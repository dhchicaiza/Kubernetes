
Desplige de una aplicación web simple (Python/Flask) con una base de datos (PostgreSQL) en un clúster de Kubernetes (Minikube).

## Componentes

**Base de Datos** | Almacena los datos y la tabla `registros`. | `db-deployment.yaml` | PostgreSQL 14 | `ClusterIP` (Solo interno) |
**Aplicación Web** | Provee la interfaz gráfica CRUD y la lógica de conexión a la BD. | `app-deployment.yaml` | Python / Flask | `NodePort` (Acceso externo) |

## Requisitos y Preparación

1.  **Instalar:** [Minikube](https://minikube.sigs.k8s.io/docs/start/) y `kubectl`.
2.  **Iniciar el clúster:**
    # Inicia el entorno de Minikube, creando un nodo de Kubernetes en la máquina local.
   
    minikube start
    
3.  **Configurar el entorno Docker de Minikube** (para construir la imagen de la app):
    # Configura tu terminal para que el comando 'docker' apunte al demonio de Docker dentro de Minikube.
    # Esto permite construir imágenes directamente en el clúster, evitando subirlas a un registro público.
    eval $(minikube docker-env)
    
---

## Despliegue de la Base de Datos (PostgreSQL)

### 1.1. Configuración del Deployment y Service de la BD

Cree el archivo `db-deployment.yaml` con las credenciales de entorno. Este archivo define dos objetos:
**Deployment:** Se encarga de crear y mantener el Pod que ejecuta el contenedor de PostgreSQL.
**Service:** Expone la base de datos dentro del clúster con un nombre DNS fijo (`postgres-service`) para que la aplicación pueda encontrarla.

### 1.2. Aplicación y Verificación

1.  **Desplegar la BD y el Service:**
    # Aplica la configuración del archivo YAML, creando el Deployment y el Service en Kubernetes.
    kubectl apply -f db-deployment.yaml

2.  **Verificar el estado del Pod:**
    # Lista los Pods que tienen la etiqueta 'app=postgres'.
    # Espere hasta que la columna 'STATUS' muestre 'Running'.
    kubectl get pods -l app=postgres
    kubectl get services

### 1.3. Conexión y Creación de la Tabla

1.  **Obtener el nombre exacto del Pod** de PostgreSQL (ej. `postgres-deployment-xxxx-yyyy`).
    # Filtra los pods por la etiqueta y extrae solo el nombre del pod.
    POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
    echo "Conectándose a: $POD_NAME"

2.  **Acceder a la terminal del Pod:**
    # Ejecuta un comando 'bash' de forma interactiva dentro del contenedor del Pod de PostgreSQL.
    kubectl exec -it $POD_NAME -- bash

3.  **Acceder al cliente `psql` y crear la tabla `registros`:**
    # Dentro del Pod, conéctate a la base de datos 'mibase' con el usuario 'usuario'.
    psql -U usuario -d mibase

4.  Dentro del prompt (`mibase=#`), **ejecute las sentencias SQL:**
    -- Crea la tabla para almacenar los datos.
    CREATE TABLE registros (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100),
        mensaje VARCHAR(255),
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- \dt: Muestra las tablas creadas
    \dt

    -- \q: Salir de psql.
    \q

5.  **Salir del Pod:**
    exit

---

## Despliegue de la Aplicación Web (Flask/Python)

La aplicación Flask provee la lógica de conexión y la interfaz gráfica HTML/JS para el CRUD.

### 2.1. Estructura de Archivos

Asegúrese de tener los siguientes archivos en su directorio de trabajo: `app.py`, `Dockerfile`, `requirements.txt` y la carpeta `templates/index.html`. El código de `app.py` debe usar el nombre del service `postgres-service` para la conexión.

### 2.2. Construir la Imagen Docker

Construir y etiquetar la imagen. Este proceso empaqueta la aplicación Flask en una imagen de Docker que Kubernetes puede usar.
# Construye una imagen de Docker llamada 'mi-app-web:v1' usando el Dockerfile
docker build -t mi-app-web:v1 .

### 2.3. Configuración del Deployment y Service de la App

Cree el archivo `app-deployment.yaml` para desplegar la aplicación y exponerla con `NodePort`.
*   **Deployment:** Crea el Pod para la aplicación web usando la imagen Docker que acabamos de construir.
*   **Service (`NodePort`):** Expone la aplicación fuera del clúster para que podamos acceder a ella desde un navegador.

### 2.4. Aplicar y Probar el CRUD Gráfico

1.  **Desplegar la aplicación y el Service:**
    # Aplica la configuración para crear el Deployment y el Service de la aplicación web.
    kubectl apply -f app-deployment.yaml

2.  **Obtener la URL de acceso:**
    # Minikube proporciona una URL accesible desde tu máquina para el Service de tipo NodePort.
    minikube service app-web-service --url

---

## Limpieza

# Elimina los recursos creados a partir de los archivos YAML.
kubectl delete -f app-deployment.yaml
kubectl delete -f db-deployment.yaml

# Detiene el clúster de Minikube.
minikube stop
