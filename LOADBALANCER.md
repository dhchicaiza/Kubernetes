# 🔄 BALANCEADOR DE CARGA CON 2 PODS - GUÍA COMPLETA

## 📋 Índice
1. [Introducción](#introducción)
2. [Arquitectura](#arquitectura)
3. [Ajustes Detallados](#ajustes-detallados)
4. [Despliegue](#despliegue)
5. [Pruebas y Verificación](#pruebas-y-verificación)
6. [Escalado Automático](#escalado-automático)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Introducción

Este proyecto implementa un **balanceador de carga en Kubernetes con 2 pods**, diseñado para:

- ✅ **Alta disponibilidad**: Si un pod falla, el otro sigue sirviendo tráfico
- ✅ **Distribución de carga**: El tráfico se reparte equitativamente entre los 2 pods
- ✅ **Actualizaciones sin downtime**: Rolling updates mantienen el servicio disponible
- ✅ **Escalado automático** (opcional): Aumenta pods según la carga
- ✅ **Health checks**: Detecta y recupera pods problemáticos

---

## 🏗️ Arquitectura

```
                           ┌─────────────────────────────┐
                           │   LOADBALANCER SERVICE      │
                           │   (IP Externa: X.X.X.X:80)  │
                           └──────────┬──────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │   Algoritmo: Round-Robin          │
                    │   SessionAffinity: None            │
                    └─────────────────┬─────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
          ┌─────────▼────────┐              ┌─────────▼────────┐
          │   POD 1          │              │   POD 2          │
          │   nginx:alpine   │              │   nginx:alpine   │
          │   ────────────   │              │   ────────────   │
          │   CPU: 100m-500m │              │   CPU: 100m-500m │
          │   RAM: 64Mi-256Mi│              │   RAM: 64Mi-256Mi│
          │   Port: 80       │              │   Port: 80       │
          │   ────────────   │              │   ────────────   │
          │   ✓ Liveness    │              │   ✓ Liveness    │
          │   ✓ Readiness   │              │   ✓ Readiness   │
          │   ✓ Startup     │              │   ✓ Startup     │
          └─────────┬────────┘              └─────────┬────────┘
                    │                                 │
          ┌─────────▼────────┐              ┌────────▼─────────┐
          │   NODO 1         │              │   NODO 2         │
          │  (preferido)     │              │  (preferido)     │
          └──────────────────┘              └──────────────────┘
```

### Flujo de Tráfico

1. **Cliente** → Hace petición a `LoadBalancerIP:80`
2. **LoadBalancer** → Selecciona un pod (round-robin)
3. **Pod** → Procesa la petición y responde
4. **Si un pod falla**:
   - Readiness probe lo detecta
   - LoadBalancer deja de enviarle tráfico
   - Todo el tráfico va al pod saludable
   - Liveness probe reinicia el pod problemático
   - Cuando se recupera, vuelve al balanceo

---

## ⚙️ Ajustes Detallados

### 1️⃣ RÉPLICAS: 2 Pods

```yaml
spec:
  replicas: 2
```

**¿Por qué 2 pods?**
- ✅ **Mínimo para alta disponibilidad**: Si 1 falla, el otro funciona
- ✅ **Balanceo real**: Reparte la carga 50%-50%
- ✅ **Costo-beneficio**: Más pods = más recursos consumidos
- ✅ **Escalable**: Con HPA puede crecer a 5 pods automáticamente

**Alternativas:**
- **1 pod**: No hay alta disponibilidad ni balanceo
- **3+ pods**: Mayor disponibilidad y distribución, pero más recursos

---

### 2️⃣ ESTRATEGIA: RollingUpdate

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1         # Permite 1 pod extra durante actualización
    maxUnavailable: 0   # Siempre al menos 2 pods disponibles
```

**¿Cómo funciona el Rolling Update?**

**Escenario: Actualizar de nginx:1.23 a nginx:1.24**

```
Estado Inicial:
[Pod1: v1.23] [Pod2: v1.23]  ← 2 pods funcionando

Paso 1 (maxSurge: 1):
[Pod1: v1.23] [Pod2: v1.23] [Pod3: v1.24]  ← Crea 1 pod nuevo (total: 3)

Paso 2 (espera readiness de Pod3):
[Pod1: v1.23] [Pod2: v1.23] [Pod3: v1.24 ✓]  ← Pod3 listo

Paso 3 (elimina Pod1):
[Pod2: v1.23] [Pod3: v1.24 ✓]  ← Ahora 2 pods

Paso 4 (crea Pod4):
[Pod2: v1.23] [Pod3: v1.24 ✓] [Pod4: v1.24]  ← Crea otro pod nuevo

Paso 5 (espera readiness de Pod4):
[Pod2: v1.23] [Pod3: v1.24 ✓] [Pod4: v1.24 ✓]

Paso 6 (elimina Pod2):
[Pod3: v1.24 ✓] [Pod4: v1.24 ✓]  ← Actualización completa

Estado Final:
[Pod3: v1.24] [Pod4: v1.24]  ← 2 pods en nueva versión
```

**Ventajas:**
- ✅ **Cero downtime**: Siempre hay pods disponibles
- ✅ **Gradual**: Detecta problemas antes de actualizar todos
- ✅ **Reversible**: Fácil hacer rollback si algo falla

---

### 3️⃣ RECURSOS: Requests y Limits

```yaml
resources:
  requests:
    memory: "64Mi"    # Mínimo garantizado
    cpu: "100m"       # 0.1 CPU
  limits:
    memory: "256Mi"   # Máximo permitido
    cpu: "500m"       # 0.5 CPU
```

**¿Qué significan?**

| Métrica | Request | Limit | Explicación |
|---------|---------|-------|-------------|
| **Memoria** | 64Mi | 256Mi | Kubernetes reserva 64Mi. Si usa >256Mi, pod reinicia (OOMKilled) |
| **CPU** | 100m | 500m | Kubernetes reserva 0.1 CPU. Si usa >500m, se limita (throttling) |

**Con 2 pods:**
- **Recursos reservados**: 128Mi RAM, 0.2 CPU (2 × requests)
- **Consumo máximo**: 512Mi RAM, 1.0 CPU (2 × limits)

**¿Cómo elegir valores?**

1. **Medir primero**: Desplegar con valores altos, observar consumo real
2. **Requests**: Consumo promedio típico
3. **Limits**: Consumo pico máximo + margen 20-30%

**Ejemplo con métricas:**
```bash
# Ver consumo real de los pods
kubectl top pods -l app=web-lb

# Resultado ejemplo:
NAME                    CPU   MEMORY
web-lb-pod-1           45m   52Mi
web-lb-pod-2           38m   48Mi

# Conclusión: requests (100m/64Mi) son adecuados
```

---

### 4️⃣ PROBES: Health Checks

#### A) **Liveness Probe** - ¿Está vivo?

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 15   # Espera 15s antes de empezar
  periodSeconds: 10         # Chequea cada 10s
  failureThreshold: 3       # 3 fallos = reinicia pod
```

**Funcionamiento:**
```
Tiempo  | Acción
--------|--------------------------------------------------------
0s      | Pod inicia
15s     | Primera verificación → GET http://pod-ip:80/
25s     | Segunda verificación → GET http://pod-ip:80/
35s     | Tercera verificación → GET http://pod-ip:80/ (FALLA)
45s     | Cuarta verificación (FALLA)
55s     | Quinta verificación (FALLA) ← 3 fallos consecutivos
55s     | ❌ Kubernetes REINICIA el pod
```

**¿Cuándo usar?**
- ✅ Detectar deadlocks (app bloqueada)
- ✅ Detectar corrupción de memoria
- ✅ Detectar app en estado inválido

#### B) **Readiness Probe** - ¿Está listo?

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3       # 3 fallos = saca del LoadBalancer
```

**Diferencia con Liveness:**
- **Liveness falla** → Reinicia el pod (destructivo)
- **Readiness falla** → Quita del LoadBalancer (no destructivo)

**Ejemplo práctico:**

```
Pod está iniciando, conectando a DB...

Tiempo  | Readiness | LoadBalancer | Estado
--------|-----------|--------------|----------------------------------
0s      | ❌ FAIL   | Sin tráfico  | App conectando a DB...
5s      | ❌ FAIL   | Sin tráfico  | Todavía conectando...
10s     | ✅ OK     | ✓ Recibe     | Conectado, listo para peticiones
15s     | ✅ OK     | ✓ Recibe     | Sirviendo tráfico
20s     | ❌ FAIL   | Sin tráfico  | DB desconectó (pero app viva)
25s     | ❌ FAIL   | Sin tráfico  | Intentando reconectar...
30s     | ✅ OK     | ✓ Recibe     | Reconectado, vuelve al balanceo
```

**Ventaja:** El pod no se reinicia (conserva conexiones, cache, estado)

#### C) **Startup Probe** - ¿Inició correctamente?

```yaml
startupProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 2
  failureThreshold: 15      # 15 × 2s = 30s máximo de inicio
```

**¿Para qué sirve?**
- Apps que tardan en iniciar (Java, frameworks pesados)
- Desactiva liveness probe hasta que startup tenga éxito
- Evita que liveness reinicie un pod que está iniciando lentamente

---

### 5️⃣ ANTI-AFINIDAD: Distribución en Nodos

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - web-lb
        topologyKey: kubernetes.io/hostname
```

**¿Qué hace?**
- **PREFIERE** poner cada pod en un nodo diferente
- No es obligatorio (si solo hay 1 nodo, ambos van ahí)

**Escenarios:**

**Cluster con 2+ nodos:**
```
Nodo1: [Pod1: web-lb] ← Primer pod aquí
Nodo2: [Pod2: web-lb] ← Segundo pod aquí (preferido)
```

**Cluster con 1 nodo:**
```
Nodo1: [Pod1: web-lb] [Pod2: web-lb] ← Ambos aquí (permitido)
```

**¿Por qué es importante?**
- ✅ Si Nodo1 falla, Nodo2 sigue sirviendo
- ✅ Mejor disponibilidad
- ✅ Aislamiento de fallos

**Alternativa obligatoria:**
```yaml
# requiredDuringSchedulingIgnoredDuringExecution (más estricto)
# Si no hay nodos disponibles, el pod NO se crea
```

---

### 6️⃣ SERVICE: LoadBalancer

```yaml
type: LoadBalancer
sessionAffinity: None
externalTrafficPolicy: Cluster
```

**Tipos de Service comparados:**

| Tipo | Acceso | IP Externa | Load Balancing |
|------|--------|------------|----------------|
| **ClusterIP** | Solo dentro del cluster | ❌ No | Sí (interno) |
| **NodePort** | NodoIP:Puerto | ❌ No | Sí |
| **LoadBalancer** | IP dedicada | ✅ Sí | ✅ Sí |

**Algoritmo de balanceo: Round-Robin**

```
Petición 1 → Pod1
Petición 2 → Pod2
Petición 3 → Pod1
Petición 4 → Pod2
...
```

**sessionAffinity:**
- **None** (default): Round-robin puro, mejor balanceo
- **ClientIP**: Mismo cliente va siempre al mismo pod (sticky session)

**¿Cuándo usar sessionAffinity: ClientIP?**
```yaml
sessionAffinity: ClientIP
sessionAffinityConfig:
  clientIP:
    timeoutSeconds: 10800  # 3 horas
```

Usar cuando:
- ✅ App guarda sesión en memoria (sin Redis/DB)
- ✅ WebSockets (necesita misma conexión)
- ✅ Cargas de archivos largas

**externalTrafficPolicy:**

| Valor | Ventajas | Desventajas |
|-------|----------|-------------|
| **Cluster** | Mejor balanceo, más resiliente | Pierde IP origen del cliente |
| **Local** | Preserva IP cliente, menor latencia | Puede haber balanceo desigual |

---

### 7️⃣ HPA: Escalado Automático

```yaml
minReplicas: 2
maxReplicas: 5
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      averageUtilization: 70  # Escala cuando CPU > 70%
```

**¿Cómo escala?**

**Fórmula:**
```
pods_deseados = ceil(pods_actuales × (uso_actual / objetivo))
```

**Ejemplo práctico:**

```
Estado inicial:
- 2 pods
- CPU promedio: 40%
- Objetivo: 70%

Cálculo: 2 × (40 / 70) = 1.14 → ceil(1.14) = 2 pods
→ Sin cambios (dentro del objetivo)

───────────────────────────────────────────────────

Pico de tráfico:
- 2 pods
- CPU promedio: 85%
- Objetivo: 70%

Cálculo: 2 × (85 / 70) = 2.43 → ceil(2.43) = 3 pods
→ ⬆️ ESCALA A 3 PODS

───────────────────────────────────────────────────

Más tráfico:
- 3 pods
- CPU promedio: 80%
- Objetivo: 70%

Cálculo: 3 × (80 / 70) = 3.43 → ceil(3.43) = 4 pods
→ ⬆️ ESCALA A 4 PODS

───────────────────────────────────────────────────

Tráfico baja:
- 4 pods
- CPU promedio: 30%
- Objetivo: 70%

Cálculo: 4 × (30 / 70) = 1.71 → ceil(1.71) = 2 pods
→ ⬇️ ESCALA A 2 PODS (respeta minReplicas)
```

**Comportamiento de escalado:**

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0       # Escala arriba inmediatamente
    policies:
    - type: Percent
      value: 100                        # Puede doblar pods
      periodSeconds: 15

  scaleDown:
    stabilizationWindowSeconds: 300     # Espera 5 min antes de bajar
    policies:
    - type: Pods
      value: 1                          # Baja de 1 en 1
      periodSeconds: 60
```

**Timeline de scale down:**

```
Tiempo | CPU | Pods | Acción
-------|-----|------|---------------------------------------
0:00   | 85% | 4    | Tráfico alto
0:01   | 30% | 4    | Tráfico baja bruscamente
0:01   | 30% | 4    | HPA detecta, pero espera (stabilization)
1:00   | 30% | 4    | Todavía esperando...
3:00   | 30% | 4    | Todavía esperando...
5:00   | 30% | 4    | ✓ 5 min de estabilidad
5:00   | 30% | 3    | ⬇️ Remueve 1 pod
6:00   | 30% | 3    | Espera 1 min
6:00   | 30% | 2    | ⬇️ Remueve otro pod (mínimo alcanzado)
```

**¿Por qué esperar 5 min para bajar?**
- ✅ Evita "flapping" (subir/bajar constantemente)
- ✅ El tráfico puede subir de nuevo
- ✅ Más estable que reactivo

---

### 8️⃣ PDB: Pod Disruption Budget

```yaml
minAvailable: 1
```

**¿Qué protege?**

Durante operaciones voluntarias (no crashes):
- Drain de nodo (mantenimiento)
- Actualización de Kubernetes
- Redimensionamiento de cluster

**Ejemplo: Drain de nodo**

```
Sin PDB:
Nodo1: [Pod1] [Pod2]
Nodo2: []

$ kubectl drain nodo1
→ Elimina Pod1 y Pod2 simultáneamente
→ ⚠️ 0 pods disponibles temporalmente
→ ⚠️ DOWNTIME

───────────────────────────────────────────────────

Con PDB (minAvailable: 1):
Nodo1: [Pod1] [Pod2]
Nodo2: []

$ kubectl drain nodo1
→ Crea Pod3 en Nodo2
→ Espera que Pod3 esté ready
→ Elimina Pod1
→ Crea Pod4 en Nodo2
→ Espera que Pod4 esté ready
→ Elimina Pod2
→ ✅ Siempre al menos 1 pod disponible
→ ✅ CERO DOWNTIME
```

---

## 🚀 Despliegue

### Paso 1: Crear el Deployment y Service

```bash
# Aplicar la configuración
kubectl apply -f loadbalancer-deployment.yaml

# Verificar deployment
kubectl get deployment web-loadbalancer-deployment

# Verificar pods (deben ser 2)
kubectl get pods -l app=web-lb

# Verificar service
kubectl get service web-loadbalancer-service
```

### Paso 2: Obtener IP del LoadBalancer

```bash
# En Minikube
minikube service web-loadbalancer-service --url

# En cloud (AWS, GCP, Azure)
kubectl get service web-loadbalancer-service
# Espera a que EXTERNAL-IP cambie de <pending> a una IP real
```

### Paso 3: Probar el balanceo

```bash
# Obtener IP del LoadBalancer
LB_IP=$(kubectl get service web-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Hacer múltiples peticiones
for i in {1..10}; do
  curl http://$LB_IP
  echo "---"
done
```

---

## ✅ Pruebas y Verificación

### 1️⃣ Verificar que hay 2 pods

```bash
kubectl get pods -l app=web-lb

# Salida esperada:
NAME                                            READY   STATUS    RESTARTS   AGE
web-loadbalancer-deployment-5d4f8b6c9d-abc12   1/1     Running   0          2m
web-loadbalancer-deployment-5d4f8b6c9d-def34   1/1     Running   0          2m
```

### 2️⃣ Verificar distribución en nodos

```bash
kubectl get pods -l app=web-lb -o wide

# Ver columna NODE - idealmente en nodos diferentes
```

### 3️⃣ Probar alta disponibilidad

```bash
# Eliminar un pod manualmente
kubectl delete pod <nombre-de-un-pod>

# Kubernetes debe:
# 1. Crear un pod nuevo inmediatamente
# 2. El LoadBalancer sigue funcionando con el otro pod
# 3. Cuando el nuevo pod esté listo, vuelve al balanceo

# Verificar que siempre hay 2 pods
watch kubectl get pods -l app=web-lb
```

### 4️⃣ Ver logs de ambos pods

```bash
# Logs en tiempo real de ambos pods
kubectl logs -l app=web-lb --follow --prefix
```

### 5️⃣ Simular carga para HPA

```bash
# Generar tráfico (instala 'hey' primero)
# https://github.com/rakyll/hey
LB_IP=$(kubectl get service web-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
hey -z 5m -c 100 http://$LB_IP

# Observar escalado
watch kubectl get hpa web-loadbalancer-hpa
watch kubectl get pods -l app=web-lb
```

### 6️⃣ Verificar health checks

```bash
# Ver eventos de probes
kubectl describe pod <nombre-pod> | grep -A 5 "Liveness\|Readiness\|Startup"

# Ver eventos de reinicios
kubectl get events --sort-by='.lastTimestamp' | grep -i "unhealthy\|failed"
```

---

## 📈 Escalado Automático

### Prerequisito: Metrics Server

```bash
# Verificar si metrics-server está instalado
kubectl get deployment metrics-server -n kube-system

# Si no está, instalarlo
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# En Minikube
minikube addons enable metrics-server
```

### Monitorear HPA

```bash
# Ver estado del HPA
kubectl get hpa web-loadbalancer-hpa

# Salida ejemplo:
NAME                      REFERENCE                                    TARGETS   MINPODS   MAXPODS   REPLICAS
web-loadbalancer-hpa      Deployment/web-loadbalancer-deployment       45%/70%   2         5         2

# Ver eventos de escalado
kubectl describe hpa web-loadbalancer-hpa
```

### Probar escalado manual

```bash
# Escalar manualmente (HPA lo ajustará después)
kubectl scale deployment web-loadbalancer-deployment --replicas=4

# HPA volverá al número óptimo según métricas
```

---

## 🔧 Troubleshooting

### ❌ Problema: LoadBalancer en estado <pending>

**Síntoma:**
```bash
kubectl get svc web-loadbalancer-service
# EXTERNAL-IP: <pending>
```

**Causa:** Estás en Minikube o cluster sin proveedor de LoadBalancer

**Solución:**
```bash
# En Minikube, usar tunnel
minikube tunnel
# Deja esta terminal abierta

# O usa minikube service
minikube service web-loadbalancer-service
```

---

### ❌ Problema: Pods no se distribuyen en nodos diferentes

**Verificar:**
```bash
kubectl get pods -l app=web-lb -o wide
# Ver columna NODE
```

**Causa:** Solo hay 1 nodo o la anti-afinidad es "preferred" (no obligatoria)

**Verificar nodos:**
```bash
kubectl get nodes
```

**Solución:** La configuración actual es "preferred", está bien tener ambos en el mismo nodo

---

### ❌ Problema: HPA no escala

**Síntoma:**
```bash
kubectl get hpa
# TARGETS: <unknown>
```

**Causa:** Metrics server no está instalado

**Verificar:**
```bash
kubectl top nodes
kubectl top pods

# Si da error, instalar metrics-server
minikube addons enable metrics-server
```

---

### ❌ Problema: Pod se reinicia constantemente (CrashLoopBackOff)

**Verificar logs:**
```bash
kubectl logs <nombre-pod>
kubectl describe pod <nombre-pod>
```

**Causas comunes:**
1. Imagen incorrecta
2. Liveness probe muy agresivo
3. Recursos insuficientes (OOMKilled)

**Solución temporal:**
```bash
# Aumentar initialDelaySeconds del liveness probe
# O aumentar limits de memoria
```

---

### ❌ Problema: Tráfico solo va a un pod

**Verificar endpoints:**
```bash
kubectl get endpoints web-loadbalancer-service

# Debe mostrar IPs de ambos pods
# Si solo hay 1 IP, el otro pod no pasa readiness probe
```

**Verificar readiness:**
```bash
kubectl get pods -l app=web-lb

# READY debe ser 1/1 en ambos
# Si es 0/1, ver logs y eventos
```

---

## 📊 Monitoreo Continuo

### Dashboard de Kubernetes

```bash
# En Minikube
minikube dashboard
```

### Comandos útiles

```bash
# Estado general
kubectl get all -l app=web-lb

# Recursos consumidos
kubectl top pods -l app=web-lb

# Eventos recientes
kubectl get events --sort-by='.lastTimestamp' | grep web-lb

# Watch en tiempo real
watch kubectl get pods,svc,hpa -l app=web-lb
```

---

## 🎓 Resumen de Conceptos Clave

| Concepto | Valor | Propósito |
|----------|-------|-----------|
| **Réplicas** | 2 | Alta disponibilidad + balanceo |
| **maxSurge** | 1 | Permite 3 pods durante update |
| **maxUnavailable** | 0 | Siempre 2+ pods disponibles |
| **CPU request** | 100m | Reserva 0.1 CPU por pod |
| **CPU limit** | 500m | Máximo 0.5 CPU por pod |
| **Memory request** | 64Mi | Reserva 64MB por pod |
| **Memory limit** | 256Mi | Máximo 256MB por pod |
| **Liveness** | 15s delay | Reinicia si falla 3 veces |
| **Readiness** | 5s delay | Quita del LB si falla 3 veces |
| **HPA min** | 2 | Mínimo de pods |
| **HPA max** | 5 | Máximo de pods |
| **HPA target** | 70% CPU | Escala cuando excede 70% |
| **PDB** | minAvailable: 1 | Al menos 1 pod durante drain |

---

## 🔗 Próximos Pasos

1. **Monitoreo avanzado**: Integrar Prometheus + Grafana
2. **Logs centralizados**: ELK Stack o Loki
3. **Ingress**: Agregar Ingress Controller para múltiples servicios
4. **TLS/HTTPS**: Certificados SSL con cert-manager
5. **CI/CD**: Automatizar despliegues con GitOps (ArgoCD/Flux)

---

## 📚 Referencias

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
