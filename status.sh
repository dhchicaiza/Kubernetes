#!/bin/bash
# Script para verificar el estado del cluster y las aplicaciones

echo "📊 Estado del Cluster Minikube"
echo "================================"
echo ""

# Estado de Minikube
echo "🖥️  Estado de Minikube:"
minikube status
echo ""

# Pods
echo "📦 Pods:"
minikube kubectl -- get pods -o wide
echo ""

# Deployments
echo "🚀 Deployments:"
minikube kubectl -- get deployments
echo ""

# Services
echo "🌐 Services:"
minikube kubectl -- get services
echo ""

# ConfigMaps y Secrets
echo "⚙️  ConfigMaps:"
minikube kubectl -- get configmaps
echo ""

echo "🔐 Secrets:"
minikube kubectl -- get secrets
echo ""

# URLs de acceso
echo "🔗 URLs de acceso:"
echo "--------------------------------"
minikube service list
echo ""

echo "💡 Para acceder a la aplicación web:"
echo "   minikube service app-web-service"
