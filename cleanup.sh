#!/bin/bash
# Script para limpiar todos los recursos desplegados

set -e

echo "🧹 Limpiando recursos de Kubernetes..."
echo ""

# Eliminar deployments y services
echo "1️⃣  Eliminando aplicación Flask..."
minikube kubectl -- delete -f app-deployment.yaml --ignore-not-found=true

echo "2️⃣  Eliminando PostgreSQL..."
minikube kubectl -- delete -f db-deployment.yaml --ignore-not-found=true

echo "3️⃣  Eliminando configuraciones..."
minikube kubectl -- delete -f db-config.yaml --ignore-not-found=true

echo ""
echo "✅ Recursos eliminados"
echo ""
echo "📊 Estado actual:"
minikube kubectl -- get all
