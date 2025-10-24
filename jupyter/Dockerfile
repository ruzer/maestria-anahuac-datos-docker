FROM jupyter/datascience-notebook:latest

USER root

# Instala librerías adicionales requeridas globalmente
RUN pip install --no-cache-dir panel hvplot

USER ${NB_UID}
