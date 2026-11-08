-- ============================================================================
-- UTN - TECNICATURA UNIVERSITARIA EN PROGRAMACIÓN | BASE DE DATOS II
-- TRABAJO PRÁCTICO N.º 8: Food Store en la feria: la base de la tablet
-- Consigna 1.c: Pruebas del esquema SQLite, transacciones y casos C1 y C7
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- 0. Poblado inicial de producto_cache a partir del snapshot del servidor
-- ----------------------------------------------------------------------------
INSERT OR REPLACE INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
VALUES 
    (101, 'Hamburguesa Clásica', 450000, 25, 1, 0, '2026-11-08 19:00:00'),
    (102, 'Hamburguesa Doble Queso', 600000, 15, 1, 0, '2026-11-08 19:00:00'),
    (103, 'Papas Fritas Medianas', 220000, 30, 1, 0, '2026-11-08 19:00:00'),
    (104, 'Gaseosa Cola 500ml', 150000, 50, 1, 0, '2026-11-08 19:00:00'),
    (105, 'Cerveza Artesanal IPA', 320000, 5, 1, 0, '2026-11-08 19:00:00'),
    (106, 'Veggie Burger Especial', 520000, 0, 1, 0, '2026-11-08 19:00:00'),
    (107, 'Postre Brownie con Helado', 280000, 10, 0, 0, '2026-11-08 19:00:00'), -- no disponible
    (108, 'Promo Combo Amigos', 990000, 8, 1, 1, '2026-11-08 19:00:00');        -- lápida (eliminado)

-- ----------------------------------------------------------------------------
-- 1. Transacción 1: Borrador completo guardado con BEGIN ... COMMIT
-- ----------------------------------------------------------------------------
BEGIN TRANSACTION;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('b47c04df-6a3f-4e09-915b-21d74a2b9101', 'operador_tablet_01', 'EFECTIVO', '2026-11-08 19:15:00');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES 
    ('b47c04df-6a3f-4e09-915b-21d74a2b9101', 101, 2, 450000),
    ('b47c04df-6a3f-4e09-915b-21d74a2b9101', 103, 1, 220000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c93d18ba-1512-4217-bc45-e6f7902d1a01', 'b47c04df-6a3f-4e09-915b-21d74a2b9101', 'PENDIENTE', NULL);

COMMIT;

-- Comprobación de persistencia del borrador comprometido
SELECT pb.id_local, pb.usuario, pb.forma_pago, ib.producto_id, pc.nombre, ib.cantidad, cs.estado
FROM pedido_borrador pb
JOIN item_borrador ib ON pb.id_local = ib.id_local
JOIN producto_cache pc ON ib.producto_id = pc.id
JOIN cola_sync cs ON pb.id_local = cs.id_local
WHERE pb.id_local = 'b47c04df-6a3f-4e09-915b-21d74a2b9101';

-- ----------------------------------------------------------------------------
-- 1. Transacción 2: Operación deshecha con ROLLBACK (Atomicidad en acción)
-- ----------------------------------------------------------------------------
BEGIN TRANSACTION;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('f99a11bb-22cc-33dd-44ee-55ff66aa7788', 'operador_tablet_01', 'TARJETA', '2026-11-08 19:20:00');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('f99a11bb-22cc-33dd-44ee-55ff66aa7788', 102, 1, 600000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('d88c22aa-33bb-44cc-55dd-66ee77ff8899', 'f99a11bb-22cc-33dd-44ee-55ff66aa7788', 'PENDIENTE', NULL);

-- Se aborta la operación: el cliente canceló antes de confirmar el borrador
ROLLBACK;

-- Comprobación: Demostramos que NO quedó ninguna fila residual
SELECT COUNT(*) AS filas_post_rollback 
FROM pedido_borrador 
WHERE id_local = 'f99a11bb-22cc-33dd-44ee-55ff66aa7788';

-- ----------------------------------------------------------------------------
-- 2. Caso C1: Consulta del catálogo disponible sin conectarse al servidor
-- Debe excluir productos eliminados (lápidas) y no disponibles.
-- ----------------------------------------------------------------------------
SELECT 
    id,
    nombre,
    precio_centavos,
    PRINTF('$%.2f', precio_centavos / 100.0) AS precio_formateado,
    stock_visto,
    fecha_copia
FROM producto_cache
WHERE disponible = 1 
  AND eliminado = 0
ORDER BY id ASC;

-- ----------------------------------------------------------------------------
-- 3. Caso C7: Pruebas de restricciones de integridad (CHECK y FOREIGN KEY)
-- ----------------------------------------------------------------------------

-- Intento A: Cantidad en 0 (debe fallar por CHECK (cantidad > 0))
-- SQLite arroja: CHECK constraint failed: cantidad > 0
-- INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
-- VALUES ('b47c04df-6a3f-4e09-915b-21d74a2b9101', 101, 0, 450000);

-- Intento B: Producto inexistente ID 9999 (debe fallar por FOREIGN KEY (producto_id) REFERENCES producto_cache(id))
-- SQLite arroja: FOREIGN KEY constraint failed
-- INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
-- VALUES ('b47c04df-6a3f-4e09-915b-21d74a2b9101', 9999, 1, 500000);

-- Verificación final: Se comprueba que no existen ítems con cantidad <= 0 ni huérfanos
SELECT COUNT(*) AS total_items_invalidos 
FROM item_borrador 
WHERE cantidad <= 0 
   OR producto_id NOT IN (SELECT id FROM producto_cache);
