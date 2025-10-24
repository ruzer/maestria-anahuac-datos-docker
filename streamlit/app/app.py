"""
Aplicación Streamlit para explorar datos de la Maestría en Datos Anáhuac.
Permite validar la conectividad con MySQL y visualizar datasets de ejemplo.
"""

from __future__ import annotations

import os
from pathlib import Path

import pandas as pd
import streamlit as st
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError


def _load_local_env() -> None:
    """Carga un archivo .env cercano si existe (útil fuera de Docker)."""
    candidate_paths = [
        Path(__file__).resolve().parent / ".env",
        Path(__file__).resolve().parent.parent / ".env",
        Path(__file__).resolve().parent.parent.parent / ".env",
    ]
    for dotenv_path in candidate_paths:
        if dotenv_path.exists():
            load_dotenv(dotenv_path, override=False)
            break


_load_local_env()

st.set_page_config(
    page_title="Explorador de Datos - Maestría Anáhuac",
    page_icon="📊",
    layout="wide",
)

st.title("📊 Explorador de Datos")
st.caption(
    "Integra MySQL, notebooks y herramientas BI en un panel rápido para demostraciones."
)


def get_db_credentials() -> dict[str, str]:
    """Obtiene credenciales de conexión desde variables de entorno."""
    return {
        "host": os.getenv("MYSQL_HOST", "mysql"),
        "port": os.getenv("MYSQL_PORT", "3306"),
        "database": os.getenv("MYSQL_DATABASE", "curso"),
        "user": os.getenv("MYSQL_USER", "alumno"),
        "password": os.getenv("MYSQL_PASSWORD", ""),
    }


def build_connection_url(creds: dict[str, str]) -> str:
    """Construye la URL de conexión compatible con SQLAlchemy."""
    return (
        f"mysql+pymysql://{creds['user']}:{creds['password']}"
        f"@{creds['host']}:{creds['port']}/{creds['database']}"
    )


@st.cache_resource(show_spinner=False)
def get_engine_cached(url: str) -> Engine:
    """Crea un engine reutilizable hacia MySQL."""
    return create_engine(url, pool_pre_ping=True, pool_recycle=3600)


def render_connection_status(engine: Engine) -> None:
    """Verifica la conectividad y muestra métricas rápidas."""
    try:
        with engine.connect() as connection:
            schema = connection.execute(text("SELECT DATABASE()")).scalar() or "N/D"
            version = connection.execute(text("SELECT VERSION()")).scalar() or "N/D"
            st.success("Conexión a MySQL establecida correctamente.")
            col_schema, col_version = st.columns(2)
            col_schema.metric("Base de datos activa", schema)
            col_version.metric("Versión de MySQL", version)
    except SQLAlchemyError as exc:
        st.error("No se pudo conectar a MySQL. Revisa credenciales y estado del servicio.")
        st.exception(exc)
        st.stop()


@st.cache_data(ttl=60)
def get_tables(engine: Engine) -> list[str]:
    """Lista tablas disponibles en la base de datos."""
    with engine.connect() as connection:
        result = connection.execute(text("SHOW TABLES"))
        return [row[0] for row in result.fetchall()]


@st.cache_data(ttl=60)
def fetch_preview(engine: Engine, table: str, limit: int) -> pd.DataFrame:
    """Obtiene una vista previa de una tabla."""
    query = text(f"SELECT * FROM `{table}` LIMIT :limit")
    with engine.connect() as connection:
        result = connection.execute(query, {"limit": limit})
        df = pd.DataFrame(result.fetchall(), columns=result.keys())
    return df


def list_datasets(dataset_path: Path) -> list[Path]:
    """Enumera datasets planos disponibles para referencia rápida."""
    if not dataset_path.exists():
        return []
    return sorted(
        [
            path
            for path in dataset_path.glob("**/*")
            if path.is_file() and path.suffix.lower() in {".csv", ".parquet"}
        ]
    )


def dataset_selector(dataset_path: Path) -> Path | None:
    """Renderiza el selector de datasets en la barra lateral."""
    st.subheader("📁 Datasets disponibles")
    datasets = list_datasets(dataset_path)
    if not datasets:
        st.info(
            "No se encontraron datasets en `data/datasets`.\n"
            "Copia archivos CSV o Parquet para habilitar esta sección."
        )
        return None

    return st.selectbox(
        "Selecciona un dataset",
        options=datasets,
        format_func=lambda path: path.relative_to(dataset_path.parent),
    )


def render_dataset_preview(dataset_path: Path | None) -> None:
    """Muestra una vista previa del dataset seleccionado."""
    st.subheader("📁 Vista rápida de datasets")
    if not dataset_path:
        st.info("Selecciona un dataset en la barra lateral para visualizarlo aquí.")
        return

    try:
        if dataset_path.suffix.lower() == ".csv":
            df = pd.read_csv(dataset_path)
        else:
            df = pd.read_parquet(dataset_path)
    except Exception as exc:  # pylint: disable=broad-except
        st.error(f"No se pudo cargar `{dataset_path.name}`.")
        st.exception(exc)
        return

    st.dataframe(df.head(100), use_container_width=True)
    st.caption(f"Mostrando los primeros 100 registros de `{dataset_path.name}`.")


def render_sql_playground(engine: Engine, tables: list[str]) -> None:
    """Area interactiva para ejecutar consultas rápidas."""
    st.subheader("🧪 Laboratorio SQL")
    st.write("Ejecuta consultas rápidas sobre MySQL (máximo 200 filas).")
    default_query = "SELECT * FROM `{table}` LIMIT 50" if tables else "SELECT 1"
    query = st.text_area(
        "Escribe tu consulta",
        value=default_query.format(table=tables[0]) if tables else default_query,
        height=160,
    )
    if st.button("Ejecutar consulta"):
        try:
            with engine.connect() as connection:
                result = connection.execute(text(query))
                df = pd.DataFrame(result.fetchall(), columns=result.keys())
            st.dataframe(df.head(200), use_container_width=True)
            st.success(f"Consulta ejecutada. Filas retornadas: {len(df)}")
        except SQLAlchemyError as exc:
            st.error("Ocurrió un error al ejecutar la consulta.")
            st.exception(exc)


def main() -> None:
    creds = get_db_credentials()
    connection_url = build_connection_url(creds)
    engine = get_engine_cached(connection_url)

    selected_dataset: Path | None = None
    with st.sidebar:
        st.header("⚙️ Configuración")
        st.write(
            f"**Host:** {creds['host']}  \n"
            f"**Base de datos:** {creds['database']}  \n"
            f"**Usuario:** {creds['user']}"
        )
        st.caption("Variables proporcionadas desde docker-compose/.env.")
        selected_dataset = dataset_selector(Path("/data/datasets"))

    render_connection_status(engine)

    tables = get_tables(engine)
    st.subheader("📚 Tablas disponibles")
    if tables:
        selected_table = st.selectbox("Selecciona una tabla para vista previa", tables)
        limit = st.slider("Límite de filas", min_value=10, max_value=500, value=100, step=10)
        preview = fetch_preview(engine, selected_table, limit)
        st.dataframe(preview, use_container_width=True)
        st.caption(f"Mostrando {len(preview)} filas de `{selected_table}`.")
    else:
        st.info(
            "No se detectaron tablas. Usa los notebooks o herramientas BI para cargar datos."
        )

    render_dataset_preview(selected_dataset)
    render_sql_playground(engine, tables)


if __name__ == "__main__":
    main()
