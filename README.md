# TP Unidad 7 · NoSQL — Food Store

Entrega del trabajo práctico **«NoSQL y nuevas formas de almacenamiento»** de
Base de Datos II: modelado documental del subconjunto *pedidos y detalle de pedidos*
en MongoDB y comparación verificable contra PostgreSQL.

## Archivos

| Archivo | Qué es |
|---|---|
| `informe_u7_nosql.pdf` | **Entrega principal** (4 páginas). Modelo, evidencias, tabla de verificación, contraste de IA y conclusión. |
| `informe_u7_nosql.md` | Fuente editable del informe. |
| `consultas_mongodb.js` | Creación de la colección, `insertMany` de los 10 pedidos, validador `$jsonSchema`, índices, consultas a–d y pruebas negativas. |
| `consultas_postgresql.sql` | Extracción con `jsonb_agg`, equivalentes de b) y c), tabla de verificación y control de las Reglas 1 y 2. |
| `datos_migracion.json` | Los 10 documentos migrados en JSON (formato importable con `mongoimport`). |
| `salida_mongodb.txt` | Salida real de `mongosh --file consultas_mongodb.js`. |
| `salida_postgresql.txt` | Salida real de `psql -f consultas_postgresql.sql`. |

## Reproducción

```bash
# 1. MongoDB (debe estar corriendo en 127.0.0.1:27017)
mongosh "mongodb://127.0.0.1:27017" --file consultas_mongodb.js

# 2. PostgreSQL (base de trabajo, NUNCA practica_bd2)
psql -U postgres -h localhost -d practica_bd2_tp -f consultas_postgresql.sql
```

Alternativa para la carga en MongoDB, sin ejecutar el JS:

```bash
mongoimport --db foodstore_nosql --collection pedidos \
            --file datos_migracion.json --jsonArray
```

## Qué se migró

10 pedidos reales de `practica_bd2_tp` (IDs `1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001`),
elegidos para cubrir las tres formas de pago y para que cuatro de ellos compartan el
producto 1 (así la consulta c) devuelve más de una fila).

Un documento = un pedido completo:

```javascript
{ _id, pedido_id, fecha, forma_pago, cliente{}, lineas[], total, origen{} }
```

`_id` es el `pedido.id` original: no se generan claves nuevas. `lineas[].precio_unitario`
es el precio histórico de `detalle_pedido`, nunca el precio actual del producto.

## Resultado de la comparación

| Consulta | PostgreSQL | MongoDB | Coinciden los IDs |
|---|---|---|---|
| Estado `TARJETA` | 4 | 4 | Sí — `{2, 3, 5, 50001}` |
| Producto 1 | 4 | 4 | Sí — `{1, 50001, 100001, 150001}` |

## Notas de entorno

- Las evidencias de PostgreSQL se generaron sobre una **instancia temporal** (puerto 5433)
  restaurada desde `db/backups/Food_Store_Copia_backup_U4P2.sql` (del repositorio del proyecto
  original, `02_Base-de-datos-II`), para no ejecutar nada contra `practica_bd2_tp`. Los datos son
  los mismos: 200.000 pedidos, 200.000 detalles.
- El modelo real de Food Store **no tiene columna `estado`**: el atributo que cumple ese
  rol es `forma_pago`. Está explicado en el informe, sección 2.3.
- Hallazgo: la carga masiva del TP3 generó **una línea por pedido**, así que la relación
  N:M quedó degenerada en 1:1. Ver sección 2.6 del informe.
