# Documento de Diseño de Arquitectura (ADD) - Base Móvil Offline
## Food Store: Capa de Datos Móvil Desconectada (Unidad 8)
**Equipo**: Gimenez, Saleme, Coronel y Godoy  
**Asignatura**: Base de Datos II - UTN TUP  

---

### 1. Visión General de la Arquitectura
El food truck de Food Store opera en entornos de conectividad intermitente o nula (ferias gastronómicas). Para garantizar la continuidad del negocio sin degradar la consistencia global del sistema, se adopta el patrón arquitectónico **Offline-First** apoyado en:
1. **Almacenamiento Local Embebido (SQLite 3.37+)**: Base de datos autónoma de footprint liviano en cada tablet.
2. **Tablas de Tipado Estricto (`STRICT`)**: Garantía a nivel motor de que no existan coerciones dinámicas de tipo ni datos mal formateados.
3. **Caché Desconectada con Lápidas (Tombstones)**: La tabla `producto_cache` almacena productos con banderas booleanas `disponible` y `eliminado` para soportar bajas lógicas sin perder integridad referencial histórica.
4. **Semáforo de Sincronización Asíncrona**: Algoritmo determinista que contrasta borradores locales (`pedido_borrador`, `item_borrador`) contra una instantánea reciente del servidor central (`snapshot_servidor`).

```
+-----------------------------------------------------------------------+
| TABLET MÓVIL (SQLite 3.37+ STRICT)                                   |
|                                                                       |
|  +--------------------+         +----------------------------------+  |
|  |   producto_cache   | <-------+        snapshot_servidor         |  |
|  +--------------------+ (Copia) +----------------------------------+  |
|            ^                                       ^                  |
|            | FK                                    | Evaluación       |
|  +--------------------+                  +-------------------------+  |
|  |   item_borrador    | ---------------->|    SEMÁFORO SQL         |  |
|  +--------------------+                  +-------------------------+  |
|            ^                                       |                  |
|            | FK (ON DELETE CASCADE)                v                  |
|  +--------------------+                  +-------------------------+  |
|  |  pedido_borrador   | <---------------+|       cola_sync         |  |
|  +--------------------+      FK          |  (PENDIENTE, CONFLICTO, |  |
|                                          |   RECHAZADO, SIM_APROB) |  |
|                                          +-------------------------+  |
+-----------------------------------------------------------------------+
                                  ^
                        Export CSV \ Instantánea (Solo Lectura)
                                  |
+-----------------------------------------------------------------------+
| SERVIDOR CENTRAL (PostgreSQL 16+)                                     |
| • Fuente Única de Verdad (Precios oficiales, Stock real, Ventas)      |
| • Vista: v_snapshot_movil                                             |
+-----------------------------------------------------------------------+
```

---

### 2. Decisiones de Diseño Técnico

#### A. Tipos de Datos y Precisión Monetaria
* **Centavos en Enteros (`INTEGER`)**: En lugar de utilizar números en coma flotante (`REAL` o `FLOAT`), todos los importes monetarios se almacenan como enteros en centavos (`precio_centavos`). Esto erradica errores de redondeo binario de punto flotante en cálculos y sumatorias financieras.
* **Modo `STRICT` en SQLite**: Se activa en las cuatro tablas principales para forzar tipos de datos rígidos (`INTEGER`, `TEXT`), impidiendo el almacenamiento inadvertido de textos en campos numéricos.
* **Integridad Referencial Forzada**: Se ejecuta `PRAGMA foreign_keys = ON;` al abrir la conexión, asegurando que `item_borrador` y `cola_sync` no admitan referencias huérfanas hacia pedidos o productos inexistentes.

#### B. Separación de Responsabilidades y Seguridad
* **Datos que viajan a la tablet**: Únicamente identificador de producto, denominación comercial, precio en centavos, stock referencial, y banderas de disponibilidad y baja lógica.
* **Datos que NO viajan**: Costos mayoristas de mercadería, datos sensibles de usuarios y clientes (contraseñas, emails, hashes, números de tarjeta de crédito), historial completo de facturación contable.
* **Minimización de Superficie de Ataque**: Si la tablet física es sustraída en el predio ferial, ningún dato confidencial o personal queda comprometido.

#### C. Ciclo de Vida del Semáforo y Máquina de Estados
La tabla `cola_sync` implementa una máquina de estados determinista:

```
[ INICIO ] ---> PENDIENTE 
                    |
      +-------------+-------------+
      |                           |                           |
      v                           v                           v
  [ RECHAZADO ]              [ CONFLICTO ]           [ SIMULADO_APROBADO ]
  • Stock insuficiente       • Precio visto          • Todo coincide
  • Producto baja/lápida       cambió en servidor    • Requiere confirmación
  • No disponible            (Permite renegociar       final en PostgreSQL
  • Inexistente               con el cliente)
```

1. **PENDIENTE**: Estado inicial asignado al crear el borrador en la tablet.
2. **RECHAZADO (Rojo)**: Se detecta que algún producto del borrador no tiene stock disponible, está marcado con baja lógica (`eliminado = 't'`), fue desactivado (`disponible <> 't'`) o no existe en la base central. Operación cancelada.
3. **CONFLICTO (Amarillo)**: No hay causales de rechazo de catálogo o stock, pero el precio en centavos registrado por la tablet no coincide con el precio vigente en el servidor. El sistema solicita al operador confirmar el nuevo valor con el cliente. Si el cliente acepta, se actualiza el borrador local y se encola una nueva solicitud para su resolución.
4. **SIMULADO_APROBADO (Verde)**: La validación contra la instantánea concluye satisfactoriamente. **Nota crítica**: Esta aprobación es exclusivamente una simulación local previa; la venta definitiva y el descuento de stock real ocurren exclusivamente cuando PostgreSQL procesa la orden tras la reconexión.
