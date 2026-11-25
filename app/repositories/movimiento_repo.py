"""Movimientos y operaciones monetarias delegadas a MySQL."""
from typing import Any
from app.repositories.base import consultar, procedimiento, funcion
from app.utils.resultado import Resultado

OPERACIONES = {"depositar":"SP_DEPOSITAR","retirar":"SP_RETIRAR","transferir":"SP_TRANSFERIR"}


def listar(conexion: Any, identificador: int, limite: int) -> Resultado:
    funcion(conexion,"FN_SALDO_DISPONIBLE",[identificador])
    return Resultado(consultar(conexion,"SELECT ID_MOVIMIENTO,TIPO,MONTO,SALDO_POSTERIOR,FECHA,DESCRIPCION,ID_CUENTA_RELACIONADA FROM MOVIMIENTOS WHERE ID_CUENTA=:id ORDER BY FECHA DESC,ID_MOVIMIENTO DESC LIMIT :limite",{"id":identificador,"limite":limite}))


def operar(conexion: Any, operacion: str, datos: dict) -> Resultado:
    entradas = [datos["origen"],datos["destino"],datos["monto"]] if operacion == "transferir" else [datos["id_cuenta"],datos["monto"]]
    return procedimiento(conexion,OPERACIONES[operacion],entradas)
