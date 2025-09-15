#!/bin/bash

# ===========================================
# DESCARGA DE DATASETS DE PRUEBA
# Maestría en Datos - Universidad Anáhuac
# ===========================================

set -e

echo "📥 Descargando datasets de prueba..."

# Crear directorio temporal
mkdir -p temp_datasets
cd temp_datasets

# Descargar base de datos Employees
echo "🏢 Descargando MySQL Employees Database..."
wget -q https://github.com/datacharmer/test_db/archive/master.zip
unzip -q master.zip

# Copiar archivos necesarios
echo "📋 Copiando archivos de inicialización..."
cp test_db-master/*.dump ../mysql/init/
cp test_db-master/employees.sql ../mysql/init/03_employees.sql

# Limpiar archivos temporales
cd ..
rm -rf temp_datasets

echo "✅ Datasets descargados correctamente"
echo "📁 Archivos disponibles en mysql/init/"