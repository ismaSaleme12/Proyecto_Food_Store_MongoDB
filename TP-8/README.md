# Food Store - Módulo Móvil Offline (Unidad 8)
## Food Truck en la Feria: La Base de la Tablet y el Cierre de la Capa de Datos
**Universidad Tecnológica Nacional (UTN) · Tecnicatura Universitaria en Programación**  
**Cátedra de Base de Datos II · Ciclo Lectivo 2026**  
**Equipo de Proyecto**: Sabrina Gimenez, Ismael Saleme, Jeronimo Coronel y Joaquin Godoy

---

### Descripción del Proyecto
Este módulo implementa la capa de datos desconectada (**Offline-First**) para las tablets del food truck de Food Store en ferias gastronómicas sin señal de Internet. Utiliza **SQLite 3.37+ con tablas STRICT**, transacciones ACID locales, y un **semáforo de sincronización determinista** de tres estados (`SIMULADO_APROBADO`, `CONFLICTO`, `RECHAZADO`) para evaluar borradores locales contra instantáneas del servidor central PostgreSQL.

> **Regla de Oro Innegociable**:  
> *El móvil propone, el servidor dispone.* La tablet solo consulta catálogos en caché y arma borradores. Precio, stock y confirmación de ventas son potestad exclusiva de PostgreSQL. `SIMULADO_APROBADO` nunca es una venta.

---

### Estructura del Repositorio y Entrega
```
food-store/
├── README.md                   # Guía de reproducción y ensayo de defensa
├── movil/
│   ├── schema_sqlite.sql       # Consigna 1.b: DDL SQLite STRICT y claves foráneas
│   ├── pruebas_sqlite.sql      # Consigna 1.c: Transacciones COMMIT/ROLLBACK, casos C1 y C7
│   ├── semaforo.sql            # Consigna 2.b: Algoritmo de semáforo SQL para cola_sync
│   ├── simulador.py            # Script interactivo de simulación automatizada C1 a C7
│   ├── servidor_snapshot.csv   # Consigna 2.a: Instantánea exportada desde PostgreSQL
│   └── foodstore_movil.db      # Base SQLite precompilada con catálogo y pruebas
└── docs/
    ├── informe.pdf             # Consignas 1.a, 2.c, 3.a, 3.b y 3.c (máx. 6 páginas)
    ├── kiro/                   # Consigna 4.a: Especificación formal
    │   ├── requirements.md     # 4 requisitos en notación EARS vinculados a casos
    │   ├── design.md           # Diseño de arquitectura offline y semáforo
    │   └── tasks.md            # Plan de tareas de implementación
    ├── bitacora_ia.md          # Consigna 4.b: Registro de interacción con IA (3 entradas)
    └── DUIA.md                 # Consigna 4.b: Declaración de Uso de IA formal
```

---

### Orden de Ejecución para Crear Todo desde Cero

#### Paso 1: Generar la instantánea en PostgreSQL de pruebas (Consigna 2.a)
En el servidor PostgreSQL central, crear la vista de exportación móvil y volcarla a CSV:
```sql
-- En psql conectado a la base 'foodstore_server'
CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT 
    id,
    nombre,
    ROUND(precio * 100)::INTEGER AS precio_centavos,
    stock,
    disponible,
    eliminado
FROM productos;

\copy (SELECT * FROM v_snapshot_movil) TO 'servidor_snapshot.csv' CSV HEADER;
```

#### Paso 2: Crear la base de datos de la tablet en SQLite (Consigna 1.b)
Desde la terminal en el directorio `food-store/movil`:
```bash
# Con la CLI de sqlite3
sqlite3 foodstore_movil.db < schema_sqlite.sql
```
*(O bien abrir `foodstore_movil.db` en DB Browser for SQLite y ejecutar `schema_sqlite.sql`).*

#### Paso 3: Importar la instantánea y cargar el catálogo local (Consigna 2.a)
```sql
-- Dentro de sqlite3 foodstore_movil.db:
.mode csv
.import --skip 1 servidor_snapshot.csv snapshot_servidor

-- Sincronizar la tabla producto_cache a partir del snapshot:
INSERT OR REPLACE INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)
SELECT 
    id,
    nombre,
    precio_centavos,
    stock,
    CASE WHEN disponible = 't' THEN 1 ELSE 0 END,
    CASE WHEN eliminado = 't' THEN 1 ELSE 0 END,
    CURRENT_TIMESTAMP
FROM snapshot_servidor;
```

#### Paso 4: Ejecutar las pruebas unitarias y de integridad (Consigna 1.c)
```bash
sqlite3 foodstore_movil.db < pruebas_sqlite.sql
```
Verifica:
* Commit de borrador completo y Rollback de operación abortada.
* Caso C1: Consulta de catálogo disponible sin conexión.
* Caso C7: Bloqueo de cantidad en 0 y producto inexistente.

#### Paso 5: Ejecutar el Semáforo de Sincronización (Consigna 2.b)
Para evaluar solicitudes en estado `PENDIENTE`:
```bash
sqlite3 foodstore_movil.db < semaforo.sql
```

#### Opción Automatizada: Ejecutar la suite completa mediante Python
Para correr todos los casos C1 a C7 de forma secuencial y visual:
```bash
python simulador.py
```

#### Paso 6: Verificación de Inmutabilidad en PostgreSQL
Al finalizar la jornada o las pruebas, se ejecuta en PostgreSQL:
```sql
SELECT COUNT(*) AS total_pedidos FROM pedidos;
SELECT id, nombre, stock FROM productos ORDER BY id;
```
Se comprueba fehacientemente que **ni el stock ni los pedidos en PostgreSQL cambiaron**, validando la Regla de Oro.

---

### Guía para el Ensayo de Defensa Oral (10 Minutos)

Para la exposición individual de la Semana 13, la estructura recomendada es:

1. **El Mapa de la Capa de Datos (3 minutos)**:
   * Proyectar la tabla de los 3 motores: PostgreSQL (servidor transaccional y fuente de verdad única de ventas y stock), MongoDB (catálogo rápido desnormalizado y reseñas) y SQLite (caché local desconectada y borradores en la tablet).
   * Explicar el principio: *"El móvil propone, el servidor dispone"*.
2. **Demostración de un Caso en Vivo (4 minutos)**:
   * **Caso C2**: Mostrar un borrador creado con precio antiguo ($5500). Correr el semáforo contra el snapshot actualizado ($6000) y observar la transición a `CONFLICTO`.
   * Demostrar en vivo cómo el cliente acepta: se actualiza el borrador local, se reenvía la solicitud y pasa inmediatamente a `SIMULADO_APROBADO`.
   * Demostrar la idempotencia de **C6**: reintentar la solicitud con el mismo UUID y mostrar cómo la clave primaria impide la duplicación.
3. **Un Hallazgo de la IA Descartado con Fundamento (3 minutos)**:
   * Exponer la Entrada 2 de la Bitácora de IA: la IA sugirió que la tablet redujera el stock localmente y confirmara la venta.
   * Argumentar por qué fue descartado: riesgo crítico de race condition y sobreventa en sistemas distribuidos desconectados, reafirmando que solo PostgreSQL posee aislamiento transaccional para descontar stock real.
