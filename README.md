# 🚀 Aplicación CRUD con Kubernetes

Proyecto educativo para aprender Kubernetes y Docker mediante una aplicación web completa con arquitectura de microservicios.

## 📋 Descripción

Aplicación web CRUD (Create, Read, Update, Delete) desarrollada con Flask y PostgreSQL, desplegada en Kubernetes usando Minikube. Demuestra conceptos fundamentales de contenedores, orquestación y arquitectura de microservicios.

## ✨ Características

- ✅ **CRUD Completo**: API REST con todas las operaciones
- ✅ **Interfaz Web**: HTML/CSS/JavaScript interactivo
- ✅ **Arquitectura de Microservicios**: Base de datos y aplicación en pods separados
- ✅ **Configuración Segura**: ConfigMaps y Secrets de Kubernetes
- ✅ **Inicialización Automática**: Setup automático de la base de datos
- ✅ **Persistencia**: Volúmenes para mantener los datos

## 🏗️ Arquitectura

```
┌─────────────────┐         ┌──────────────────┐
│   Navegador     │         │    Minikube      │
│                 │         │                  │
└────────┬────────┘         │  ┌────────────┐  │
         │                  │  │  App Pod   │  │
         │                  │  │  (Flask)   │  │
         │ HTTP (NodePort)  │  │  Port 5000 │  │
         └──────────────────┼─▶│            │  │
                            │  └─────┬──────┘  │
                            │        │         │
                            │        │ ClusterIP
                            │        │         │
                            │  ┌─────▼──────┐  │
                            │  │  DB Pod    │  │
                            │  │ (PostgreSQL)│ │
                            │  │  Port 5432 │  │
                            │  └────────────┘  │
                            └──────────────────┘
```

## 🛠️ Tecnologías

- **Backend**: Python 3.9, Flask
- **Base de Datos**: PostgreSQL 14
- **Contenedores**: Docker
- **Orquestación**: Kubernetes (Minikube)
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)

## 📂 Estructura del Proyecto

```
├── app.py                  # API Flask con endpoints CRUD
├── Dockerfile              # Imagen Docker de la aplicación
├── requirements.txt        # Dependencias Python
├── templates/
│   └── index.html         # Interfaz web
├── db-config.yaml         # ConfigMap y Secret
├── db-deployment.yaml     # Deployment de PostgreSQL
├── app-deployment.yaml    # Deployment de Flask
├── init-db.sql            # Script de inicialización
├── pasos_despliegue.md    # Guía detallada de despliegue
└── README.md              # Este archivo
```

## 🚀 Inicio Rápido

### Requisitos Previos

- Minikube instalado
- kubectl instalado
- Docker instalado

### Despliegue en 3 Pasos

```bash
# 1. Iniciar Minikube y configurar Docker
minikube start
eval $(minikube docker-env)

# 2. Construir la imagen de la aplicación
docker build -t mi-app-web:v1 .

# 3. Desplegar todo
kubectl apply -f db-config.yaml
kubectl apply -f db-deployment.yaml
kubectl apply -f app-deployment.yaml

# 4. Acceder a la aplicación
minikube service app-web-service
```

## 🔌 API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/` | Interfaz web |
| `GET` | `/api/registros` | Listar todos los registros |
| `GET` | `/api/registros/<id>` | Obtener un registro |
| `POST` | `/api/crear` | Crear registro |
| `PUT` | `/api/registros/<id>` | Actualizar registro |
| `DELETE` | `/api/registros/<id>` | Eliminar registro |

## 📖 Documentación Completa

Para instrucciones detalladas de despliegue, solución de problemas y conceptos de Kubernetes, consulta [pasos_despliegue.md](pasos_despliegue.md).

## 🧪 Pruebas

```bash
# Obtener URL de la aplicación
URL=$(minikube service app-web-service --url)

# Listar registros
curl $URL/api/registros

# Crear un registro
curl -X POST $URL/api/crear \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Test","mensaje":"Hola Kubernetes"}'
```

## 🧹 Limpieza

```bash
# Eliminar todos los recursos
kubectl delete -f app-deployment.yaml
kubectl delete -f db-deployment.yaml
kubectl delete -f db-config.yaml

# Detener Minikube
minikube stop
```

## 🎓 Conceptos de Kubernetes Aplicados

- **Pods**: Unidad básica de despliegue
- **Deployments**: Gestión de réplicas y actualizaciones
- **Services**: Exposición y comunicación entre pods
  - ClusterIP: Para comunicación interna
  - NodePort: Para acceso externo
- **ConfigMaps**: Configuración no sensible
- **Secrets**: Información sensible (contraseñas)
- **Volumes**: Persistencia de datos

## 🔐 Seguridad

- Contraseñas almacenadas en Secrets de Kubernetes
- Variables de entorno en lugar de hardcodear credenciales
- Separación de configuración y código

## 📚 Recursos de Aprendizaje

- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Tutorial de Minikube](https://minikube.sigs.k8s.io/docs/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [PostgreSQL en Kubernetes](https://kubernetes.io/docs/tutorials/stateful-application/)

## 🤝 Contribuciones

Este es un proyecto educativo. Siéntete libre de hacer fork y experimentar.

## 📝 Licencia

Proyecto educativo de código abierto.

---

**Desarrollado con fines educativos para aprender Kubernetes, Docker y arquitectura de microservicios** 🎓
