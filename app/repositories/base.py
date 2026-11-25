"""Adaptadores MySQL: binds, funciones y procedimientos con OUT."""
import json
import re
from decimal import Decimal
from typing import Any
from app.utils.resultado import Resultado


def sql_mysql(sql: str) -> str:
    sql=re.sub(r'FOR UPDATE WAIT 5', 'FOR UPDATE',sql,flags=re.I)
    sql=re.sub(r'FETCH FIRST (:[a-z_]+|[0-9]+) ROWS? ONLY',r'LIMIT \1',sql,flags=re.I)
    return re.sub(r':([a-zA-Z_][a-zA-Z_0-9]*)',r'%(\1)s',sql)


def consultar(conexion: Any,sql: str,binds: dict | None=None) -> list[dict]:
    with conexion.cursor() as cursor:
        cursor.execute(sql_mysql(sql),binds or {})
        nombres=[c[0].lower() for c in cursor.description]
        return [dict(zip(nombres,f)) for f in cursor.fetchall()]


def funcion(conexion: Any,nombre: str,entradas: list,texto: bool=False):
    if nombre not in {'FN_SALDO_DISPONIBLE','FN_COMISION','FN_CATEGORIA_CLIENTE'}: raise ValueError('Función no permitida.')
    with conexion.cursor() as cursor:
        cursor.execute('SELECT '+nombre+'('+','.join(['%s']*len(entradas))+')',entradas)
        valor=cursor.fetchone()[0]
        return valor if texto or valor is None else Decimal(str(valor))


def procedimiento(conexion: Any,nombre: str,entradas: list,salidas: dict | None=None) -> Resultado:
    permitidos={'SP_ABRIR_CUENTA','SP_DEPOSITAR','SP_RETIRAR','SP_TRANSFERIR','SP_CAMBIAR_ESTADO_CUENTA','SP_APLICAR_INTERESES','SP_ACTUALIZAR_CATEGORIAS','SP_REPORTE_CLIENTES','SP_LAB_ERRORES','SP_RESUMEN_CLIENTE','SP_SIMULADOR_INTERES','SP_ESTADO_CUENTA_MENSUAL'}
    if nombre not in permitidos: raise ValueError('Procedimiento no permitido.')
    salidas=salidas or {}
    with conexion.cursor() as cursor:
        valores=cursor.callproc(nombre,list(entradas)+[None]*len(salidas)+[None,None,None])
        datos={}
        for i,(n,tipo) in enumerate(salidas.items(),len(entradas)):
            valor=valores[i]
            if tipo=='json' and valor is not None: valor=json.loads(valor,parse_float=Decimal)
            datos[n]=valor
        return Resultado(datos,valores[-3],int(valores[-2] or 0),valores[-1] or '')
