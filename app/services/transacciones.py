"""Transacciones y reintentos centralizados, independientes de las rutas."""
import logging
from typing import Callable
from app.db import pool
from app.utils.errores import es_conexion, traducir, mapear, datos_error
from app.utils.resultado import Resultado, respuesta

logger = logging.getLogger(__name__)


def registrar_error(codigo: int,mensaje: str,objetos: list[str]) -> None:
    """MySQL no tiene transacciones autónomas: registrar después del rollback."""
    try:
        with pool.conexion() as c:
            with c.cursor() as cursor:
                cursor.callproc('SP_LOG_ERROR',[next((o for o in objetos if o.startswith('SP_')),'API'),codigo,mensaje[:4000]])
            c.commit()
    except Exception:
        logger.warning('No se pudo guardar el registro de error de MySQL.')


def ejecutar(operacion: Callable, objetos: list[str], *, lectura: bool = False,
             laboratorio: bool = False) -> tuple[dict,int]:
    """Reintenta una lectura una sola vez; nunca repite escrituras."""
    for intento in range(2 if lectura else 1):
        etapa = "conectar"
        try:
            with pool.conexion() as conexion:
                etapa = "ejecutar"
                try:
                    resultado: Resultado = operacion(conexion)
                    if resultado.estado != "OK":
                        conexion.rollback()
                        registrar_error(resultado.codigo,resultado.mensaje,objetos)
                        http,mensaje = mapear(resultado.codigo,resultado.mensaje,negocio=True)
                        return respuesta(None,mensaje,resultado.codigo,objetos,False),http
                    if lectura or laboratorio:
                        conexion.rollback()
                        if laboratorio and isinstance(resultado.datos,dict):
                            registrar_error(int(resultado.datos.get('codigo',0)),str(resultado.datos.get('sqlerrm','')),objetos)
                    else:
                        etapa = "commit"
                        conexion.commit()
                    return respuesta(resultado.datos,resultado.mensaje,0,objetos),200
                except Exception:
                    try:
                        conexion.rollback()
                    except Exception:
                        logger.warning("No se pudo completar rollback.")
                    raise
        except Exception as error:
            if lectura and intento == 0 and es_conexion(error):
                continue
            http,codigo,mensaje = traducir(error,durante_escritura=not lectura and etapa != "conectar")
            if not lectura and etapa != "conectar" and not es_conexion(error): registrar_error(codigo,mensaje,objetos)
            logger.error("Operación fallida: tipo=%s, código=%s, etapa=%s",type(error).__name__,datos_error(error)[0],etapa)
            return respuesta(None,mensaje,codigo,objetos,False),http
    raise RuntimeError("Flujo de reintento inválido.")
