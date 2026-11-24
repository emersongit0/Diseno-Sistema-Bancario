"""Prueba manual de lectura: ejecutar únicamente por indicación del usuario."""

import logging

import oracledb

from app.config import parametros_conexion

logger = logging.getLogger(__name__)


def main() -> int:
    """Muestra el usuario conectado sin exponer credenciales ni DSN."""
    try:
        parametros = parametros_conexion()
        with oracledb.connect(**parametros) as conexion:
            conexion.call_timeout = 15000
            with conexion.cursor() as cursor:
                cursor.execute("SELECT USER FROM dual")
                usuario = cursor.fetchone()[0]
        logger.info("Usuario conectado: %s", usuario)
        return 0
    except ValueError:
        logger.error("Completa DB_USER, DB_PASSWORD y DB_DSN en tu configuración local.")
    except oracledb.Error:
        logger.error("No se pudo conectar. Revisa el panel de FreeSQL, TCPS, wallet y red local. No compartas credenciales.")
    return 1


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    raise SystemExit(main())
