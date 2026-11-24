"""Reportes, intereses, categorías y simulación PL/SQL."""
from typing import Any
from app.utils.errores import ErrorAplicacion
from app.repositories.base import consultar, procedimiento, bloque
from app.utils.resultado import Resultado


def salud(conexion: Any) -> Resultado:
    consultar(conexion,"SELECT 1 AS ESTADO FROM dual")
    return Resultado({"conectada":True},mensaje="Base de datos conectada.")


def estado_cuenta(conexion: Any, identificador: int, anio: int, mes: int) -> Resultado:
    return Resultado(consultar(conexion,"SELECT * FROM TABLE(FN_ESTADO_CUENTA_MENSUAL(:id,:anio,:mes))",{"id":identificador,"anio":anio,"mes":mes}))


def clientes(conexion: Any, identificador: int | None, limite: int) -> Resultado:
    return procedimiento(conexion,"SP_REPORTE_CLIENTES",[identificador,limite],{"json":"json"})


def intereses(conexion: Any, mes) -> Resultado:
    return procedimiento(conexion,"SP_APLICAR_INTERESES",[mes],{"n_cuentas":"numero","n_omitidas":"numero"})


def categorias(conexion: Any) -> Resultado:
    with conexion.cursor() as cursor:
        cursor.execute("SELECT VERSION FROM LIMITES_CATEGORIAS WHERE ID_CONFIG=1 FOR UPDATE WAIT 5")
        if cursor.fetchone() is None:
            raise ErrorAplicacion("Falta instalar la configuración de categorías.",409)
    return procedimiento(conexion,"SP_ACTUALIZAR_CATEGORIAS",[],{"n_procesados":"numero","n_cambios":"numero"})


def simular(conexion: Any, datos: dict) -> Resultado:
    entradas = {"p_"+n:v for n,v in datos.items()}
    return bloque(conexion,"BLOQUE_SIMULADOR_INTERES",entradas,{"p_saldo_final":"numero","p_meses_meta":"numero","p_proyeccion":"json"})


def laboratorio(conexion: Any, caso: str) -> Resultado:
    return procedimiento(conexion,"SP_LAB_ERRORES",[caso],{"detalle":"texto"})
