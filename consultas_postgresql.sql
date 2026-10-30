-- ============================================================================
-- TP Unidad 7 - NoSQL y nuevas formas de almacenamiento - Food Store
-- Base de datos II - Tecnicatura Universitaria en Programacion
--
-- Archivo : consultas_postgresql.sql
-- Motor   : PostgreSQL 17
-- Base    : practica_bd2_tp   (NUNCA practica_bd2 - ver AGENTS.md)
-- Uso     : psql -U postgres -h localhost -d practica_bd2_tp -f consultas_postgresql.sql
--
-- Contenido:
--   Bloque 1 - Consulta de extraccion: genera los documentos migrados a MongoDB
--   Bloque 2 - Consulta b) equivalente: pedidos por estado (forma_pago)
--   Bloque 3 - Consulta c) equivalente: pedidos que contienen un producto
--   Bloque 4 - Tabla de verificacion PostgreSQL vs MongoDB
--
-- Universo de comparacion: los 10 pedidos migrados a la coleccion
-- foodstore_nosql.pedidos -> [1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001]
-- Comparar contra los 200.000 pedidos de la base no seria equivalente: la
-- consigna pide comparar el MISMO conjunto de datos en ambos motores.
-- ============================================================================

\set ON_ERROR_STOP on

-- ============================================================================
-- Bloque 1 - Extraccion: pedido completo como documento JSON
-- Esta consulta es la fuente real de la migracion. Su salida, volcada a
-- datos_migracion.json, se carga con:
--     mongoimport --db foodstore_nosql --collection pedidos \
--                 --file datos_migracion.json --jsonArray
-- o, como en este TP, se pega en el arreglo `pedidos` de consultas_mongodb.js
-- y se inserta con insertMany().
-- ============================================================================
SELECT jsonb_pretty(
    jsonb_agg(doc ORDER BY id)
)
FROM (
    SELECT p.id,
           jsonb_build_object(
               '_id',              p.id,
               'pedido_id',        p.id,
               'fecha',            p.fecha,
               'forma_pago',       p.forma_pago,
               'cliente', jsonb_build_object(
                   'cliente_id', c.id,
                   'nombre',     c.nombre,
                   'email',      c.email,
                   'telefono',   c.telefono
               ),
               'lineas', jsonb_agg(
                   jsonb_build_object(
                       'producto_id',     pr.id,
                       'nombre',          pr.nombre,
                       'categoria',       cat.nombre,
                       'cantidad',        d.cantidad,
                       'precio_unitario', d.precio_unitario,
                       'subtotal',        round(d.cantidad * d.precio_unitario, 2)
                   ) ORDER BY pr.id
               ),
               'total', sum(round(d.cantidad * d.precio_unitario, 2)),
               'origen', jsonb_build_object(
                   'motor',  'PostgreSQL',
                   'tablas', jsonb_build_array('pedido','detalle_pedido','cliente','producto'),
                   'base',   'practica_bd2_tp'
               )
           ) AS doc
    FROM pedido p
    JOIN cliente        c   ON c.id   = p.cliente_id
    JOIN detalle_pedido d   ON d.pedido_id = p.id
    JOIN producto       pr  ON pr.id  = d.producto_id
    JOIN categoria      cat ON cat.id = pr.categoria_id
    WHERE p.id = ANY (ARRAY[1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001])
    GROUP BY p.id, p.fecha, p.forma_pago, c.id, c.nombre, c.email, c.telefono
) AS s;


-- ============================================================================
-- Bloque 2 - Consulta b) equivalente en PostgreSQL
-- MongoDB: db.pedidos.find({ forma_pago: "TARJETA" })
--
-- NOTA DE MODELO: Food Store no tiene columna `estado` en `pedido`. El
-- atributo del dominio que cumple ese rol es `forma_pago`
-- (ENUM: EFECTIVO | TARJETA | TRANSFERENCIA). Se usa ese campo en ambos
-- motores para que la comparacion sea sobre el mismo dato.
-- ============================================================================
SELECT p.id,
       p.forma_pago,
       p.fecha
FROM pedido p
WHERE p.forma_pago = 'TARJETA'
  AND p.id = ANY (ARRAY[1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001])
ORDER BY p.id;


-- ============================================================================
-- Bloque 3 - Consulta c) equivalente en PostgreSQL
-- MongoDB: db.pedidos.find({ "lineas.producto_id": 1 })
--
-- En relacional el "arreglo embebido" es la tabla detalle_pedido: hace falta
-- un JOIN y un DISTINCT para no repetir el pedido por cada linea que
-- coincida con el producto buscado.
-- ============================================================================
SELECT DISTINCT p.id,
       pr.nombre  AS producto,
       d.cantidad,
       d.precio_unitario
FROM pedido p
JOIN detalle_pedido d  ON d.pedido_id  = p.id
JOIN producto       pr ON pr.id        = d.producto_id
WHERE d.producto_id = 1
  AND p.id = ANY (ARRAY[1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001])
ORDER BY p.id;


-- ============================================================================
-- Bloque 4 - Tabla de verificacion (Consigna 5)
-- Devuelve, para cada consulta, la cantidad y los IDs recuperados.
-- Espejo exacto de la salida de consultas_mongodb.js.
-- ============================================================================
WITH universo (id) AS (
    VALUES (1), (2), (3), (4), (5), (6), (7), (50001), (100001), (150001)
),
por_estado AS (
    SELECT p.id
    FROM pedido p
    JOIN universo u ON u.id = p.id
    WHERE p.forma_pago = 'TARJETA'
),
por_producto AS (
    SELECT DISTINCT p.id
    FROM pedido p
    JOIN detalle_pedido d ON d.pedido_id = p.id
    JOIN universo u       ON u.id = p.id
    WHERE d.producto_id = 1
)
SELECT 'Estado = TARJETA'                       AS consulta,
       (SELECT count(*) FROM por_estado)        AS cantidad,
       (SELECT array_agg(id ORDER BY id) FROM por_estado)   AS ids
UNION ALL
SELECT 'Producto = 1',
       (SELECT count(*) FROM por_producto),
       (SELECT array_agg(id ORDER BY id) FROM por_producto)
ORDER BY consulta;


-- ============================================================================
-- Bloque 5 - Control de integridad del universo migrado (Consigna 3)
-- Verifica que los 10 pedidos sigan cumpliendo las dos reglas de negocio
-- del proyecto antes/despues de la migracion:
--   Regla 1: ningun pedido puede tener lineas de productos inactivos.
--   Regla 2: todo pedido debe tener al menos una linea.
-- ============================================================================
SELECT p.id,
       count(d.producto_id)                                AS lineas,
       count(*) FILTER (WHERE pr.activo IS FALSE)          AS lineas_inactivas,
       bool_and(d.cantidad > 0)                            AS cantidades_positivas
FROM pedido p
LEFT JOIN detalle_pedido d ON d.pedido_id = p.id
LEFT JOIN producto       pr ON pr.id = d.producto_id
WHERE p.id = ANY (ARRAY[1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001])
GROUP BY p.id
ORDER BY p.id;
