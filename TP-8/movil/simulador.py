"""
============================================================================
UTN - TECNICATURA UNIVERSITARIA EN PROGRAMACIÓN | BASE DE DATOS II
TRABAJO PRÁCTICO N.º 8: Food Store en la feria: la base de la tablet
Simulador de Sincronización y Semáforo Offline (Consigna 2.b y 2.c)
============================================================================
"""

import sqlite3
import csv
import os
import sys

DB_PATH = os.path.join(os.path.dirname(__file__), "foodstore_movil.db")
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), "schema_sqlite.sql")
SNAPSHOT_CSV = os.path.join(os.path.dirname(__file__), "servidor_snapshot.csv")
SEMAFORO_SQL = os.path.join(os.path.dirname(__file__), "semaforo.sql")

def obtener_conexion():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def inicializar_base(conn):
    print("[*] Inicializando base de datos SQLite con tablas STRICT...")
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        conn.executescript(f.read())
    conn.commit()
    print("[+] Esquema creado exitosamente.")

def importar_snapshot(conn, csv_path=SNAPSHOT_CSV):
    print(f"[*] Importando instantánea del servidor desde '{os.path.basename(csv_path)}'...")
    cursor = conn.cursor()
    cursor.execute("DELETE FROM snapshot_servidor;")
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cursor.execute("""
                INSERT INTO snapshot_servidor (id, nombre, precio_centavos, stock, disponible, eliminado)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (int(row["id"]), row["nombre"], int(row["precio_centavos"]),
                  int(row["stock"]), row["disponible"], row["eliminado"]))
    
    # Cargar producto_cache desde snapshot_servidor
    cursor.execute("""
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
    """)
    conn.commit()
    print("[+] Catálogo local 'producto_cache' actualizado exitosamente.")

def ejecutar_semaforo(conn):
    print("[*] Ejecutando semáforo de sincronización (evaluando solicitudes PENDIENTE)...")
    with open(SEMAFORO_SQL, "r", encoding="utf-8") as f:
        sql = f.read()
    conn.executescript(sql)
    conn.commit()
    print("[+] Semáforo ejecutado.")

def mostrar_estado_cola(conn, titulo="Estado de cola_sync"):
    cursor = conn.cursor()
    cursor.execute("SELECT solicitud_uuid, id_local, estado, motivo FROM cola_sync;")
    filas = cursor.fetchall()
    print(f"\n--- {titulo} ---")
    for uuid_sol, id_local, estado, motivo in filas:
        color = "\033[92m" if estado == "SIMULADO_APROBADO" else ("\033[93m" if estado == "CONFLICTO" else "\033[91m")
        reset = "\033[0m"
        print(f"• Solicitud: {uuid_sol[:8]}... | Pedido: {id_local[:8]}... | Estado: {color}{estado}{reset}")
        print(f"  Motivo: {motivo}")
    print("-" * 50)

def ejecutar_simulacion_completa():
    conn = obtener_conexion()
    inicializar_base(conn)
    importar_snapshot(conn)

    print("\n" + "="*60)
    print("EJECUCIÓN DE CASOS DE PRUEBA (C1 a C7)")
    print("="*60)

    # C1: Catálogo disponible
    print("\n>>> CASO C1: Consulta del catálogo disponible offline")
    cursor = conn.cursor()
    cursor.execute("SELECT id, nombre, precio_centavos, stock_visto FROM producto_cache WHERE disponible = 1 AND eliminado = 0;")
    prods = cursor.fetchall()
    print(f"[+] Productos activos disponibles offline: {len(prods)}")
    for p in prods:
        print(f"    - ID {p[0]}: {p[1]} | ${p[2]/100:.2f} | Stock visto: {p[3]}")

    # C5: Borrador sin cambios -> SIMULADO_APROBADO
    print("\n>>> CASO C5: Borrador sin cambios (coincide con servidor)")
    conn.executescript("""
        INSERT INTO pedido_borrador VALUES ('borrador-c5', 'cliente_c5', 'EFECTIVO', '2026-11-08 19:30:00');
        INSERT INTO item_borrador VALUES ('borrador-c5', 101, 1, 450000); -- Hamb Clásica ($4500)
        INSERT INTO cola_sync VALUES ('solicitud-c5', 'borrador-c5', 'PENDIENTE', NULL);
    """)
    ejecutar_semaforo(conn)
    mostrar_estado_cola(conn, "Resultado Caso C5")

    # C2: Conflicto de precio -> CONFLICTO, luego cliente acepta -> SIMULADO_APROBADO
    print("\n>>> CASO C2: Conflicto de precio (precio visto anterior al aumento del servidor)")
    conn.executescript("""
        -- Borrador creado cuando la Hamburguesa Doble costaba $5500 (550000), pero en servidor cuesta $6000 (600000)
        INSERT INTO pedido_borrador VALUES ('borrador-c2', 'cliente_c2', 'TARJETA', '2026-11-08 19:35:00');
        INSERT INTO item_borrador VALUES ('borrador-c2', 102, 1, 550000); 
        INSERT INTO cola_sync VALUES ('solicitud-c2-v1', 'borrador-c2', 'PENDIENTE', NULL);
    """)
    ejecutar_semaforo(conn)
    mostrar_estado_cola(conn, "Resultado Caso C2 (Fase 1: Detección de Conflicto)")

    print("[*] El cliente acepta el nuevo precio de $6000. Se actualiza el borrador y se reintenta:")
    conn.executescript("""
        UPDATE item_borrador SET precio_centavos_visto = 600000 WHERE id_local = 'borrador-c2' AND producto_id = 102;
        INSERT INTO cola_sync VALUES ('solicitud-c2-v2', 'borrador-c2', 'PENDIENTE', NULL);
    """)
    ejecutar_semaforo(conn)
    mostrar_estado_cola(conn, "Resultado Caso C2 (Fase 2: Cliente Acepta Nuevo Precio)")

    # C3: Stock insuficiente -> RECHAZADO
    print("\n>>> CASO C3: Borrador por más unidades de las disponibles en el servidor")
    conn.executescript("""
        -- Cerveza IPA (ID 105) solo tiene stock 5 en servidor. El cliente pide 10.
        INSERT INTO pedido_borrador VALUES ('borrador-c3', 'cliente_c3', 'EFECTIVO', '2026-11-08 19:40:00');
        INSERT INTO item_borrador VALUES ('borrador-c3', 105, 10, 320000);
        INSERT INTO cola_sync VALUES ('solicitud-c3', 'borrador-c3', 'PENDIENTE', NULL);
    """)
    ejecutar_semaforo(conn)
    mostrar_estado_cola(conn, "Resultado Caso C3")

    # C4: Producto dado de baja lógica (eliminado = 't') -> RECHAZADO
    print("\n>>> CASO C4: Borrador con producto dado de baja en servidor (Lápida)")
    conn.executescript("""
        -- Promo Combo Amigos (ID 108) tiene eliminado = 't' en el servidor
        INSERT INTO pedido_borrador VALUES ('borrador-c4', 'cliente_c4', 'TRANSFERENCIA', '2026-11-08 19:45:00');
        INSERT INTO item_borrador VALUES ('borrador-c4', 108, 1, 990000);
        INSERT INTO cola_sync VALUES ('solicitud-c4', 'borrador-c4', 'PENDIENTE', NULL);
    """)
    ejecutar_semaforo(conn)
    mostrar_estado_cola(conn, "Resultado Caso C4")

    # C6: Reenviar misma solicitud (mismo UUID) -> No se duplica
    print("\n>>> CASO C6: Idempotencia - Reenvío de solicitud duplicada")
    try:
        cursor.execute("INSERT INTO cola_sync VALUES ('solicitud-c5', 'borrador-c5', 'PENDIENTE', NULL);")
        conn.commit()
    except sqlite3.IntegrityError as e:
        print(f"[+] Éxito esperado: SQLite rechazó duplicación de solicitud_uuid: {e}")

    # C7: Restricciones de integridad (cantidad 0 y producto inexistente)
    print("\n>>> CASO C7: Restricciones de integridad (CHECK y Clave Foránea)")
    try:
        cursor.execute("INSERT INTO item_borrador VALUES ('borrador-c5', 101, 0, 450000);")
    except sqlite3.IntegrityError as e:
        print(f"[+] Éxito esperado: Rechazo por cantidad = 0 (CHECK): {e}")

    try:
        cursor.execute("INSERT INTO item_borrador VALUES ('borrador-c5', 9999, 1, 500000);")
    except sqlite3.IntegrityError as e:
        print(f"[+] Éxito esperado: Rechazo por producto inexistente (FK): {e}")

    conn.close()
    print("\n[✔] Simulación finalizada correctamente.")

if __name__ == "__main__":
    ejecutar_simulacion_completa()
