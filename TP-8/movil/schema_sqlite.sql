-- ============================================================================
-- UTN - TECNICATURA UNIVERSITARIA EN PROGRAMACIÓN | BASE DE DATOS II
-- TRABAJO PRÁCTICO N.º 8: Food Store en la feria: la base de la tablet
-- Consigna 1.b: Esquema SQLite (STRICT) para la tablet móvil offline
-- ============================================================================

-- Activación obligatoria de claves foráneas en SQLite
PRAGMA foreign_keys = ON;

-- Limpieza preventiva si se recrea la base desde cero
DROP TABLE IF EXISTS cola_sync;
DROP TABLE IF EXISTS item_borrador;
DROP TABLE IF EXISTS pedido_borrador;
DROP TABLE IF EXISTS producto_cache;
DROP TABLE IF EXISTS snapshot_servidor;

-- ----------------------------------------------------------------------------
-- 1. Tabla: producto_cache
-- Copia local de solo lectura del catálogo de productos para consulta offline.
-- ----------------------------------------------------------------------------
CREATE TABLE producto_cache (
    id              INTEGER PRIMARY KEY,
    nombre          TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto     INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible      INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado       INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia     TEXT NOT NULL
) STRICT;

-- ----------------------------------------------------------------------------
-- 2. Tabla: pedido_borrador
-- Encabezado de los borradores armados localmente en la tablet sin conexión.
-- ----------------------------------------------------------------------------
CREATE TABLE pedido_borrador (
    id_local    TEXT PRIMARY KEY,
    usuario     TEXT NOT NULL,
    forma_pago  TEXT NOT NULL CHECK (forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    fecha       TEXT NOT NULL
) STRICT;

-- ----------------------------------------------------------------------------
-- 3. Tabla: item_borrador
-- Líneas de detalle de cada pedido borrador.
-- ----------------------------------------------------------------------------
CREATE TABLE item_borrador (
    id_local             TEXT NOT NULL,
    producto_id          INTEGER NOT NULL,
    cantidad             INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache(id)
) STRICT;

-- ----------------------------------------------------------------------------
-- 4. Tabla: cola_sync
-- Cola local para simulación y posterior sincronización con el servidor central.
-- ----------------------------------------------------------------------------
CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY,
    id_local       TEXT NOT NULL,
    estado         TEXT NOT NULL CHECK (estado IN ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo         TEXT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE
) STRICT;

-- ----------------------------------------------------------------------------
-- 5. Tabla: snapshot_servidor (Estructura de importación para Consigna 2.a)
-- Almacena temporalmente la instantánea descargada desde PostgreSQL (v_snapshot_movil)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS snapshot_servidor (
    id              INTEGER PRIMARY KEY,
    nombre          TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL,
    stock           INTEGER NOT NULL,
    disponible      TEXT NOT NULL, -- 't' o 'f' (formato exportado por PostgreSQL)
    eliminado       TEXT NOT NULL  -- 't' o 'f' (lápida de baja lógica en PostgreSQL)
);
