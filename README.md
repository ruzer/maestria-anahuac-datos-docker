# 🎓 Entorno de Análisis de Datos - Maestría Anáhuac

## 📋 Descripción
Entorno completo de análisis de datos para las clases de **Bases de Datos e Inteligencia de Negocios** de la Maestría en Universidad Anáhuac.

## 🛠️ Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **MySQL 8.4** | 3306 | Base de datos principal |
| **Adminer** | 8080 | Administrador web de BD |
| **Metabase** | 3000 | Herramienta de Business Intelligence |
| **Apache Superset** | 8088 | Plataforma de visualización |
| **Streamlit** | 8501 | Explorador interactivo de datos |
| **Jupyter Notebook** | 8888 | Análisis de datos con Python |
| **MySQL Backup** | - | Respaldos automáticos |

## 🚀 Inicio Rápido

### Prerrequisitos
- Docker Desktop instalado
- 8GB RAM mínimo
- 10GB espacio libre

### Instalación
```bash
# 1. Clonar o descargar el proyecto
git clone [tu-repositorio]
cd Docker

# 2. Ejecutar script de configuración
chmod +x setup.sh
./setup.sh

# 3. Acceder a los servicios (URLs mostradas al final)
```

## 📁 Estructura del Proyecto
- `docker-compose.yml`: Orquestador de todos los servicios.
- `streamlit/`: Imagen y aplicación Streamlit conectada a MySQL y datasets locales.
- `config/`, `data/`, `logs/`: Directorios montados en contenedores para configuración, información y trazas.
- `notebooks/`: Espacio de trabajo compartido para Jupyter.
- `mysql/`: Inicialización y configuraciones personalizadas de la base de datos.
