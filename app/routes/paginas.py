"""Diez pantallas HTML; todas las operaciones se realizan mediante la API."""
from flask import Blueprint, render_template

paginas = Blueprint('paginas',__name__)
PANTALLAS = [
    ('dashboard','/','Resumen general','Situación del banco y acceso a las tareas frecuentes.','V_CUENTAS_RESUMEN'),
    ('clientes','/clientes','Clientes','Registra titulares y consulta su relación con el banco.','CLIENTES TRG_CLIENTES_BI BLOQUE_RESUMEN_CLIENTE'),
    ('cuentas','/cuentas','Cuentas','Consulta cuentas, revisa movimientos y atiende solicitudes.','V_CUENTAS_RESUMEN SP_ABRIR_CUENTA SQ_CUENTA SP_CAMBIAR_ESTADO_CUENTA V_ESTADO_CUENTA MOVIMIENTOS'),
    ('operaciones','/operaciones','Operaciones','Registra depósitos, retiros y transferencias entre cuentas.','SP_DEPOSITAR SP_RETIRAR SP_TRANSFERIR FN_COMISION FN_SALDO_DISPONIBLE TRG_MOVIMIENTOS_AI'),
    ('estado_cuenta','/estado-cuenta','Estado de cuenta','Consulta los movimientos y el saldo acumulado de una cuenta por mes.','FN_ESTADO_CUENTA_MENSUAL T_MOV_FILA T_MOV_TABLA'),
    ('reporte','/reporte','Reporte de clientes','Explora clientes, sus cuentas y sus últimos movimientos.','SP_REPORTE_CLIENTES'),
    ('intereses','/intereses','Intereses y categorías','Gestiona intereses por periodo y actualiza las categorías de clientes.','SP_APLICAR_INTERESES SP_ACTUALIZAR_CATEGORIAS FN_CATEGORIA_CLIENTE LIMITES_CATEGORIAS'),
    ('simulador','/simulador','Simulador de ahorro','Proyecta un ahorro sin modificar el dinero de la cuenta.','BLOQUE_SIMULADOR_INTERES'),
    ('auditoria','/auditoria','Auditoría y registro de errores','La trazabilidad de cada operación.','AUDITORIA LOG_ERRORES'),
    ('laboratorio','/laboratorio','Laboratorio de errores','Explora cómo responde Oracle.','SP_LAB_ERRORES SP_LOG_ERROR'),
]


GRUPOS = [
    ('Inicio',['dashboard']),
    ('Atención y operaciones',['clientes','cuentas','operaciones','simulador']),
    ('Administración',['intereses']),
    ('Consultas y supervisión',['estado_cuenta','reporte','auditoria']),
    ('Pruebas y demostración',['laboratorio']),
]


def mostrar(pagina: str) -> str:
    configuracion = next(p for p in PANTALLAS if p[0] == pagina)
    return render_template(pagina+'.html',pagina=pagina,titulo=configuracion[2],
        descripcion=configuracion[3],objetos_pagina=configuracion[4].split(),pantallas=PANTALLAS,grupos=GRUPOS,
        grupo=next(titulo for titulo,nombres in GRUPOS if pagina in nombres))


def registrar() -> None:
    for nombre,ruta,*_ in PANTALLAS:
        paginas.add_url_rule(ruta,endpoint=nombre,view_func=lambda pagina=nombre:mostrar(pagina))

registrar()
