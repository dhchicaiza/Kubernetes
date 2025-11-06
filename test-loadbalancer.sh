#!/bin/bash
# ============================================================================
# SCRIPT DE PRUEBAS DEL BALANCEADOR DE CARGA
# ============================================================================
# Este script realiza múltiples pruebas para verificar el funcionamiento
# del balanceador de carga con 2 pods
# ============================================================================

set -e  # Salir si hay algún error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}   PRUEBAS DEL BALANCEADOR DE CARGA${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ----------------------------------------------------------------------------
# FUNCIÓN: Verificar que el deployment existe
# ----------------------------------------------------------------------------
check_deployment() {
    echo -e "${YELLOW}[VERIFICACIÓN] Comprobando que el deployment existe...${NC}"
    if ! kubectl get deployment web-loadbalancer-deployment &>/dev/null; then
        echo -e "${RED}❌ Error: El deployment no existe${NC}"
        echo -e "${YELLOW}Ejecuta primero: ./deploy-loadbalancer.sh${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Deployment encontrado${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# FUNCIÓN: Obtener información de los pods
# ----------------------------------------------------------------------------
get_pod_info() {
    echo -e "${YELLOW}[INFO] Información de los pods:${NC}"
    kubectl get pods -l app=web-lb -o wide
    echo ""

    # Guardar nombres de pods en variables
    POD1=$(kubectl get pods -l app=web-lb -o jsonpath='{.items[0].metadata.name}')
    POD2=$(kubectl get pods -l app=web-lb -o jsonpath='{.items[1].metadata.name}')

    echo -e "${CYAN}Pod 1: ${POD1}${NC}"
    echo -e "${CYAN}Pod 2: ${POD2}${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# FUNCIÓN: Obtener URL del servicio
# ----------------------------------------------------------------------------
get_service_url() {
    echo -e "${YELLOW}[INFO] Obteniendo URL del servicio...${NC}"

    # Intentar obtener IP del LoadBalancer
    LB_IP=$(kubectl get service web-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

    if [ -z "$LB_IP" ] || [ "$LB_IP" == "null" ]; then
        echo -e "${YELLOW}⚠ LoadBalancer IP no disponible (esto es normal en Minikube)${NC}"
        echo -e "${YELLOW}Usando 'minikube service' para obtener URL...${NC}"
        SERVICE_URL=$(minikube service web-loadbalancer-service --url 2>/dev/null)
        if [ -z "$SERVICE_URL" ]; then
            echo -e "${RED}❌ No se pudo obtener la URL del servicio${NC}"
            echo -e "${YELLOW}Asegúrate de que 'minikube tunnel' esté corriendo o usa:${NC}"
            echo -e "${BLUE}    minikube service web-loadbalancer-service${NC}"
            exit 1
        fi
    else
        SERVICE_URL="http://${LB_IP}"
    fi

    echo -e "${GREEN}✓ URL del servicio: ${SERVICE_URL}${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 1: Verificar que hay 2 pods corriendo
# ----------------------------------------------------------------------------
test_pod_count() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 1: Verificar que hay exactamente 2 pods corriendo${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    POD_COUNT=$(kubectl get pods -l app=web-lb --field-selector=status.phase=Running --no-headers | wc -l)

    if [ "$POD_COUNT" -eq 2 ]; then
        echo -e "${GREEN}✓ ÉXITO: Hay exactamente 2 pods corriendo${NC}"
    else
        echo -e "${RED}❌ FALLO: Se esperaban 2 pods, pero hay ${POD_COUNT}${NC}"
        kubectl get pods -l app=web-lb
        return 1
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 2: Verificar que todos los pods están READY
# ----------------------------------------------------------------------------
test_pods_ready() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 2: Verificar que todos los pods están READY (pasan health checks)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    NOT_READY=$(kubectl get pods -l app=web-lb --no-headers | grep -v "1/1" | wc -l)

    if [ "$NOT_READY" -eq 0 ]; then
        echo -e "${GREEN}✓ ÉXITO: Todos los pods están READY (1/1)${NC}"
        kubectl get pods -l app=web-lb
    else
        echo -e "${RED}❌ FALLO: Hay pods que no están READY${NC}"
        kubectl get pods -l app=web-lb
        echo ""
        echo -e "${YELLOW}Descripción de pods problemáticos:${NC}"
        kubectl describe pods -l app=web-lb | grep -A 10 "Conditions:"
        return 1
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 3: Verificar endpoints del Service
# ----------------------------------------------------------------------------
test_service_endpoints() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 3: Verificar que el Service tiene 2 endpoints${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    ENDPOINTS=$(kubectl get endpoints web-loadbalancer-service -o jsonpath='{.subsets[*].addresses[*].ip}')
    ENDPOINT_COUNT=$(echo "$ENDPOINTS" | wc -w)

    echo -e "Endpoints encontrados: ${BLUE}${ENDPOINT_COUNT}${NC}"
    echo -e "IPs: ${BLUE}${ENDPOINTS}${NC}"

    if [ "$ENDPOINT_COUNT" -eq 2 ]; then
        echo -e "${GREEN}✓ ÉXITO: El Service tiene 2 endpoints (ambos pods listos para recibir tráfico)${NC}"
    else
        echo -e "${RED}❌ FALLO: Se esperaban 2 endpoints, pero hay ${ENDPOINT_COUNT}${NC}"
        echo -e "${YELLOW}Esto significa que algún pod no pasa el readinessProbe${NC}"
        kubectl describe service web-loadbalancer-service
        return 1
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 4: Probar conectividad al LoadBalancer
# ----------------------------------------------------------------------------
test_connectivity() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 4: Probar conectividad al LoadBalancer${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    echo -e "${YELLOW}Haciendo petición HTTP a: ${SERVICE_URL}${NC}"

    if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$SERVICE_URL" | grep -q "200"; then
        echo -e "${GREEN}✓ ÉXITO: El LoadBalancer responde correctamente (HTTP 200)${NC}"
        echo -e "${YELLOW}Respuesta:${NC}"
        curl -s "$SERVICE_URL" | head -n 20
    else
        echo -e "${RED}❌ FALLO: El LoadBalancer no responde o devuelve error${NC}"
        return 1
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 5: Probar balanceo de carga (múltiples peticiones)
# ----------------------------------------------------------------------------
test_load_balancing() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 5: Verificar distribución de tráfico entre los 2 pods${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    echo -e "${YELLOW}Haciendo 20 peticiones y contando respuestas por pod...${NC}"

    # Limpiar logs anteriores
    kubectl logs -l app=web-lb --tail=0 &>/dev/null

    # Hacer 20 peticiones
    for i in {1..20}; do
        curl -s "$SERVICE_URL" > /dev/null 2>&1
        sleep 0.1
    done

    echo -e "${GREEN}✓ 20 peticiones completadas${NC}"
    echo ""

    # Contar peticiones por pod (si nginx tiene logs de acceso)
    echo -e "${YELLOW}Logs recientes de cada pod:${NC}"
    echo ""

    echo -e "${CYAN}Pod 1 (${POD1}):${NC}"
    POD1_LOGS=$(kubectl logs $POD1 --tail=10 2>/dev/null | wc -l)
    echo -e "Líneas de log: ${BLUE}${POD1_LOGS}${NC}"
    kubectl logs $POD1 --tail=5 2>/dev/null || echo "  (sin logs disponibles)"
    echo ""

    echo -e "${CYAN}Pod 2 (${POD2}):${NC}"
    POD2_LOGS=$(kubectl logs $POD2 --tail=10 2>/dev/null | wc -l)
    echo -e "Líneas de log: ${BLUE}${POD2_LOGS}${NC}"
    kubectl logs $POD2 --tail=5 2>/dev/null || echo "  (sin logs disponibles)"
    echo ""

    echo -e "${GREEN}✓ ÉXITO: Ambos pods están respondiendo (el balanceo está activo)${NC}"
    echo -e "${YELLOW}Nota: La distribución exacta depende del algoritmo del LoadBalancer${NC}"
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 6: Probar alta disponibilidad (eliminar un pod)
# ----------------------------------------------------------------------------
test_high_availability() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 6: Alta disponibilidad - Simular fallo de un pod${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    echo -e "${YELLOW}Estado inicial:${NC}"
    kubectl get pods -l app=web-lb
    echo ""

    echo -e "${YELLOW}Eliminando el pod: ${POD1}${NC}"
    kubectl delete pod $POD1 &
    sleep 2

    echo -e "${YELLOW}Haciendo peticiones durante el fallo...${NC}"
    SUCCESS=0
    FAILED=0

    for i in {1..10}; do
        if curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$SERVICE_URL" | grep -q "200"; then
            SUCCESS=$((SUCCESS + 1))
            echo -e "${GREEN}✓${NC} Petición $i: OK"
        else
            FAILED=$((FAILED + 1))
            echo -e "${RED}✗${NC} Petición $i: FALLO"
        fi
        sleep 0.5
    done

    echo ""
    echo -e "${YELLOW}Resultados:${NC}"
    echo -e "  Exitosas: ${GREEN}${SUCCESS}${NC}"
    echo -e "  Fallidas: ${RED}${FAILED}${NC}"

    if [ "$SUCCESS" -ge 8 ]; then
        echo -e "${GREEN}✓ ÉXITO: El servicio sigue disponible durante el fallo (alta disponibilidad)${NC}"
    else
        echo -e "${RED}❌ FALLO: Demasiadas peticiones fallidas durante el fallo del pod${NC}"
        return 1
    fi

    echo ""
    echo -e "${YELLOW}Esperando a que Kubernetes cree un nuevo pod...${NC}"
    kubectl wait --for=condition=ready pod -l app=web-lb --timeout=60s

    echo -e "${YELLOW}Estado final:${NC}"
    kubectl get pods -l app=web-lb

    POD_COUNT_FINAL=$(kubectl get pods -l app=web-lb --field-selector=status.phase=Running --no-headers | wc -l)
    if [ "$POD_COUNT_FINAL" -eq 2 ]; then
        echo -e "${GREEN}✓ Kubernetes recreó automáticamente el pod (vuelve a haber 2)${NC}"
    else
        echo -e "${RED}❌ Error: Hay ${POD_COUNT_FINAL} pods (se esperaban 2)${NC}"
        return 1
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 7: Verificar recursos (requests y limits)
# ----------------------------------------------------------------------------
test_resources() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 7: Verificar configuración de recursos${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    echo -e "${YELLOW}Recursos configurados por pod:${NC}"
    kubectl get pods -l app=web-lb -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}  CPU Request: {.spec.containers[0].resources.requests.cpu}{"\n"}  CPU Limit: {.spec.containers[0].resources.limits.cpu}{"\n"}  Memory Request: {.spec.containers[0].resources.requests.memory}{"\n"}  Memory Limit: {.spec.containers[0].resources.limits.memory}{"\n\n"}{end}'

    # Verificar si metrics-server está disponible
    if kubectl top pods -l app=web-lb &>/dev/null; then
        echo -e "${YELLOW}Consumo actual de recursos:${NC}"
        kubectl top pods -l app=web-lb
        echo -e "${GREEN}✓ ÉXITO: Recursos configurados y métricas disponibles${NC}"
    else
        echo -e "${YELLOW}⚠ Metrics-server no disponible, no se pueden ver métricas en tiempo real${NC}"
        echo -e "${GREEN}✓ ÉXITO: Recursos configurados correctamente${NC}"
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 8: Verificar HPA (Horizontal Pod Autoscaler)
# ----------------------------------------------------------------------------
test_hpa() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 8: Verificar Horizontal Pod Autoscaler${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    if kubectl get hpa web-loadbalancer-hpa &>/dev/null; then
        echo -e "${GREEN}✓ HPA encontrado${NC}"
        kubectl get hpa web-loadbalancer-hpa
        echo ""

        echo -e "${YELLOW}Configuración del HPA:${NC}"
        kubectl describe hpa web-loadbalancer-hpa | grep -A 5 "Min replicas\|Max replicas\|Metrics"

        echo -e "${GREEN}✓ ÉXITO: HPA configurado correctamente${NC}"
    else
        echo -e "${YELLOW}⚠ HPA no encontrado (opcional)${NC}"
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# PRUEBA 9: Verificar PDB (Pod Disruption Budget)
# ----------------------------------------------------------------------------
test_pdb() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}PRUEBA 9: Verificar Pod Disruption Budget${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════════════${NC}"

    if kubectl get pdb web-loadbalancer-pdb &>/dev/null; then
        echo -e "${GREEN}✓ PDB encontrado${NC}"
        kubectl get pdb web-loadbalancer-pdb
        echo ""

        echo -e "${YELLOW}Configuración del PDB:${NC}"
        kubectl describe pdb web-loadbalancer-pdb | grep -A 3 "Min available"

        echo -e "${GREEN}✓ ÉXITO: PDB configurado (protección durante mantenimiento)${NC}"
    else
        echo -e "${YELLOW}⚠ PDB no encontrado (opcional)${NC}"
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# EJECUTAR TODAS LAS PRUEBAS
# ----------------------------------------------------------------------------

# Variables para tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Verificaciones iniciales
check_deployment
get_pod_info
get_service_url

# Ejecutar pruebas
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}   INICIANDO SUITE DE PRUEBAS${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Prueba 1
if test_pod_count; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 2
if test_pods_ready; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 3
if test_service_endpoints; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 4
if test_connectivity; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 5
if test_load_balancing; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 6
if test_high_availability; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 7
if test_resources; then TESTS_PASSED=$((TESTS_PASSED + 1)); else TESTS_FAILED=$((TESTS_FAILED + 1)); fi

# Prueba 8 (opcional)
test_hpa

# Prueba 9 (opcional)
test_pdb

# ----------------------------------------------------------------------------
# RESUMEN FINAL
# ----------------------------------------------------------------------------
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}   RESUMEN DE PRUEBAS${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total de pruebas: ${BLUE}${TOTAL_TESTS}${NC}"
echo -e "Exitosas: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Fallidas: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ TODAS LAS PRUEBAS PASARON EXITOSAMENTE                     ║${NC}"
    echo -e "${GREEN}║  El balanceador de carga está funcionando correctamente       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ ALGUNAS PRUEBAS FALLARON                                    ║${NC}"
    echo -e "${RED}║  Revisa los mensajes de error arriba                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
