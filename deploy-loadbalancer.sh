#!/bin/bash
# ============================================================================
# SCRIPT DE DESPLIEGUE DEL BALANCEADOR DE CARGA
# ============================================================================
# Este script despliega y configura el balanceador de carga con 2 pods
# ============================================================================

set -e  # Salir si hay algún error

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}   DESPLIEGUE DE BALANCEADOR DE CARGA CON 2 PODS${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ----------------------------------------------------------------------------
# PASO 1: Verificar que Minikube está corriendo
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[1/8] Verificando Minikube...${NC}"
if ! minikube status &>/dev/null; then
    echo -e "${RED}❌ Minikube no está corriendo${NC}"
    echo -e "${YELLOW}Iniciando Minikube...${NC}"
    minikube start
else
    echo -e "${GREEN}✓ Minikube está corriendo${NC}"
fi
echo ""

# ----------------------------------------------------------------------------
# PASO 2: Verificar que metrics-server está habilitado (para HPA)
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[2/8] Verificando metrics-server (requerido para HPA)...${NC}"
if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
    echo -e "${YELLOW}⚠ Metrics-server no encontrado, habilitando...${NC}"
    minikube addons enable metrics-server
    echo -e "${YELLOW}Esperando a que metrics-server esté listo...${NC}"
    sleep 10
else
    echo -e "${GREEN}✓ Metrics-server está instalado${NC}"
fi
echo ""

# ----------------------------------------------------------------------------
# PASO 3: Eliminar despliegue anterior si existe
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[3/8] Limpiando despliegues anteriores...${NC}"
if kubectl get deployment web-loadbalancer-deployment &>/dev/null; then
    echo -e "${YELLOW}⚠ Eliminando deployment anterior...${NC}"
    kubectl delete -f loadbalancer-deployment.yaml --ignore-not-found=true
    echo -e "${YELLOW}Esperando a que los recursos se eliminen...${NC}"
    sleep 5
else
    echo -e "${GREEN}✓ No hay despliegues anteriores${NC}"
fi
echo ""

# ----------------------------------------------------------------------------
# PASO 4: Aplicar la configuración del balanceador de carga
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[4/8] Desplegando balanceador de carga...${NC}"
kubectl apply -f loadbalancer-deployment.yaml
echo -e "${GREEN}✓ Configuración aplicada${NC}"
echo ""

# ----------------------------------------------------------------------------
# PASO 5: Esperar a que el deployment esté listo
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[5/8] Esperando a que el deployment esté listo...${NC}"
kubectl rollout status deployment/web-loadbalancer-deployment --timeout=120s
echo -e "${GREEN}✓ Deployment listo${NC}"
echo ""

# ----------------------------------------------------------------------------
# PASO 6: Verificar que hay 2 pods corriendo
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[6/8] Verificando pods...${NC}"
POD_COUNT=$(kubectl get pods -l app=web-lb --field-selector=status.phase=Running --no-headers | wc -l)
echo -e "Pods corriendo: ${GREEN}${POD_COUNT}${NC}"

if [ "$POD_COUNT" -ne 2 ]; then
    echo -e "${RED}❌ Error: Se esperaban 2 pods, pero hay ${POD_COUNT}${NC}"
    echo -e "${YELLOW}Estado de los pods:${NC}"
    kubectl get pods -l app=web-lb
    exit 1
fi

echo -e "${GREEN}✓ 2 pods están corriendo correctamente${NC}"
kubectl get pods -l app=web-lb -o wide
echo ""

# ----------------------------------------------------------------------------
# PASO 7: Verificar distribución en nodos (anti-afinidad)
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[7/8] Verificando distribución en nodos...${NC}"
NODES=$(kubectl get pods -l app=web-lb -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort -u | wc -l)
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)

echo -e "Nodos disponibles en el cluster: ${BLUE}${TOTAL_NODES}${NC}"
echo -e "Nodos con pods del balanceador: ${BLUE}${NODES}${NC}"

if [ "$NODES" -eq 2 ] && [ "$TOTAL_NODES" -ge 2 ]; then
    echo -e "${GREEN}✓ Excelente: Los 2 pods están en nodos diferentes (alta disponibilidad)${NC}"
elif [ "$NODES" -eq 1 ] && [ "$TOTAL_NODES" -eq 1 ]; then
    echo -e "${YELLOW}⚠ Info: Ambos pods están en el mismo nodo (solo hay 1 nodo disponible)${NC}"
    echo -e "${YELLOW}  Esto es normal en Minikube. En producción, usa múltiples nodos.${NC}"
else
    echo -e "${YELLOW}⚠ Distribución de pods:${NC}"
    kubectl get pods -l app=web-lb -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName
fi
echo ""

# ----------------------------------------------------------------------------
# PASO 8: Verificar el Service LoadBalancer
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[8/8] Verificando LoadBalancer Service...${NC}"
kubectl get service web-loadbalancer-service

# Obtener la IP del LoadBalancer
echo ""
echo -e "${YELLOW}Esperando IP externa del LoadBalancer...${NC}"
echo -e "${YELLOW}(En Minikube necesitarás ejecutar 'minikube tunnel' en otra terminal)${NC}"

# Intentar obtener la IP
for i in {1..10}; do
    LB_IP=$(kubectl get service web-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$LB_IP" ]; then
        echo -e "${GREEN}✓ IP del LoadBalancer: ${LB_IP}${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${YELLOW}⚠ La IP externa está <pending>${NC}"
        echo -e "${YELLOW}  Para obtener acceso en Minikube, ejecuta en otra terminal:${NC}"
        echo -e "${BLUE}    minikube tunnel${NC}"
        echo -e "${YELLOW}  O usa:${NC}"
        echo -e "${BLUE}    minikube service web-loadbalancer-service${NC}"
        break
    fi
    sleep 2
done
echo ""

# ----------------------------------------------------------------------------
# RESUMEN FINAL
# ----------------------------------------------------------------------------
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}✓ DESPLIEGUE COMPLETADO EXITOSAMENTE${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

echo -e "${YELLOW}📊 RESUMEN:${NC}"
echo -e "  • Deployment:  web-loadbalancer-deployment"
echo -e "  • Service:     web-loadbalancer-service (tipo: LoadBalancer)"
echo -e "  • Réplicas:    2 pods"
echo -e "  • HPA:         Escalado automático 2-5 pods (CPU > 70%)"
echo -e "  • PDB:         Mínimo 1 pod disponible durante mantenimiento"
echo ""

echo -e "${YELLOW}🔍 COMANDOS ÚTILES:${NC}"
echo -e "  Ver pods:"
echo -e "    ${BLUE}kubectl get pods -l app=web-lb${NC}"
echo ""
echo -e "  Ver logs de todos los pods:"
echo -e "    ${BLUE}kubectl logs -l app=web-lb --follow --prefix${NC}"
echo ""
echo -e "  Ver estado del HPA:"
echo -e "    ${BLUE}kubectl get hpa web-loadbalancer-hpa${NC}"
echo ""
echo -e "  Ver métricas de los pods:"
echo -e "    ${BLUE}kubectl top pods -l app=web-lb${NC}"
echo ""
echo -e "  Acceder al servicio (Minikube):"
echo -e "    ${BLUE}minikube service web-loadbalancer-service${NC}"
echo ""
echo -e "  Ejecutar pruebas de balanceo:"
echo -e "    ${BLUE}./test-loadbalancer.sh${NC}"
echo ""

echo -e "${YELLOW}🚀 PRÓXIMOS PASOS:${NC}"
echo -e "  1. Ejecuta ${BLUE}minikube tunnel${NC} en otra terminal (para obtener IP externa)"
echo -e "  2. Ejecuta ${BLUE}./test-loadbalancer.sh${NC} para probar el balanceo de carga"
echo -e "  3. Revisa ${BLUE}LOADBALANCER.md${NC} para documentación detallada"
echo ""

echo -e "${GREEN}✨ ¡Balanceador de carga listo para usar!${NC}"
echo ""
