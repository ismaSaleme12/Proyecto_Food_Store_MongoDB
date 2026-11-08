# Bitácora de Registro de Uso de Inteligencia Artificial
## Food Store: Capa de Datos Móvil Desconectada (Unidad 8)
**Equipo**: Gimenez, Saleme, Coronel y Godoy  
**Asignatura**: Base de Datos II - UTN TUP  
**Entorno de IA**: OpenCode / Antigravity / Gemini 3.8 Flash

---

### Entrada 1: Modelado de Esquema SQLite y Precisión Monetaria
* **Fecha y Módulo**: 08/11/2026 · Consigna 1.b (`schema_sqlite.sql`).
* **Qué se le pidió a la IA**:  
  "Diseñá el script DDL de SQLite para la base de la tablet móvil de Food Store, incluyendo las tablas de caché de productos, borradores de pedidos, ítems y cola de sincronización."
* **Qué propuso la IA**:  
  Generó un esquema SQLite estándar con tipos permisivos y propuso la columna `precio REAL` en las tablas `producto_cache` e `item_borrador`, argumentando que simplificaba la lectura humana de los precios con dos decimales (ej. `45.50`).
* **Qué se aceptó**:  
  La estructura de las cuatro tablas relacionales requeridas y la inclusión de `PRAGMA foreign_keys = ON;` al inicio del script.
* **Qué se descartó y por qué (Justificación Técnica)**:  
  Se descartó rotundamente el uso de `REAL` (punto flotante IEEE 754) para magnitudes monetarias. En sistemas transaccionales comerciales y financieros, los números de punto flotante introducen errores de precisión y redondeo acumulativo binario (ej. `0.1 + 0.2 = 0.30000000000000004`), lo que provocaría discrepancias de centavos al sumar pedidos y conciliar cajas. Se exigió almacenar el precio estrictamente como `INTEGER` en centavos (`precio_centavos`), adoptando además la cláusula `STRICT` (SQLite 3.37+) para prohibir inserciones con tipado dinámico débil.

---

### Entrada 2: Diseño del Semáforo y Regla de Oro del Negocio
* **Fecha y Módulo**: 08/11/2026 · Consigna 2.b (`semaforo.sql`).
* **Qué se le pidió a la IA**:  
  "Implementá la lógica del semáforo en SQL para evaluar los pedidos en la cola local de la tablet y actualizar el estado a SIMULADO_APROBADO, CONFLICTO o RECHAZADO contra el snapshot del servidor."
* **Qué propuso la IA**:  
  La IA propuso una rutina que, tras clasificar un pedido como `SIMULADO_APROBADO`, ejecutaba un `UPDATE producto_cache SET stock_visto = stock_visto - i.cantidad` localmente y generaba una sentencia de inserción directa a la tabla `ventas` y `pedidos` de PostgreSQL mediante un link de sincronización para consolidar la venta de inmediato.
* **Qué se aceptó**:  
  La consulta CTE (`WITH`) para clasificar en una sola pasada el estado de cada solicitud evaluando stock, disponibilidad, bajas lógicas y disparidades de precios.
* **Qué se descartó y por qué (Justificación Técnica)**:  
  Se rechazó tajantemente que la tablet descuente stock o confirme ventas. Esta propuesta violaba la Regla de Oro innegociable de la cátedra: *"El móvil propone, el servidor dispone. SIMULADO_APROBADO no es una venta"*. En un food truck con múltiples tablets operando desconectadas, permitir que cada móvil decremente stock de manera distribuida genera condiciones de carrera (race conditions) y sobreventas masivas al reconectar. El stock real y la confirmación contable son soberanía indiscutible de PostgreSQL.

---

### Entrada 3: Idempotencia y Manejo de Reintentos de Red (Caso C6)
* **Fecha y Módulo**: 08/11/2026 · Consigna 2.c y Parada 8 (`semaforo.sql` y Caso C6).
* **Qué se le pidió a la IA**:  
  "Explicá cómo implementar la protección contra pedidos duplicados si la tablet pierde la señal WiFi en el momento del envío y el usuario presiona Reintentar varias veces."
* **Qué propuso la IA**:  
  Sugirió crear un trigger en SQLite que elimine el pedido de la base de la tablet en el instante en que el usuario presione el botón 'Enviar', de manera que no pueda volver a ser enviado.
* **Qué se aceptó**:  
  La utilización de UUIDs v4 como clave primaria universal para cada solicitud (`solicitud_uuid`) y la condición de guarda `WHERE estado = 'PENDIENTE'` en el semáforo para garantizar ejecuciones idempotentes.
* **Qué se descartó y por qué (Justificación Técnica)**:  
  Se descartó el borrado preventivo local propuesto por la IA. Si la tablet borra el borrador antes de recibir la confirmación HTTP formal del servidor y la red se corta a mitad de camino, el pedido se perdería para siempre sin saber si el servidor lo recibió. La arquitectura robusta de sincronización exige conservar el borrador y delegar la deduplicación a PostgreSQL mediante una restricción `UNIQUE (solicitud_uuid)` o una tabla de claves de idempotencia con retención temporal (TTL) en el backend.
