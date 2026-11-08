-- ============================================================================
-- UTN - TECNICATURA UNIVERSITARIA EN PROGRAMACIÓN | BASE DE DATOS II
-- TRABAJO PRÁCTICO N.º 8: Food Store en la feria: la base de la tablet
-- Consigna 2.b: Semáforo de resolución y sincronización offline
-- ============================================================================

-- El móvil propone, el servidor dispone:
-- Esta consulta compara las solicitudes en estado 'PENDIENTE' registradas localmente
-- en 'cola_sync' contra la tabla 'snapshot_servidor' (instantánea de PostgreSQL).
--
-- Reglas de decisión:
-- 1. ROJO (RECHAZADO): Algún ítem no existe en el servidor, no está disponible (disponible <> 't'),
--    fue dado de baja lógica (eliminado = 't'), o la cantidad solicitada supera el stock.
-- 2. AMARILLO (CONFLICTO): No presenta causales de rechazo, pero el precio visto por la tablet
--    difiere del precio actual del servidor (precio_centavos_visto <> precio_centavos).
-- 3. VERDE (SIMULADO_APROBADO): Todos los productos existen, están activos, tienen stock suficiente
--    y los precios coinciden plenamente.
--
-- Idempotencia:
-- Solo se evalúan solicitudes con estado = 'PENDIENTE'. Si se reejecuta el script,
-- las solicitudes ya procesadas no son alteradas ni reevaluadas.

WITH diagnostico_items AS (
    SELECT 
        c.solicitud_uuid,
        -- Detección individual del motivo por producto/ítem
        CASE 
            WHEN s.id IS NULL THEN 'Producto inexistente en servidor (ID: ' || i.producto_id || ')'
            WHEN s.eliminado IN ('t', '1') THEN 'Producto dado de baja lógica / lápida (' || s.nombre || ')'
            WHEN s.disponible NOT IN ('t', '1') THEN 'Producto no disponible en catálogo (' || s.nombre || ')'
            WHEN i.cantidad > s.stock THEN 'Stock insuficiente en ' || s.nombre || ' (solicitado: ' || i.cantidad || ', disponible: ' || COALESCE(s.stock, 0) || ')'
            WHEN i.precio_centavos_visto <> s.precio_centavos THEN 'Diferencia de precio en ' || s.nombre || ' (visto: $' || PRINTF('%.2f', i.precio_centavos_visto / 100.0) || ', servidor: $' || PRINTF('%.2f', s.precio_centavos / 100.0) || ')'
            ELSE 'OK'
        END AS motivo_item,
        -- Indicador binario de causal de rechazo
        CASE 
            WHEN s.id IS NULL OR s.eliminado IN ('t', '1') OR s.disponible NOT IN ('t', '1') OR i.cantidad > s.stock THEN 1
            ELSE 0
        END AS es_rechazo,
        -- Indicador binario de causal de conflicto de precio
        CASE 
            WHEN (s.id IS NOT NULL AND s.eliminado NOT IN ('t', '1') AND s.disponible IN ('t', '1') AND i.cantidad <= s.stock)
                 AND (i.precio_centavos_visto <> s.precio_centavos) THEN 1
            ELSE 0
        END AS es_conflicto
    FROM cola_sync c
    JOIN item_borrador i ON c.id_local = i.id_local
    LEFT JOIN snapshot_servidor s ON i.producto_id = s.id
    WHERE c.estado = 'PENDIENTE'
),
evaluacion_solicitud AS (
    SELECT 
        solicitud_uuid,
        -- Jerarquía de estados: RECHAZADO > CONFLICTO > SIMULADO_APROBADO
        CASE 
            WHEN SUM(es_rechazo) > 0 THEN 'RECHAZADO'
            WHEN SUM(es_conflicto) > 0 THEN 'CONFLICTO'
            ELSE 'SIMULADO_APROBADO'
        END AS nuevo_estado,
        -- Construcción del motivo detallado
        CASE 
            WHEN SUM(es_rechazo) > 0 THEN 'Rechazado: ' || GROUP_CONCAT(motivo_item, '; ')
            WHEN SUM(es_conflicto) > 0 THEN 'Conflicto de precio: ' || GROUP_CONCAT(motivo_item, '; ')
            ELSE 'Validación simulada exitosa: stock y precios coinciden con el servidor'
        END AS nuevo_motivo
    FROM diagnostico_items
    GROUP BY solicitud_uuid
)
UPDATE cola_sync
SET 
    estado = (SELECT nuevo_estado FROM evaluacion_solicitud WHERE evaluacion_solicitud.solicitud_uuid = cola_sync.solicitud_uuid),
    motivo = (SELECT nuevo_motivo FROM evaluacion_solicitud WHERE evaluacion_solicitud.solicitud_uuid = cola_sync.solicitud_uuid)
WHERE estado = 'PENDIENTE'
  AND solicitud_uuid IN (SELECT solicitud_uuid FROM evaluacion_solicitud);

-- Consulta de verificación de la cola de sincronización tras la ejecución del semáforo
SELECT 
    solicitud_uuid,
    id_local,
    estado,
    motivo
FROM cola_sync;
