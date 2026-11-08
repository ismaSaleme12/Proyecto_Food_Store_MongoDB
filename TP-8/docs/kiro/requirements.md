# Especificación de Requisitos de Software (SRS) - Módulo Móvil Offline
## Proyecto Integrador: Food Store en la Feria (Unidad 8)
**Equipo**: Gimenez, Saleme, Coronel y Godoy  
**Asignatura**: Base de Datos II - UTN TUP  
**Metodología / Formato**: Notación EARS (Easy Approach to Requirements Syntax)

---

### Contexto y Regla de Oro
El sistema opera en tablets móviles dentro de un food truck emplazado en una feria gastronómica sin conectividad continua a Internet. La base de datos local SQLite opera de manera desconectada (offline-first).
> **Regla de oro de la arquitectura**:  
> *El móvil propone, el servidor dispone.* La tablet solo consulta catálogos en caché y arma borradores de pedidos. Precios definitivos, asignación de stock y confirmación de ventas son potestad exclusiva del servidor central PostgreSQL.

---

### Requisitos Funcionales en Notación EARS

#### REQ-01: Detección y Gestión de Conflictos de Precio (Event-driven)
* **Definición**:  
  **WHEN** el precio actual de uno o más productos en el snapshot del servidor difiere del precio registrado en el borrador (`precio_centavos_visto <> precio_centavos`),  
  **THE SYSTEM SHALL** clasificar la solicitud en `cola_sync` con el estado `CONFLICTO`, registrando en el campo `motivo` el detalle del precio desactualizado y permitiendo al operador reintentar con el nuevo importe previa aceptación del cliente.  
* **Criterio de Aceptación / Caso de Prueba**: **Caso C2**.

---

#### REQ-02: Rechazo por Falta de Stock o Inconsistencia de Catálogo (Unwanted Behaviour)
* **Definición**:  
  **IF** un ítem del pedido borrador solicita una cantidad superior al stock disponible en el servidor (`cantidad > stock`), o referencia a un producto que no existe, no está disponible (`disponible <> 't'`) o fue dado de baja lógica (`eliminado = 't'`),  
  **THEN THE SYSTEM SHALL** asignar a la solicitud en `cola_sync` el estado `RECHAZADO` y documentar la causal unívoca en el campo `motivo`.  
* **Criterio de Aceptación / Caso de Prueba**: **Casos C3 y C4**.

---

#### REQ-03: Validación Exitosa de Solicitud de Pedido (State-driven)
* **Definición**:  
  **WHILE** todos los productos incluidos en el borrador existan en el snapshot del servidor, se encuentren activos (`disponible = 't'`), no eliminados (`eliminado = 'f'`), dispongan de stock suficiente y mantengan idéntico precio en centavos,  
  **THE SYSTEM SHALL** marcar la solicitud en `cola_sync` con el estado `SIMULADO_APROBADO`, dejando constancia de que la transacción es un simulacro no confirmado hasta su procesamiento final en PostgreSQL.  
* **Criterio de Aceptación / Caso de Prueba**: **Caso C5**.

---

#### REQ-04: Idempotencia y Protección ante Duplicados (Ubiquitous)
* **Definición**:  
  **THE SYSTEM SHALL** preservar la unicidad de las solicitudes mediante restricción de clave primaria sobre `solicitud_uuid` (impidiendo duplicaciones accidentales) y limitar la evaluación del semáforo exclusivamente a registros en estado `PENDIENTE`, garantizando que repeticiones de la simulación no alteren estados resueltos ni generen doble procesamiento.  
* **Criterio de Aceptación / Caso de Prueba**: **Caso C6**.

---

### Requisitos Complementarios de Integridad y Operación Local

* **REQ-05 (Consulta Offline de Catálogo - Ubiquitous)**:  
  **THE SYSTEM SHALL** brindar acceso inmediato de solo lectura al catálogo local (`producto_cache`) filtrando únicamente artículos habilitados y no eliminados (`disponible = 1 AND eliminado = 0`), sin requerir comunicación con el servidor.  
  *Se prueba con: Caso C1*.

* **REQ-06 (Integridad Referencial y de Dominio - Unwanted Behaviour)**:  
  **IF** una transacción intenta insertar un ítem con cantidad menor o igual a cero o asociado a un identificador de producto inexistente,  
  **THEN THE SYSTEM SHALL** abortar la operación emitiendo error de restricción (`CHECK` o `FOREIGN KEY`), garantizando que no se almacenen registros corruptos o huérfanos.  
  *Se prueba con: Caso C7*.
