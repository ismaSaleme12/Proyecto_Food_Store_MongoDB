/* ============================================================================
   TP Unidad 7 - NoSQL y nuevas formas de almacenamiento - Food Store
   Base de datos II - Tecnicatura Universitaria en Programacion

   Archivo : consultas_mongodb.js
   Motor   : MongoDB 7+ (probado con mongosh 2.14.1 / mongod 9.0.4)
   Uso     : mongosh "mongodb://127.0.0.1:27017" --file consultas_mongodb.js

   Contenido:
     Bloque 0 - Creacion de la base y la coleccion
     Bloque 1 - Migracion (insertMany) de 10 pedidos reales de Food Store
     Bloque 2 - Indices de apoyo
     Bloque 3 - Consultas a), b), c) y d) de la consigna 4
     Bloque 4 - Verificacion del modelo

   Origen de los datos: base PostgreSQL practica_bd2_tp, tablas
   pedido + detalle_pedido + cliente + producto. Se conservan los
   identificadores originales (pedido_id) y los precios historicos
   (detalle_pedido.precio_unitario).
   ============================================================================ */

// ---------------------------------------------------------------------------
// Bloque 0 - Base y coleccion
// ---------------------------------------------------------------------------
const foodstore = db.getSiblingDB("foodstore_nosql");
foodstore.pedidos.drop();          // idempotente: permite re-ejecutar el script

// ---------------------------------------------------------------------------
// Bloque 1 - Migracion
// Un documento = un pedido completo (cabecera + lineas + datos del cliente).
// El _id ES el id original de pedido.pedido_id: no se inventan claves.
// ---------------------------------------------------------------------------
const pedidos = [
  {
    _id: 1,
    pedido_id: 1,
    fecha: ISODate("2026-06-28T20:06:30.148803-03:00"),
    forma_pago: "EFECTIVO",
    cliente: { cliente_id: 453, nombre: "Cliente 453", email: "cliente453@example.com", telefono: "555-000453" },
    lineas: [
        { producto_id: 1, nombre: "Producto 1", categoria: "Bebidas", cantidad: 5, precio_unitario: 1868.53, subtotal: 9342.65 }
    ],
    total: 9342.65,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 2,
    pedido_id: 2,
    fecha: ISODate("2026-06-22T13:47:35.025016-03:00"),
    forma_pago: "TARJETA",
    cliente: { cliente_id: 14648, nombre: "Cliente 14648", email: "cliente14648@example.com", telefono: "555-014648" },
    lineas: [
        { producto_id: 2, nombre: "Producto 2", categoria: "Comidas", cantidad: 4, precio_unitario: 4847.34, subtotal: 19389.36 }
    ],
    total: 19389.36,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 3,
    pedido_id: 3,
    fecha: ISODate("2026-04-24T03:56:45.421229-03:00"),
    forma_pago: "TARJETA",
    cliente: { cliente_id: 15329, nombre: "Cliente 15329", email: "cliente15329@example.com", telefono: "555-015329" },
    lineas: [
        { producto_id: 3, nombre: "Producto 3", categoria: "Postres", cantidad: 5, precio_unitario: 2850.81, subtotal: 14254.05 }
    ],
    total: 14254.05,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 4,
    pedido_id: 4,
    fecha: ISODate("2026-06-12T00:23:26.620474-03:00"),
    forma_pago: "TRANSFERENCIA",
    cliente: { cliente_id: 12804, nombre: "Cliente 12804", email: "cliente12804@example.com", telefono: "555-012804" },
    lineas: [
        { producto_id: 4, nombre: "Producto 4", categoria: "Snacks", cantidad: 3, precio_unitario: 1536.34, subtotal: 4609.02 }
    ],
    total: 4609.02,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 5,
    pedido_id: 5,
    fecha: ISODate("2026-08-25T11:07:54.368831-03:00"),
    forma_pago: "TARJETA",
    cliente: { cliente_id: 6968, nombre: "Cliente 6968", email: "cliente6968@example.com", telefono: "555-006968" },
    lineas: [
        { producto_id: 5, nombre: "Producto 5", categoria: "Lácteos", cantidad: 5, precio_unitario: 1119.23, subtotal: 5596.15 }
    ],
    total: 5596.15,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 6,
    pedido_id: 6,
    fecha: ISODate("2026-06-25T20:54:03.874779-03:00"),
    forma_pago: "EFECTIVO",
    cliente: { cliente_id: 12840, nombre: "Cliente 12840", email: "cliente12840@example.com", telefono: "555-012840" },
    lineas: [
        { producto_id: 6, nombre: "Producto 6", categoria: "Panadería", cantidad: 2, precio_unitario: 2485.69, subtotal: 4971.38 }
    ],
    total: 4971.38,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 7,
    pedido_id: 7,
    fecha: ISODate("2025-09-13T07:32:32.455194-03:00"),
    forma_pago: "TRANSFERENCIA",
    cliente: { cliente_id: 16145, nombre: "Cliente 16145", email: "cliente16145@example.com", telefono: "555-016145" },
    lineas: [
        { producto_id: 7, nombre: "Producto 7", categoria: "Verdulería", cantidad: 5, precio_unitario: 2563.43, subtotal: 12817.15 }
    ],
    total: 12817.15,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 50001,
    pedido_id: 50001,
    fecha: ISODate("2026-05-03T21:32:56.167989-03:00"),
    forma_pago: "TARJETA",
    cliente: { cliente_id: 2506, nombre: "Cliente 2506", email: "cliente2506@example.com", telefono: "555-002506" },
    lineas: [
        { producto_id: 1, nombre: "Producto 1", categoria: "Bebidas", cantidad: 1, precio_unitario: 1868.53, subtotal: 1868.53 }
    ],
    total: 1868.53,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 100001,
    pedido_id: 100001,
    fecha: ISODate("2025-12-28T12:36:36.893343-03:00"),
    forma_pago: "TRANSFERENCIA",
    cliente: { cliente_id: 8073, nombre: "Cliente 8073", email: "cliente8073@example.com", telefono: "555-008073" },
    lineas: [
        { producto_id: 1, nombre: "Producto 1", categoria: "Bebidas", cantidad: 4, precio_unitario: 1868.53, subtotal: 7474.12 }
    ],
    total: 7474.12,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  },
  {
    _id: 150001,
    pedido_id: 150001,
    fecha: ISODate("2026-03-09T09:05:14.682599-03:00"),
    forma_pago: "TRANSFERENCIA",
    cliente: { cliente_id: 1318, nombre: "Cliente 1318", email: "cliente1318@example.com", telefono: "555-001318" },
    lineas: [
        { producto_id: 1, nombre: "Producto 1", categoria: "Bebidas", cantidad: 3, precio_unitario: 1868.53, subtotal: 5605.59 }
    ],
    total: 5605.59,
    origen: { motor: "PostgreSQL", tablas: ["pedido", "detalle_pedido", "cliente", "producto"], base: "practica_bd2_tp" }
  }
];

const resultado = foodstore.pedidos.insertMany(pedidos);
print("Documentos insertados: " + Object.keys(resultado.insertedIds).length);

// ---------------------------------------------------------------------------
// Bloque 2 - Indices de apoyo
// - "lineas.producto_id": indice multikey, sostiene la consulta c)
// - forma_pago:          sostiene la consulta b)
// - total:               sostiene la consulta d)
// ---------------------------------------------------------------------------
foodstore.pedidos.createIndex({ "lineas.producto_id": 1 }, { name: "idx_lineas_producto" });
foodstore.pedidos.createIndex({ forma_pago: 1 }, { name: "idx_forma_pago" });
foodstore.pedidos.createIndex({ total: -1 }, { name: "idx_total_desc" });

// ---------------------------------------------------------------------------
// Bloque 2b - Validacion de esquema ($jsonSchema)
// Replica a nivel de motor las restricciones estructurales que en PostgreSQL
// resolvian NOT NULL / CHECK / la Regla 2 (trigger diferido):
//   - campos obligatorios y tipos
//   - forma_pago dentro del dominio del ENUM
//   - cantidad > 0 y precio_unitario >= 0
//   - lineas con minItems: 1  -> Regla 2 pasa a ser ESTRUCTURAL
// ---------------------------------------------------------------------------
foodstore.runCommand({
  collMod: "pedidos",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["pedido_id", "fecha", "forma_pago", "cliente", "lineas", "total"],
      properties: {
        pedido_id:  { bsonType: ["int", "long", "double"] },
        fecha:      { bsonType: "date" },
        forma_pago: { enum: ["EFECTIVO", "TARJETA", "TRANSFERENCIA"] },
        total:      { bsonType: ["int", "long", "double"], minimum: 0 },
        cliente: {
          bsonType: "object",
          required: ["cliente_id", "nombre"],
          properties: { cliente_id: { bsonType: ["int", "long", "double"] } }
        },
        lineas: {
          bsonType: "array",
          minItems: 1,
          items: {
            bsonType: "object",
            required: ["producto_id", "cantidad", "precio_unitario"],
            properties: {
              producto_id:     { bsonType: ["int", "long", "double"] },
              cantidad:        { bsonType: ["int", "long", "double"], minimum: 1 },
              precio_unitario: { bsonType: ["int", "long", "double"], minimum: 0 }
            }
          }
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
print("Validador de esquema aplicado sobre foodstore_nosql.pedidos");

// ---------------------------------------------------------------------------
// Bloque 3 - Consultas de la consigna 4
// ---------------------------------------------------------------------------

print("\n===== a) Todos los pedidos con su identificador y estado =====");
foodstore.pedidos.find(
  {},
  { _id: 1, fecha: 1, forma_pago: 1, total: 1 }
).sort({ _id: 1 }).forEach(d => print(
  d._id + " | " + d.fecha.toISOString().slice(0, 10) + " | " + d.forma_pago + " | $" + d.total
));

// "estado" del pedido en Food Store = forma_pago (el modelo real no tiene
// columna estado; ver informe, seccion 2.3).
print("\n===== b) Pedidos con estado = TARJETA =====");
const b = foodstore.pedidos.find(
  { forma_pago: "TARJETA" },
  { _id: 1, forma_pago: 1, total: 1 }
).sort({ _id: 1 }).toArray();
b.forEach(d => print(d._id + " | " + d.forma_pago + " | $" + d.total));
print("Cantidad: " + b.length);
print("IDs: [" + b.map(d => d._id).join(", ") + "]");

print("\n===== c) Pedidos que contienen el producto 1 en lineas =====");
const c = foodstore.pedidos.find(
  { "lineas.producto_id": 1 },
  { _id: 1, lineas: { $elemMatch: { producto_id: 1 } } }
).sort({ _id: 1 }).toArray();
c.forEach(d => print(
  d._id + " | " + d.lineas[0].nombre + " | cant " + d.lineas[0].cantidad +
  " x $" + d.lineas[0].precio_unitario
));
print("Cantidad: " + c.length);
print("IDs: [" + c.map(d => d._id).join(", ") + "]");

// Umbral: $10.000. Promedio de la coleccion = $8.592,80 y mediana = $6.539,86,
// por lo que 10.000 aísla el tercio superior de pedidos (3 de 10).
print("\n===== d) Pedidos con total > 10000 =====");
const d4 = foodstore.pedidos.find(
  { total: { $gt: 10000 } },
  { _id: 1, total: 1 }
).sort({ total: -1 }).toArray();
d4.forEach(d => print(d._id + " | $" + d.total));
print("Cantidad: " + d4.length);
print("IDs: [" + d4.map(d => d._id).join(", ") + "]");

// ---------------------------------------------------------------------------
// Bloque 4 - Verificacion del modelo
// ---------------------------------------------------------------------------
print("\n===== Verificacion =====");
print("Documentos en la coleccion: " + foodstore.pedidos.countDocuments({}));
print("Total facturado en la coleccion: $" + foodstore.pedidos.aggregate([
  { $group: { _id: null, total: { $sum: "$total" } } }
]).toArray()[0].total);
print("Documento de ejemplo (pedido 1):");
printjson(foodstore.pedidos.findOne({ _id: 1 }));

// ---------------------------------------------------------------------------
// Bloque 5 - Prueba negativa: la Regla 2 ahora la rechaza el motor
// ---------------------------------------------------------------------------
print("\n===== Prueba negativa: pedido sin lineas (Regla 2) =====");
try {
  foodstore.pedidos.insertOne({
    _id: 999999,
    pedido_id: 999999,
    fecha: new Date(),
    forma_pago: "EFECTIVO",
    cliente: { cliente_id: 1, nombre: "Pedido de prueba" },
    lineas: [],
    total: 0,
    origen: { motor: "prueba-negativa" }
  });
  print("ERROR: el documento invalido fue aceptado");
} catch (e) {
  print("RECHAZADO por el validador -> " + String(e.message).split("\n")[0].slice(0, 160));
}

print("\n===== Prueba negativa: cantidad = 0 =====");
try {
  foodstore.pedidos.insertOne({
    _id: 999998,
    pedido_id: 999998,
    fecha: new Date(),
    forma_pago: "EFECTIVO",
    cliente: { cliente_id: 1, nombre: "Pedido de prueba" },
    lineas: [{ producto_id: 1, cantidad: 0, precio_unitario: 100 }],
    total: 0,
    origen: { motor: "prueba-negativa" }
  });
  print("ERROR: el documento invalido fue aceptado");
} catch (e) {
  print("RECHAZADO por el validador -> " + String(e.message).split("\n")[0].slice(0, 160));
}
print("\nIDs migrados: [1, 2, 3, 4, 5, 6, 7, 50001, 100001, 150001]");
