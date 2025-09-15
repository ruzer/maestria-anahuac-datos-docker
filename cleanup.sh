#!/bin/bash

# ===========================================
# SCRIPT DE LIMPIEZA COMPLETA
# Maestría en Datos - Universidad Anáhuac
# ===========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

echo "🧹 Iniciando limpieza completa del entorno..."
print_warning "Esto eliminará TODOS los datos y contenedores"

read -p "¿Estás seguro? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operación cancelada"
    exit 1
fi

echo "\n🛑 Deteniendo servicios..."
docker compose down --volumes --remove-orphans

echo "\n🗑️  Eliminando datos locales..."
rm -rf data/mysql/*
rm -rf data/metabase/*
rm -rf data/superset/*
rm -rf logs/*
rm -rf backups/*

echo "\n🐳 Limpiando imágenes Docker no utilizadas..."
docker system prune -f

print_status "Limpieza completada"
echo "\n🚀 Ejecuta ./setup.sh para reinicializar el entorno"