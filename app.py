# app.py (Código con ruta para servir la interfaz web)
import os
import psycopg2
from flask import Flask, jsonify, request, render_template

# --- Configuración de Conexión (Igual que antes) ---
app = Flask(__name__)
# ... (variables de entorno DB_HOST, DB_USER, etc., igual que antes) ...
DB_HOST = os.environ.get('DB_HOST', 'postgres-service') 
DB_USER = os.environ.get('POSTGRES_USER', 'usuario')
DB_PASSWORD = os.environ.get('POSTGRES_PASSWORD', 'miclave')
DB_NAME = os.environ.get('POSTGRES_DB', 'mibase')

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
    # ... (Lógica de consulta de registros, igual que antes, pero renombramos la ruta a /api/registros) ...
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

# --- Rutas de Interfaz Gráfica (Web Endpoints) ---

@app.route('/')
def index():
    # Esta ruta servirá el archivo HTML que contiene el formulario y la tabla.
    return render_template('index.html')

if __name__ == '__main__':
    # Asegúrate de que el módulo 'psycopg2' esté instalado en el contenedor
    app.run(host='0.0.0.0', port=5000)