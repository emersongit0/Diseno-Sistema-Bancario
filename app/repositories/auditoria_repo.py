"""Lecturas del historial de auditoría y log mediante vistas de compatibilidad."""
from typing import Any
from app.repositories.base import consultar
from app.utils.resultado import Resultado
from app.utils.errores import mapear


def listar(conexion: Any) -> Resultado:
    return Resultado(consultar(conexion,"SELECT ID_AUDITORIA,TABLA,OPERACION,ID_REGISTRO,USUARIO_BD,FECHA,DETALLE FROM AUDITORIA ORDER BY FECHA DESC,ID_AUDITORIA DESC LIMIT 200"))


def errores(conexion: Any) -> Resultado:
    filas = consultar(conexion,"SELECT ID_LOG,PROCEDIMIENTO,CODIGO,MENSAJE,FECHA FROM LOG_ERRORES ORDER BY FECHA DESC,ID_LOG DESC LIMIT 200")
    for fila in filas:
        fila["mensaje"] = mapear(int(fila["codigo"]),fila["mensaje"])[1]
    return Resultado(filas)
