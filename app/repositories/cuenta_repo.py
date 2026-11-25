"""Consultas de cuentas y llamadas a sus procedimientos."""
from typing import Any
from app.repositories.base import consultar, procedimiento, funcion
from app.utils.resultado import Resultado
from app.utils.errores import ErrorAplicacion


def listar(conexion: Any, id_cliente: int | None = None) -> Resultado:
    sql = "SELECT v.*,c.ID_CLIENTE,c.TIPO FROM V_CUENTAS_RESUMEN v JOIN CUENTAS c ON c.ID_CUENTA=v.ID_CUENTA"
    binds = {}
    if id_cliente is not None:
        sql += " WHERE c.ID_CLIENTE=:id_cliente"
        binds["id_cliente"] = id_cliente
    return Resultado(consultar(conexion,sql + " ORDER BY v.ID_CUENTA",binds))


def opciones(conexion: Any) -> Resultado:
    return Resultado(consultar(conexion,"SELECT ID_CUENTA,NRO_CUENTA,ESTADO,SALDO FROM CUENTAS ORDER BY ID_CUENTA"))


def abrir(conexion: Any, datos: dict) -> Resultado:
    return procedimiento(conexion,"SP_ABRIR_CUENTA",[datos["id_cliente"],datos["tipo"],datos["saldo_inicial"],datos["tasa"]],{"id_cuenta":"numero","nro_cuenta":"texto"})


def cambiar_estado(conexion: Any, identificador: int, estado: str) -> Resultado:
    return procedimiento(conexion,"SP_CAMBIAR_ESTADO_CUENTA",[identificador,estado])


def saldo(conexion: Any, identificador: int) -> Resultado:
    return Resultado({"saldo":funcion(conexion,"FN_SALDO_DISPONIBLE",[identificador])})


def historial(conexion: Any, identificador: int) -> Resultado:
    funcion(conexion,"FN_SALDO_DISPONIBLE",[identificador])
    return Resultado(consultar(conexion,"SELECT * FROM V_ESTADO_CUENTA WHERE ID_CUENTA=:id ORDER BY FECHA,ID_MOVIMIENTO",{"id":identificador}))


def comision(conexion: Any, monto, identificador: int) -> Resultado:
    filas = consultar(conexion,"SELECT cli.CATEGORIA FROM CUENTAS c JOIN CLIENTES cli ON cli.ID_CLIENTE=c.ID_CLIENTE WHERE c.ID_CUENTA=:id",{"id":identificador})
    if not filas:
        raise ErrorAplicacion("Cuenta inexistente",404,-20002)
    importe = funcion(conexion,"FN_COMISION",[monto,filas[0]["categoria"]])
    return Resultado({"comision":importe,"total_debitar":monto+importe})


def primera_activa(conexion: Any) -> int | None:
    filas = consultar(conexion,"SELECT ID_CUENTA FROM CUENTAS WHERE ESTADO='ACTIVA' ORDER BY ID_CUENTA LIMIT 1")
    return int(filas[0]["id_cuenta"]) if filas else None
