# Guía Completa de Despliegue - CRUD con Kubernetes

Despliegue de una aplicación web completa (Python/Flask) con base de datos (PostgreSQL) en Kubernetes (Minikube).

## 🎯 Características del Proyecto

- ✅ **CRUD Completo**: Crear, Leer, Actualizar y Eliminar registros
- ✅ **API REST**: Endpoints bien estructurados
- ✅ **Interfaz Web**: HTML/CSS/JavaScript interactivo
- ✅ **Configuración Segura**: Uso de ConfigMaps y Secrets
- ✅ **Inicialización Automática**: Tabla creada automáticamente
- ✅ **Arquitectura de Microservicios**: Base de datos y aplicación en pods separados

## 📦 Componentes

| Componente | Descripción | Archivo | Tecnología | Tipo de Servicio |
|------------|-------------|---------|------------|------------------|
| **Base de Datos** | Almacena los datos en la tabla `registros` | `db-deployment.yaml` | PostgreSQL 14 | `ClusterIP` (Solo interno) |
| **Aplicación Web** | API REST y interfaz gráfica CRUD | `app-deployment.yaml` | Python/Flask | `NodePort` (Acceso externo) |
| **Configuración** | ConfigMap y Secret para variables | `db-config.yaml` | Kubernetes | - |

## 🔌 Endpoints de la API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/registros` | Lista todos los registros |
| `GET` | `/api/registros/<id>` | Obtiene un registro específico |
| `POST` | `/api/crear` | Crea un nuevo registro |
| `PUT` | `/api/registros/<id>` | Actualiza un registro existente |
| `DELETE` | `/api/registros/<id>` | Elimina un registro |
| `GET` | `/` | Interfaz web HTML |

## 📋 Requisitos Previos

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) instalado
- `kubectl` instalado
- Docker instalado
- Navegador web

## 🚀 Preparación del Entorno

### 1. Iniciar Minikube

```bash
# Inicia el clúster de Kubernetes local
minikube start

# Verifica que el clúster esté funcionando
kubectl cluster-info
kubectl get nodes
```

### 2. Configurar el Entorno Docker de Minikube

```bash
# Configura la terminal para usar el Docker de Minikube
# Esto permite construir imágenes directamente en el clúster
eval $(minikube docker-env)

# Verifica la configuración
docker ps
```

**Nota**: Este comando debe ejecutarse en cada nueva terminal que uses.

---

## 📊 Paso 1: Desplegar ConfigMap y Secret

### 1.1. Aplicar la Configuración

```bash
# Aplica el ConfigMap y Secret con las credenciales
kubectl apply -f db-config.yaml

# Verifica que se hayan creado correctamente
kubectl get configmap
kubectl get secret
```

**¿Qué hace esto?**
- **ConfigMap**: Almacena configuración no sensible (nombres de base de datos, usuarios, hosts)
- **Secret**: Almacena información sensible (contraseñas) de forma segura
- **Script de inicialización**: Se monta automáticamente en PostgreSQL para crear la tabla

---

## 🗄️ Paso 2: Desplegar la Base de Datos (PostgreSQL)

### 2.1. Desplegar PostgreSQL

```bash
# Aplica el deployment de PostgreSQL
kubectl apply -f db-deployment.yaml

# Verifica el estado del pod
kubectl get pods -l app=postgres

# Espera hasta que el STATUS sea "Running"
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Verifica el servicio
kubectl get service postgres-service
```

### 2.2. Verificar la Inicialización Automática

```bash
# Obtén el nombre del pod de PostgreSQL
POD_NAME=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
echo "Pod de PostgreSQL: $POD_NAME"

# Verifica los logs para confirmar que la tabla se creó
kubectl logs $POD_NAME | grep -i "registros"

# (Opcional) Conectarse a PostgreSQL para verificar manualmente
kubectl exec -it $POD_NAME -- psql -U usuario_db -d registro_db -c "\dt"
```

**¿Qué sucede aquí?**
1. PostgreSQL inicia automáticamente
2. Lee el script `init-db.sql` del ConfigMap
3. Crea la tabla `registros` automáticamente
4. No necesitas crear la tabla manualmente

---

## 🌐 Paso 3: Desplegar la Aplicación Web (Flask)

### 3.1. Estructura de Archivos

Asegúrate de tener estos archivos en tu directorio:
```
├── app.py                  # Aplicación Flask con API REST completa
├── Dockerfile              # Instrucciones para construir la imagen
├── requirements.txt        # Dependencias de Python
├── templates/
│   └── index.html         # Interfaz web con CRUD completo
├── db-config.yaml         # ConfigMap y Secret
├── db-deployment.yaml     # Deployment de PostgreSQL
└── app-deployment.yaml    # Deployment de la aplicación
```

### 3.2. Construir la Imagen Docker

```bash
# Verifica que estés usando el Docker de Minikube
eval $(minikube docker-env)

# Construye la imagen de la aplicación
docker build -t mi-app-web:v1 .

# Verifica que la imagen se haya creado
docker images | grep mi-app-web
```

### 3.3. Desplegar la Aplicación

```bash
# Aplica el deployment de la aplicación
kubectl apply -f app-deployment.yaml

# Verifica el estado del pod
kubectl get pods -l app=app-web

# Espera hasta que el STATUS sea "Running"
kubectl wait --for=condition=ready pod -l app=app-web --timeout=120s

# Verifica el servicio
kubectl get service app-web-service
```

### 3.4. Acceder a la Aplicación

```bash
# Obtén la URL de acceso
minikube service app-web-service --url

# O abre directamente en el navegador
minikube service app-web-service
```

**¡Listo!** Ahora deberías poder:
- ✅ Ver la interfaz web en tu navegador
- ✅ Crear nuevos registros
- ✅ Listar todos los registros
- ✅ Editar registros existentes
- ✅ Eliminar registros

---

## 🔍 Verificación y Pruebas

### Verificar todos los recursos

```bash
# Ver todos los pods
kubectl get pods

# Ver todos los servicios
kubectl get services

# Ver ConfigMaps y Secrets
kubectl get configmap,secret

# Ver logs de la aplicación
kubectl logs -l app=app-web

# Ver logs de la base de datos
kubectl logs -l app=postgres
```

### Probar la API directamente

```bash
# Obtén la URL del servicio
URL=$(minikube service app-web-service --url)

# Listar todos los registros
curl $URL/api/registros

# Crear un nuevo registro
curl -X POST $URL/api/crear \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan Pérez","mensaje":"Hola desde curl!"}'

# Actualizar un registro (cambia el ID según corresponda)
curl -X PUT $URL/api/registros/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan Actualizado","mensaje":"Mensaje actualizado"}'

# Eliminar un registro
curl -X DELETE $URL/api/registros/1
```

---

## 🔧 Solución de Problemas

### El pod de PostgreSQL no inicia

```bash
# Ver el estado detallado del pod
kubectl describe pod -l app=postgres

# Ver los logs
kubectl logs -l app=postgres

# Verificar que el ConfigMap y Secret existan
kubectl get configmap db-config
kubectl get secret db-secret
```

### La aplicación no puede conectarse a la base de datos

```bash
# Verifica que el servicio de PostgreSQL esté activo
kubectl get service postgres-service

# Verifica las variables de entorno en el pod de la aplicación
kubectl exec -it $(kubectl get pod -l app=app-web -o jsonpath='{.items[0].metadata.name}') -- env | grep DB

# Verifica los logs de la aplicación
kubectl logs -l app=app-web
```

### La imagen Docker no se encuentra

```bash
# Asegúrate de estar usando el Docker de Minikube
eval $(minikube docker-env)

# Reconstruye la imagen
docker build -t mi-app-web:v1 .

# Verifica que la imagen exista
docker images | grep mi-app-web

# Elimina y recrea el deployment
kubectl delete -f app-deployment.yaml
kubectl apply -f app-deployment.yaml
```

---

## 🧹 Limpieza

### Eliminar todos los recursos

```bash
# Elimina la aplicación
kubectl delete -f app-deployment.yaml

# Elimina la base de datos
kubectl delete -f db-deployment.yaml

# Elimina ConfigMap y Secret
kubectl delete -f db-config.yaml

# Verifica que todo se haya eliminado
kubectl get all
```

### Detener Minikube

```bash
# Detiene el clúster
minikube stop

# (Opcional) Elimina completamente el clúster
minikube delete
```

---

## 📚 Conceptos Clave de Kubernetes

### 🔑 ConfigMap vs Secret

- **ConfigMap**: Para configuración no sensible (nombres, URLs, puertos)
- **Secret**: Para información sensible (contraseñas, tokens, claves API)

### 🌐 Tipos de Services

- **ClusterIP** (Base de datos): Solo accesible dentro del clúster
- **NodePort** (Aplicación): Accesible desde fuera del clúster en un puerto específico
- **LoadBalancer**: Para entornos cloud (AWS, GCP, Azure)

### 📦 Deployments

- Gestiona réplicas de pods
- Actualiza aplicaciones sin downtime
- Rollback automático si hay errores

### 🔄 Comunicación entre Pods

1. La aplicación se conecta a `postgres-service` (nombre DNS interno)
2. Kubernetes resuelve el DNS al IP del pod de PostgreSQL
3. La comunicación es interna al clúster (no sale a Internet)

---

## 🎓 Próximos Pasos para Aprender

1. **Persistencia de Datos**: Usar PersistentVolumes para que los datos no se pierdan
2. **Escalabilidad**: Aumentar réplicas de la aplicación
3. **Health Checks**: Agregar liveness y readiness probes
4. **Resource Limits**: Configurar límites de CPU y memoria
5. **Namespaces**: Organizar recursos en diferentes espacios
6. **Ingress**: Usar un ingress controller en lugar de NodePort
7. **Helm**: Empaquetar la aplicación con Helm charts
8. **CI/CD**: Automatizar el despliegue con GitHub Actions o GitLab CI

---

## 📖 Recursos Adicionales

- [Documentación oficial de Kubernetes](https://kubernetes.io/docs/)
- [Tutorial de Minikube](https://minikube.sigs.k8s.io/docs/tutorials/)
- [PostgreSQL en Kubernetes](https://kubernetes.io/docs/tutorials/stateful-application/postgres/)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

**¡Felicidades!** 🎉 Has desplegado exitosamente una aplicación CRUD completa en Kubernetes con arquitectura de microservicios.
