#!/bin/bash

# ===========================================
# SCRIPT DE INICIALIZACIÓN
# Maestría en Datos - Universidad Anáhuac
# ===========================================

set -e  # Salir si hay errores

echo "🚀 Iniciando configuración del entorno de Maestría en Datos..."
echo "================================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verificar que Docker esté instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instala Docker Desktop."
    exit 1
fi

# Verificar que Docker Compose esté disponible
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose no está disponible. Actualiza Docker Desktop."
    exit 1
fi

print_status "Docker y Docker Compose están disponibles"

# Crear estructura de directorios
echo "\n📁 Creando estructura de directorios..."
directories=(
    "data/mysql"
    "data/metabase"
    "data/superset"
    "data/datasets"
    "logs/mysql"
    "logs/metabase"
    "logs/superset"
    "backups"
    "notebooks"
    "config/superset"
    "mysql/init"
    "mysql/conf.d"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Creado: $dir"
    else
        print_info "Ya existe: $dir"
    fi
done

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    print_warning "Archivo .env no encontrado. Creando desde plantilla..."
    cp ".env.example" ".env" 2>/dev/null || {
        print_error "No se encontró .env.example. Creando .env básico..."
        cat > .env << 'EOF'
# CONFIGURACIÓN BÁSICA - PERSONALIZA ESTAS VARIABLES
MYSQL_ROOT_PASSWORD=MaestriaAnah_R00t2024!
MYSQL_DATABASE=curso
MYSQL_USER=alumno
MYSQL_PASSWORD=MaestriaAnah_Us3r2024!
TZ=America/Mexico_City
SUPERSET_SECRET_KEY=R7mZkQ9hL2uW5pX0yT4aB8vN1jH6fC3eG9qK2sV7tM5rY8d
SUPERSET_ENV=development
SUPERSET_LOAD_EXAMPLES=yes
METABASE_JAVA_OPTS=-Xms512m -Xmx1g
METABASE_SITE_NAME=Maestría Anáhuac - Análisis de Datos
METABASE_SITE_LOCALE=es
BACKUP_CRON_TIME=0 2 * * *
BACKUP_MAX_BACKUPS=30
MYSQL_PORT=3306
ADMINER_PORT=8080
METABASE_PORT=3000
SUPERSET_PORT=8088
EOF
    }
    print_status "Archivo .env creado"
else
    print_status "Archivo .env ya existe"
fi

# Configurar permisos
echo "\n🔐 Configurando permisos..."
chmod 755 data/
chmod 755 logs/
chmod 755 backups/
chmod 755 notebooks/
print_status "Permisos configurados"

# Limpiar contenedores anteriores si existen
echo "\n🧹 Limpiando contenedores anteriores..."
docker compose down --remove-orphans 2>/dev/null || true
print_status "Limpieza completada"

# Descargar imágenes
echo "\n📥 Descargando imágenes de Docker..."
docker compose pull
print_status "Imágenes descargadas"

# Iniciar servicios
echo "\n🚀 Iniciando servicios..."
docker compose up -d

# Esperar a que MySQL esté listo
echo "\n⏳ Esperando a que MySQL esté listo..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker compose exec mysql mysqladmin ping -h localhost --silent; then
        print_status "MySQL está listo"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "MySQL no respondió después de $max_attempts intentos"
        exit 1
    fi
    
    echo "Intento $attempt/$max_attempts - Esperando MySQL..."
    sleep 5
    ((attempt++))
done

# Mostrar estado de servicios
echo "\n📊 Estado de servicios:"
docker compose ps

# Mostrar URLs de acceso
echo "\n🌐 URLs de acceso:"
echo "================================================"
print_info "Adminer (Gestión DB):    http://localhost:8080"
print_info "Metabase (BI):          http://localhost:3000"
print_info "Superset (BI):          http://localhost:8088"
print_info "Jupyter Notebook:       http://localhost:8888"
echo "================================================"

echo "\n✅ ¡Configuración completada exitosamente!"
echo "\n📖 Consulta el archivo README.md para más información"
echo "🔑 Consulta Accesos-template.txt para credenciales"

echo "\n🛠️  Comandos útiles:"
echo "  docker compose logs -f [servicio]  # Ver logs"
echo "  docker compose stop               # Detener servicios"
echo "  docker compose start              # Iniciar servicios"
echo "  docker compose down               # Detener y eliminar"
echo "  ./cleanup.sh                      # Limpiar todo"

# Descargar datasets si no existen
if [ ! -f "mysql/init/load_employees.dump" ]; then
    print_info "Descargando datasets de prueba..."
    chmod +x download-datasets.sh
    ./download-datasets.sh
else
    print_status "Datasets ya disponibles"
fi