"""Configuración de Oracle compartida con la prueba manual de conexión."""

import os
from pathlib import Path

from dotenv import load_dotenv

RAIZ = Path(__file__).resolve().parent.parent


def parametros_conexion() -> dict[str, str]:
    """Carga el archivo elegido y devuelve parámetros sin registrarlos."""
    ruta = os.getenv("BANCO_ENV_FILE")
    load_dotenv(Path(ruta) if ruta else RAIZ / ".env", override=False)
    nombres = {"user": "DB_USER", "password": "DB_PASSWORD", "dsn": "DB_DSN"}
    parametros = {clave: os.getenv(nombre, "") for clave, nombre in nombres.items()}
    if any(not valor for valor in parametros.values()):
        raise ValueError("Completa DB_USER, DB_PASSWORD y DB_DSN en tu configuración local.")
    for clave, nombre in (("config_dir", "DB_WALLET_DIR"),
                          ("wallet_location", "DB_WALLET_DIR"),
                          ("wallet_password", "DB_WALLET_PASSWORD")):
        if valor := os.getenv(nombre):
            parametros[clave] = valor
    return parametros
