# Plan de Tareas de Implementación (Tasks) - Módulo Móvil Offline
## Food Store: Capa de Datos Móvil Desconectada (Unidad 8)
**Equipo**: Gimenez, Saleme, Coronel y Godoy  
**Asignatura**: Base de Datos II - UTN TUP  

---

### Fase 1: Especificación y Modelado Conceptual
- [x] **TASK-01**: Redactar requisitos en notación EARS vinculados a casos de prueba C1 a C7 (`requirements.md`).
- [x] **TASK-02**: Diseñar la arquitectura Offline-First, esquema de datos STRICT, y semáforo de tres estados (`design.md`).
- [x] **TASK-03**: Delimitar columnas que viajan a la tablet versus datos restringidos al servidor central (Consigna 1.a).

### Fase 2: Esquema SQLite y Pruebas Locales (Consigna 1)
- [x] **TASK-04**: Escribir script DDL `schema_sqlite.sql` con `PRAGMA foreign_keys = ON;` y tablas `STRICT` (`producto_cache`, `pedido_borrador`, `item_borrador`, `cola_sync`).
- [x] **TASK-05**: Implementar script de validación `pruebas_sqlite.sql`:
  - Transacción exitosa comprometida con `BEGIN ... COMMIT`.
  - Transacción cancelada con `BEGIN ... ROLLBACK` verificando ausencia de filas huérfanas.
  - Caso C1: Consulta del catálogo disponible desconectado (`disponible = 1 AND eliminado = 0`).
  - Caso C7: Restricciones de integridad referencial y de dominio (`CHECK` cantidad > 0, `FOREIGN KEY` producto inexistente).

### Fase 3: Sincronización, Semáforo y Casos de Prueba (Consigna 2)
- [x] **TASK-06**: Definir vista PostgreSQL `v_snapshot_movil` y estructurar el dataset exportado `servidor_snapshot.csv`.
- [x] **TASK-07**: Desarrollar la consulta del semáforo `semaforo.sql` con CTEs diagnósticas, lógica de tres estados y actualización idempotente sobre registros `PENDIENTE`.
- [x] **TASK-08**: Probar y documentar exhaustivamente los casos de prueba C2 a C6:
  - Caso C2: Detección de conflicto de precio y resolución aceptada por cliente.
  - Caso C3: Rechazo por superación de stock disponible.
  - Caso C4: Rechazo por producto marcado con baja lógica (lápida).
  - Caso C5: Aprobación simulada de pedido sin discrepancias.
  - Caso C6: Idempotencia y rechazo de solicitud duplicada por clave primaria.
- [x] **TASK-09**: Verificar la inmutabilidad de la base PostgreSQL de pruebas (comprobación de stock y pedidos inalterados).

### Fase 4: Integración, Plan de Mantenimiento y Revisión con IA (Consigna 3)
- [x] **TASK-10**: Diseñar el mapa integral de la capa de datos de 3 motores (PostgreSQL, MongoDB, SQLite) detallando gobernanza de datos.
- [x] **TASK-11**: Elaborar el plan de mantenimiento para respaldos, recuperación de backups antiguos y auditoría de conflictos.
- [x] **TASK-12**: Ejecutar la revisión de código con IA (OpenCode / Plan Agent), seleccionando al menos 3 hallazgos de 2 unidades distintas con al menos 1 hallazgo descartado con fundamento.

### Fase 5: Documentación Formal y Entrega (Consigna 4)
- [x] **TASK-13**: Registrar la bitácora de interacción con IA (`bitacora_ia.md`) con 3 entradas completas.
- [x] **TASK-14**: Completar la Declaración de Uso de Inteligencia Artificial formal (`DUIA.md`).
- [x] **TASK-15**: Redactar `README.md` con instrucciones paso a paso para la reproducción desde cero y guía para el ensayo de defensa de 10 minutos.
- [x] **TASK-16**: Generar y compilar el documento formal `informe.pdf` respetando el límite máximo estricto de 6 páginas.
