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
- ✅ **Balanceador de Carga**: LoadBalancer con 2 pods para alta disponibilidad
- ✅ **Escalado Automático**: HPA (Horizontal Pod Autoscaler) de 2 a 5 pods
- ✅ **Health Checks**: Probes para detectar y recuperar pods problemáticos

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
├── app.py                       # API Flask con endpoints CRUD
├── Dockerfile                   # Imagen Docker de la aplicación
├── requirements.txt             # Dependencias Python
├── templates/
│   └── index.html              # Interfaz web
├── db-config.yaml              # ConfigMap y Secret
├── db-deployment.yaml          # Deployment de PostgreSQL
├── app-deployment.yaml         # Deployment de Flask
├── loadbalancer-deployment.yaml # Deployment del Load Balancer (2 pods)
├── deploy.sh                   # Script de despliegue automático
├── deploy-loadbalancer.sh      # Script de despliegue del Load Balancer
├── test-loadbalancer.sh        # Suite de pruebas del Load Balancer
├── status.sh                   # Script para ver estado del cluster
├── cleanup.sh                  # Script para limpiar recursos
├── DEPLOYMENT.md               # Guía detallada de despliegue
├── LOADBALANCER.md             # Documentación completa del Load Balancer
└── README.md                   # Este archivo
```

## 🚀 Inicio Rápido

### Requisitos Previos

- Minikube instalado
- Docker instalado
- kubectl (opcional - minikube incluye su propio kubectl)

### Opción 1: Despliegue Automático (Recomendado)

```bash
# 1. Iniciar Minikube y configurar Docker
minikube start
eval $(minikube docker-env)

# 2. Ejecutar script de despliegue
chmod +x deploy.sh
./deploy.sh
```

El script `deploy.sh` automáticamente:
- Construye la imagen Docker
- Despliega todos los recursos de Kubernetes
- Espera a que los servicios estén listos
- Muestra la información de acceso

### Opción 2: Despliegue Manual

```bash
# 1. Iniciar Minikube y configurar Docker
minikube start
eval $(minikube docker-env)

# 2. Construir la imagen de la aplicación
docker build -t mi-app-web:v1 .

# 3. Desplegar todo
minikube kubectl -- apply -f db-config.yaml
minikube kubectl -- apply -f db-deployment.yaml
minikube kubectl -- apply -f app-deployment.yaml

# 4. Acceder a la aplicación
minikube service app-web-service
```

> **Nota**: Si no tienes kubectl instalado, usa `minikube kubectl --` en lugar de `kubectl` en todos los comandos.

### Scripts de Utilidad

```bash
# Ver estado del cluster y aplicaciones
./status.sh

# Limpiar todos los recursos
./cleanup.sh
```

## ⚖️ Balanceador de Carga con 2 Pods

Este proyecto incluye una implementación completa de balanceador de carga con alta disponibilidad, escalado automático y health checks detallados.

### 🎯 Características del Load Balancer

- **2 Pods mínimos**: Alta disponibilidad básica con distribución 50/50 del tráfico
- **Service tipo LoadBalancer**: Distribución automática de tráfico entre pods
- **Rolling Updates**: Actualizaciones sin downtime (maxSurge: 1, maxUnavailable: 0)
- **Health Checks completos**:
  - **Liveness Probe**: Reinicia pods problemáticos
  - **Readiness Probe**: Quita pods no listos del balanceo
  - **Startup Probe**: Maneja inicios lentos
- **Anti-afinidad de pods**: Prefiere distribuir pods en nodos diferentes
- **HPA (Horizontal Pod Autoscaler)**: Escala automáticamente de 2 a 5 pods cuando CPU > 70%
- **PDB (Pod Disruption Budget)**: Garantiza al menos 1 pod durante mantenimiento
- **Recursos configurados**: Requests (100m CPU, 64Mi RAM) y Limits (500m CPU, 256Mi RAM)

### 🚀 Despliegue del Load Balancer

```bash
# Desplegar el balanceador de carga
chmod +x deploy-loadbalancer.sh
./deploy-loadbalancer.sh

# En otra terminal, habilitar acceso externo (Minikube)
minikube tunnel
```

El script automáticamente:
1. ✅ Verifica que Minikube está corriendo
2. ✅ Habilita metrics-server (para HPA)
3. ✅ Despliega el balanceador con 2 pods
4. ✅ Configura el Service LoadBalancer
5. ✅ Habilita HPA y PDB
6. ✅ Verifica que todo está funcionando

### 🧪 Pruebas del Load Balancer

```bash
# Ejecutar suite completa de pruebas
./test-loadbalancer.sh
```

Las pruebas verifican:
- ✅ Que hay exactamente 2 pods corriendo
- ✅ Que todos los pods están READY
- ✅ Que el Service tiene 2 endpoints
- ✅ Conectividad al LoadBalancer
- ✅ Distribución de tráfico entre pods
- ✅ Alta disponibilidad (elimina un pod y verifica que el servicio sigue)
- ✅ Configuración de recursos
- ✅ HPA configurado correctamente
- ✅ PDB protegiendo contra interrupciones

### 📊 Monitoreo del Load Balancer

```bash
# Ver estado de los pods
kubectl get pods -l app=web-lb -o wide

# Ver métricas de recursos
kubectl top pods -l app=web-lb

# Ver estado del HPA
kubectl get hpa web-loadbalancer-hpa

# Ver logs de todos los pods
kubectl logs -l app=web-lb --follow --prefix

# Ver distribución en nodos
kubectl get pods -l app=web-lb -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName

# Probar el servicio
LB_IP=$(kubectl get svc web-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$LB_IP
```

### 📖 Documentación Detallada

Para entender todos los ajustes y configuraciones del balanceador:

```bash
# Ver documentación completa con explicaciones detalladas
cat LOADBALANCER.md
```

La documentación incluye:
- 📋 Explicación detallada de cada ajuste (réplicas, recursos, probes, etc.)
- 🏗️ Diagramas de arquitectura y flujo de tráfico
- 📊 Ejemplos de cómo funciona el escalado automático
- 🔧 Troubleshooting de problemas comunes
- ⚙️ Ejemplos de configuración avanzada

### 🧪 Simular Carga para Probar HPA

```bash
# Generar tráfico para probar el escalado automático
# (requiere 'hey' instalado: go install github.com/rakyll/hey@latest)

LB_IP=$(minikube service web-loadbalancer-service --url)
hey -z 5m -c 100 $LB_IP

# Observar el escalado en tiempo real
watch kubectl get hpa,pods -l app=web-lb
```

### 🎓 Conceptos Avanzados de Kubernetes

El balanceador de carga demuestra:

- **Load Balancing**: Distribución automática de tráfico
- **High Availability**: Redundancia con múltiples pods
- **Rolling Updates**: Actualizaciones sin downtime
- **Health Probes**: Detección automática de problemas
- **Resource Management**: Requests y Limits de CPU/memoria
- **Auto-scaling**: HPA basado en métricas
- **Pod Disruption Budgets**: Protección durante mantenimiento
- **Anti-affinity**: Distribución inteligente en nodos

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

- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Guía detallada de despliegue con Minikube, solución de problemas y comandos útiles
- **[LOADBALANCER.md](LOADBALANCER.md)**: Documentación completa del balanceador de carga con explicaciones detalladas de todos los ajustes
- **[pasos_despliegue.md](pasos_despliegue.md)**: Conceptos de Kubernetes y explicación paso a paso (si existe)

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

### Usando el script

```bash
./cleanup.sh
```

### Manual

```bash
# Eliminar todos los recursos
minikube kubectl -- delete -f app-deployment.yaml
minikube kubectl -- delete -f db-deployment.yaml
minikube kubectl -- delete -f db-config.yaml

# Detener Minikube
minikube stop

# Eliminar el cluster (opcional)
minikube delete
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
