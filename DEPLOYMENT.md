# Guía de Despliegue en Minikube

Esta guía te ayudará a desplegar la aplicación Flask con PostgreSQL en Minikube.

## Prerrequisitos

- Minikube instalado
- Docker instalado
- kubectl (opcional - minikube incluye su propio kubectl)

## Inicio Rápido

### 1. Iniciar Minikube

```bash
minikube start
```

### 2. Configurar Docker para usar el registro de Minikube

```bash
eval $(minikube docker-env)
```

⚠️ **Importante**: Este comando debe ejecutarse en cada nueva terminal que uses para construir imágenes Docker.

### 3. Desplegar la aplicación

```bash
chmod +x deploy.sh
./deploy.sh
```

Este script automáticamente:
- Construye la imagen Docker
- Aplica todas las configuraciones de Kubernetes
- Espera a que los servicios estén listos
- Muestra información de acceso

### 4. Acceder a la aplicación

```bash
minikube service app-web-service
```

Esto abrirá automáticamente la aplicación en tu navegador.

O para obtener solo la URL:

```bash
minikube service app-web-service --url
```

## Comandos Útiles

### Ver el estado del cluster

```bash
./status.sh
```

### Comandos individuales con kubectl

Si no tienes kubectl instalado, usa `minikube kubectl --` en su lugar:

```bash
# Ver todos los pods
minikube kubectl -- get pods

# Ver logs de un pod
minikube kubectl -- logs <nombre-pod>

# Ver servicios
minikube kubectl -- get services

# Describir un pod (para debugging)
minikube kubectl -- describe pod <nombre-pod>

# Ejecutar comando dentro de un pod
minikube kubectl -- exec -it <nombre-pod> -- /bin/bash
```

### Dashboard de Kubernetes

```bash
minikube dashboard
```

### Ver logs de la aplicación

```bash
# Listar pods para obtener el nombre
minikube kubectl -- get pods

# Ver logs de la aplicación Flask
minikube kubectl -- logs -f deployment/app-web-deployment

# Ver logs de PostgreSQL
minikube kubectl -- logs -f deployment/postgres-deployment
```

## Despliegue Manual (Paso a Paso)

Si prefieres desplegar manualmente:

```bash
# 1. Construir imagen
eval $(minikube docker-env)
docker build -t mi-app-web:v1 .

# 2. Aplicar configuraciones
minikube kubectl -- apply -f db-config.yaml
minikube kubectl -- apply -f db-deployment.yaml
minikube kubectl -- apply -f app-deployment.yaml

# 3. Verificar el estado
minikube kubectl -- get pods
minikube kubectl -- get services
```

## Actualizar la aplicación

Cuando hagas cambios en el código:

```bash
# 1. Asegúrate de estar usando el Docker de Minikube
eval $(minikube docker-env)

# 2. Reconstruir la imagen
docker build -t mi-app-web:v1 .

# 3. Reiniciar el deployment
minikube kubectl -- rollout restart deployment/app-web-deployment

# 4. Ver el progreso
minikube kubectl -- rollout status deployment/app-web-deployment
```

## Limpieza

Para eliminar todos los recursos:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

O manualmente:

```bash
minikube kubectl -- delete -f app-deployment.yaml
minikube kubectl -- delete -f db-deployment.yaml
minikube kubectl -- delete -f db-config.yaml
```

Para detener Minikube:

```bash
minikube stop
```

Para eliminar completamente el cluster:

```bash
minikube delete
```

## Arquitectura del Despliegue

```
┌─────────────────────────────────────────┐
│         Minikube Cluster                │
│                                         │
│  ┌──────────────────┐  ┌─────────────┐ │
│  │ app-web-service  │  │  postgres   │ │
│  │   (NodePort)     │  │   -service  │ │
│  │   Port: 8080     │  │ (ClusterIP) │ │
│  └────────┬─────────┘  └──────┬──────┘ │
│           │                   │        │
│  ┌────────▼─────────┐  ┌──────▼──────┐ │
│  │  Flask App Pod   │  │ Postgres Pod│ │
│  │  (mi-app-web:v1) │  │ (postgres:14│ │
│  │  Port: 5000      │  │ Port: 5432  │ │
│  └──────────────────┘  └─────────────┘ │
│           │                   │        │
│  ┌────────▼───────────────────▼──────┐ │
│  │     ConfigMaps & Secrets          │ │
│  │  - db-config                      │ │
│  │  - db-secret                      │ │
│  │  - db-init-script                 │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Recursos Desplegados

- **ConfigMap** (`db-config`): Configuración de la base de datos
- **Secret** (`db-secret`): Credenciales de la base de datos
- **ConfigMap** (`db-init-script`): Script SQL de inicialización
- **Deployment** (`postgres-deployment`): Base de datos PostgreSQL
- **Service** (`postgres-service`): Servicio interno para PostgreSQL
- **Deployment** (`app-web-deployment`): Aplicación Flask
- **Service** (`app-web-service`): Servicio expuesto para la aplicación

## Solución de Problemas

### El pod no inicia

```bash
# Ver detalles del pod
minikube kubectl -- describe pod <nombre-pod>

# Ver logs
minikube kubectl -- logs <nombre-pod>
```

### Error "ImagePullBackOff"

Asegúrate de haber ejecutado `eval $(minikube docker-env)` antes de construir la imagen.

### No puedo acceder a la aplicación

```bash
# Verificar que el servicio esté corriendo
minikube kubectl -- get services

# Obtener la URL
minikube service app-web-service --url
```

### La base de datos no se inicializa

```bash
# Ver logs de PostgreSQL
minikube kubectl -- logs deployment/postgres-deployment

# Conectarse al pod de PostgreSQL
minikube kubectl -- exec -it deployment/postgres-deployment -- psql -U usuario_db -d registro_db

# Verificar las tablas
\dt
```

## Variables de Entorno

Las siguientes variables se configuran automáticamente desde los ConfigMaps y Secrets:

- `DB_HOST`: postgres-service
- `POSTGRES_DB`: registro_db
- `POSTGRES_USER`: usuario_db
- `POSTGRES_PASSWORD`: (desde secret)

## Instalación Opcional de kubectl

Si prefieres tener kubectl instalado localmente:

### Linux
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### macOS
```bash
brew install kubectl
```

### Arch Linux
```bash
sudo pacman -S kubectl
```
