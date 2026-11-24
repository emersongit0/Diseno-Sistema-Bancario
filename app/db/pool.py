"""Pool THIN perezoso, sin abrir conexiones al importar o crear la aplicación."""
from contextlib import contextmanager
from collections.abc import Iterator
from threading import Lock
import os
import oracledb
from flask import current_app
from app.config import parametros_conexion

_CERROJO = Lock()


def obtener_pool() -> oracledb.ConnectionPool:
    """Inicializa un pool por aplicación; las pruebas nunca cargan credenciales."""
    app = current_app._get_current_object()
    with _CERROJO:
        if "oracle_pool" not in app.extensions:
            parametros = parametros_conexion()
            minimo,maximo = int(os.getenv("POOL_MIN","1")),int(os.getenv("POOL_MAX","3"))
            if not 1 <= minimo <= maximo:
                raise ValueError("Configuración inválida del pool.")
            app.extensions["oracle_pool"] = oracledb.create_pool(
                **parametros,min=minimo,max=maximo,increment=1,ping_interval=60,
                getmode=oracledb.POOL_GETMODE_TIMEDWAIT,wait_timeout=15000,
                tcp_connect_timeout=15,retry_count=0)
    return app.extensions["oracle_pool"]


@contextmanager
def conexion() -> Iterator[oracledb.Connection]:
    """Presta una conexión y garantiza su devolución mediante context manager."""
    with obtener_pool().acquire() as prestada:
        prestada.call_timeout = 15000
        yield prestada
