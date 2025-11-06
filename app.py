# app.py - API CRUD completo con Flask y PostgreSQL
import os
import psycopg2
from flask import Flask, jsonify, request, render_template

# --- Configuración de Conexión ---
app = Flask(__name__)

# Variables de entorno para la conexión a PostgreSQL
DB_HOST = os.environ.get('DB_HOST', 'postgres-service')
DB_USER = os.environ.get('POSTGRES_USER', 'usuario_db')
DB_PASSWORD = os.environ.get('POSTGRES_PASSWORD', 'clave_segura_123')
DB_NAME = os.environ.get('POSTGRES_DB', 'registro_db')

def get_db_connection():
    # Intenta conectarse usando las variables del entorno K8s
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    return conn

# --- Rutas CRUD (API endpoints) ---

# RUTA DE CREACIÓN (API - POST)
@app.route('/api/crear', methods=['POST'])
def crear_registro():
    # ... (Lógica de creación de registro, igual que antes, pero renombramos la ruta a /api/crear) ...
    try:
        data = request.get_json()
        nombre = data['nombre']
        mensaje = data['mensaje']
        
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO registros (nombre, mensaje) VALUES (%s, %s)", (nombre, mensaje))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"status": "Registro creado"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# RUTA DE CONSULTA (API - GET)
@app.route('/api/registros', methods=['GET'])
def listar_registros():
    """Lista todos los registros de la base de datos"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, nombre, mensaje, fecha FROM registros ORDER BY id DESC;")
        registros = cur.fetchall()
        cur.close()
        conn.close()

        resultado = [{"id": r[0], "nombre": r[1], "mensaje": r[2], "fecha": r[3].strftime("%Y-%m-%d %H:%M:%S")} for r in registros]
        return jsonify(resultado)
    except Exception as e:
        return jsonify({"error": "Error al conectar o consultar la base de datos", "details": str(e)}), 500

# RUTA DE OBTENER UN REGISTRO (API - GET)
@app.route('/api/registros/<int:id>', methods=['GET'])
def obtener_registro(id):
    """Obtiene un registro específico por ID"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, nombre, mensaje, fecha FROM registros WHERE id = %s;", (id,))
        registro = cur.fetchone()
        cur.close()
        conn.close()

        if registro:
            resultado = {"id": registro[0], "nombre": registro[1], "mensaje": registro[2], "fecha": registro[3].strftime("%Y-%m-%d %H:%M:%S")}
            return jsonify(resultado)
        else:
            return jsonify({"error": "Registro no encontrado"}), 404
    except Exception as e:
        return jsonify({"error": "Error al consultar el registro", "details": str(e)}), 500

# RUTA DE ACTUALIZACIÓN (API - PUT)
@app.route('/api/registros/<int:id>', methods=['PUT'])
def actualizar_registro(id):
    """Actualiza un registro existente"""
    try:
        data = request.get_json()
        nombre = data.get('nombre')
        mensaje = data.get('mensaje')

        if not nombre or not mensaje:
            return jsonify({"error": "Nombre y mensaje son requeridos"}), 400

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("UPDATE registros SET nombre = %s, mensaje = %s WHERE id = %s", (nombre, mensaje, id))

        if cur.rowcount == 0:
            conn.close()
            return jsonify({"error": "Registro no encontrado"}), 404

        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"status": "Registro actualizado exitosamente"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# RUTA DE ELIMINACIÓN (API - DELETE)
@app.route('/api/registros/<int:id>', methods=['DELETE'])
def eliminar_registro(id):
    """Elimina un registro por ID"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("DELETE FROM registros WHERE id = %s", (id,))

        if cur.rowcount == 0:
            conn.close()
            return jsonify({"error": "Registro no encontrado"}), 404

        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"status": "Registro eliminado exitosamente"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Rutas de Interfaz Gráfica (Web Endpoints) ---

@app.route('/')
def index():
    # Esta ruta servirá el archivo HTML que contiene el formulario y la tabla.
    return render_template('index.html')

if __name__ == '__main__':
    # Asegúrate de que el módulo 'psycopg2' esté instalado en el contenedor
    app.run(host='0.0.0.0', port=5000)