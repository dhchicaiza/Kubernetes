#!/bin/bash
# Script para desplegar la aplicación en Minikube

set -e

echo "🚀 Desplegando aplicación en Minikube..."
echo ""

# Verificar que Minikube esté corriendo
echo "✓ Verificando estado de Minikube..."
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Error: Minikube no está corriendo. Ejecuta 'minikube start' primero."
    exit 1
fi
echo "✓ Minikube está corriendo"
echo ""

# Configurar entorno Docker de Minikube (si no está configurado)
echo "🐳 Configurando Docker para usar el registro de Minikube..."
echo "   Ejecuta: eval \$(minikube docker-env)"
echo ""

# Construir imagen Docker
echo "🔨 Construyendo imagen Docker..."
docker build -t mi-app-web:v1 .
echo "✓ Imagen construida: mi-app-web:v1"
echo ""

# Aplicar configuraciones en orden
echo "📦 Desplegando recursos de Kubernetes..."
echo ""

echo "1️⃣  Aplicando configuración de base de datos (ConfigMap y Secret)..."
minikube kubectl -- apply -f db-config.yaml
echo ""

echo "2️⃣  Desplegando PostgreSQL..."
minikube kubectl -- apply -f db-deployment.yaml
echo ""

echo "⏳ Esperando a que PostgreSQL esté listo..."
minikube kubectl -- wait --for=condition=available --timeout=120s deployment/postgres-deployment
echo "✓ PostgreSQL está listo"
echo ""

echo "3️⃣  Desplegando aplicación Flask..."
minikube kubectl -- apply -f app-deployment.yaml
echo ""

echo "⏳ Esperando a que la aplicación esté lista..."
minikube kubectl -- wait --for=condition=available --timeout=120s deployment/app-web-deployment
echo "✓ Aplicación Flask está lista"
echo ""

# Obtener información de acceso
echo "🌐 Información de acceso:"
echo ""
echo "Para acceder a la aplicación, ejecuta:"
echo "  minikube service app-web-service"
echo ""
echo "O para obtener la URL:"
echo "  minikube service app-web-service --url"
echo ""

# Mostrar estado de los pods
echo "📊 Estado de los pods:"
minikube kubectl -- get pods
echo ""

echo "✅ Despliegue completado exitosamente!"
echo ""
echo "📝 Comandos útiles:"
echo "  Ver pods:        minikube kubectl -- get pods"
echo "  Ver servicios:   minikube kubectl -- get services"
echo "  Ver logs:        minikube kubectl -- logs <nombre-pod>"
echo "  Abrir dashboard: minikube dashboard"
