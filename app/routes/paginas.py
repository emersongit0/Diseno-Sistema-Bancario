"""Diez pantallas HTML; todas las operaciones se realizan mediante la API."""
from flask import Blueprint, render_template

paginas = Blueprint('paginas',__name__)
PANTALLAS = [
    ('dashboard','/','Resumen general','Tu banco, de un vistazo.','V_CUENTAS_RESUMEN'),
    ('clientes','/clientes','Clientes','Personas y relaciones que importan.','CLIENTES TRG_CLIENTES_BI BLOQUE_RESUMEN_CLIENTE'),
    ('cuentas','/cuentas','Cuentas','Cada cuenta, con su historia.','V_CUENTAS_RESUMEN SP_ABRIR_CUENTA SQ_CUENTA SP_CAMBIAR_ESTADO_CUENTA V_ESTADO_CUENTA MOVIMIENTOS'),
    ('operaciones','/operaciones','Operaciones','Mueve tu dinero con claridad.','SP_DEPOSITAR SP_RETIRAR SP_TRANSFERIR FN_COMISION FN_SALDO_DISPONIBLE TRG_MOVIMIENTOS_AI'),
    ('estado_cuenta','/estado-cuenta','Estado de cuenta','El detalle de cada movimiento.','FN_ESTADO_CUENTA_MENSUAL T_MOV_FILA T_MOV_TABLA'),
    ('reporte','/reporte','Reporte de clientes','Una vista completa, cliente por cliente.','SP_REPORTE_CLIENTES'),
    ('intereses','/intereses','Intereses y categorías','Haz crecer el valor de cada cuenta.','SP_APLICAR_INTERESES SP_ACTUALIZAR_CATEGORIAS FN_CATEGORIA_CLIENTE'),
    ('simulador','/simulador','Simulador','Proyecta tu próxima meta.','BLOQUE_SIMULADOR_INTERES'),
    ('auditoria','/auditoria','Auditoría y errores','La trazabilidad de cada operación.','AUDITORIA LOG_ERRORES'),
    ('laboratorio','/laboratorio','Laboratorio de errores','Explora cómo responde Oracle.','SP_LAB_ERRORES SP_LOG_ERROR'),
]


def mostrar(pagina: str) -> str:
    configuracion = next(p for p in PANTALLAS if p[0] == pagina)
    return render_template(pagina+'.html',pagina=pagina,titulo=configuracion[2],
        descripcion=configuracion[3],objetos_pagina=configuracion[4].split(),pantallas=PANTALLAS)


def registrar() -> None:
    for nombre,ruta,*_ in PANTALLAS:
        paginas.add_url_rule(ruta,endpoint=nombre,view_func=lambda pagina=nombre:mostrar(pagina))

registrar()
