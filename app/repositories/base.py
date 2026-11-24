"""Adaptadores de cursor; toda ejecución SQL queda en repositorios."""
import json
from decimal import Decimal
from typing import Any
import oracledb
from flask import current_app
from app.utils.resultado import Resultado
from app.utils.codigo_plsql import codigo_bloque


def leer_valor(valor: Any) -> Any:
    """Consume CLOB antes de devolver la conexión al pool."""
    return valor.read() if hasattr(valor,"read") else valor


def consultar(conexion: Any, sql: str, binds: dict | None = None) -> list[dict]:
    with conexion.cursor() as cursor:
        cursor.execute(sql,binds or {})
        nombres = [col[0].lower() for col in cursor.description]
        return [dict(zip(nombres,(leer_valor(x) for x in fila))) for fila in cursor.fetchall()]


def funcion(conexion: Any, nombre: str, entradas: list, texto: bool = False) -> Any:
    with conexion.cursor() as cursor:
        valor = cursor.callfunc(nombre,str if texto else oracledb.DB_TYPE_NUMBER,entradas)
        return valor if texto or valor is None else Decimal(str(valor))


def variable(cursor: Any, tipo: str) -> Any:
    if tipo == "texto":
        return cursor.var(str,size=4000)
    return cursor.var(oracledb.DB_TYPE_CLOB if tipo == "json" else oracledb.DB_TYPE_NUMBER)


def convertir(valor: Any, tipo: str) -> Any:
    valor = leer_valor(valor)
    return json.loads(valor,parse_float=Decimal) if tipo == "json" and valor is not None else valor


def procedimiento(conexion: Any,nombre: str,entradas: list,salidas: dict[str,str] | None = None) -> Resultado:
    """Conserva orden posicional IN, OUT propios y OUT estándar."""
    salidas = salidas or {}
    with conexion.cursor() as cursor:
        variables = {n:variable(cursor,t) for n,t in salidas.items()}
        estado,codigo,mensaje = cursor.var(str,size=10),cursor.var(oracledb.DB_TYPE_NUMBER),cursor.var(str,size=4000)
        cursor.callproc(nombre,entradas+list(variables.values())+[estado,codigo,mensaje])
        datos = {n:convertir(v.getvalue(),salidas[n]) for n,v in variables.items()}
        return Resultado(datos,estado.getvalue(),int(codigo.getvalue() or 0),mensaje.getvalue() or "")


def bloque(conexion: Any,nombre: str,entradas: dict,salidas: dict[str,str]) -> Resultado:
    with conexion.cursor() as cursor:
        variables = {n:variable(cursor,t) for n,t in salidas.items()}
        estado,codigo,mensaje = cursor.var(str,size=10),cursor.var(oracledb.DB_TYPE_NUMBER),cursor.var(str,size=4000)
        binds = entradas | variables | dict(p_estado=estado,p_codigo=codigo,p_mensaje=mensaje)
        cursor.execute(codigo_bloque(current_app.extensions["codigo_plsql"],nombre),binds)
        datos = {n.removeprefix("p_"):convertir(v.getvalue(),salidas[n]) for n,v in variables.items()}
        return Resultado(datos,estado.getvalue(),int(codigo.getvalue() or 0),mensaje.getvalue() or "")
