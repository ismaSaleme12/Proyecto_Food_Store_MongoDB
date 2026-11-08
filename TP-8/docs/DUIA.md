# Declaración de Uso de Inteligencia Artificial (DUIA)
## Cátedra de Base de Datos II · Tecnicatura Universitaria en Programación
### Universidad Tecnológica Nacional (UTN) · Ciclo Lectivo 2026

---

### Datos del Proyecto y del Equipo
* **Proyecto**: Food Store - Proyecto Integrador
* **Instancia**: Trabajo Práctico N.º 8 (Unidad 8: Semanas 12 y 13)
* **Tema**: Food Store en la feria: la base de la tablet y el cierre de la capa de datos
* **Integrantes del Equipo**:
  1. Gimenez, Lucas
  2. Saleme, Lucas
  3. Coronel, Franco
  4. Godoy, Nahuel

---

### 1. Herramientas de Inteligencia Artificial Utilizadas
Durante el desarrollo del presente trabajo práctico se utilizaron las siguientes herramientas de IA generativa y asistencia al desarrollo:
* **Entornos / Modelos**: Google Antigravity / OpenCode (Plan Agent y Code Agent) impulsados por modelos Gemini (Gemini 3.8 Flash / Pro).
* **Propósito**: Asistencia en la diagramación de consultas SQL complejas (CTEs para el semáforo), estructuración de especificaciones en notación EARS, y code review cruzado de scripts de la cursada.

---

### 2. Alcance y Modo de Empleo
La IA se utilizó estrictamente como un asistente colaborativo de pair programming y revisión, abarcando las siguientes tareas específicas:
1. **Especificación Inicial**: Redacción inicial de los requisitos funcionales en formato EARS para `requirements.md`.
2. **Borradores de Scripts DDL y DML**: Generación de plantillas de creación de tablas en SQLite y formulación de consultas para simulación de conflictos.
3. **Revisión Crítica de Código (Code Review)**: Exploración de oportunidades de optimización, índices y consistencia en los scripts elaborados a lo largo del cuatrimestre.

---

### 3. Verificación Humana y Criterio Técnico
En estricto cumplimiento de las **Reglas que no se negocian** dictadas por la cátedra:
* **Comprobación Empírica**: Ningún fragmento de código generado por IA fue aceptado de forma pasiva ni incorporado sin verificación previa. Todos los scripts fueron ejecutados y testeados en un motor SQLite 3.37+ local (`foodstore_movil.db`) y contrastados con la instancia de PostgreSQL de pruebas.
* **Descartes Fundamentados**: Se rechazaron activamente aquellas sugerencias de la IA que contravenían los principios fundamentales de la materia, tales como el intento de actualizar el stock real o confirmar ventas desde el móvil (violación de la Regla de Oro) o el uso de tipos de datos en punto flotante (`REAL`) para magnitudes monetarias.
* **Privacidad y Seguridad**: No se ingresaron credenciales, contraseñas, correos electrónicos ni información personal en las consultas dirigidas a los modelos de lenguaje; se trabajó exclusivamente sobre datasets de prueba con datos ficticios.

---

### 4. Declaración de Autoría y Compromiso de Defensa Individual
Los integrantes del equipo declaramos bajo juramento que comprendemos en profundidad la totalidad del código, la arquitectura de datos, los mecanismos de sincronización offline, el semáforo de tres estados y los planes de contingencia documentados en esta entrega.

Asumimos la responsabilidad intelectual completa sobre el proyecto y nos comprometemos a defenderlo de forma individual en la instancia de coloquio oral de la Semana 13.
