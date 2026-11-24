"""Endpoints JSON: validan el cuerpo y delegan en servicios."""
from flask import Blueprint, request, jsonify
from app.services import banca_service as banca, reporte_service as reportes, simulador_service, laboratorio_service
from app.utils.errores import ErrorAplicacion
from app.utils.resultado import respuesta

api = Blueprint("api",__name__,url_prefix="/api")


def cuerpo() -> dict:
    datos = request.get_json(silent=True)
    if not isinstance(datos,dict):
        raise ErrorAplicacion("Envía un objeto JSON válido.")
    return datos


def enviar(resultado: tuple[dict,int]) -> tuple:
    datos,http = resultado
    return jsonify(datos),http


@api.get('/salud')
def salud() -> tuple: return enviar(banca.salud())

@api.get('/clientes')
def clientes() -> tuple: return enviar(banca.clientes())

@api.post('/clientes')
def crear_cliente() -> tuple: return enviar(banca.crear_cliente(cuerpo()))

@api.put('/clientes/<int:identificador>')
def editar_cliente(identificador: int) -> tuple: return enviar(banca.editar_cliente(identificador,cuerpo()))

@api.get('/clientes/<int:identificador>/resumen')
def resumen(identificador: int) -> tuple: return enviar(reportes.resumen(identificador))

@api.get('/categoria')
def categoria() -> tuple: return enviar(banca.categoria(request.args.get('saldo')))

@api.get('/cuentas')
def cuentas() -> tuple:
    if len(request.args.getlist('id_cliente')) > 1:
        raise ErrorAplicacion('Envía un solo id_cliente.')
    return enviar(banca.cuentas(request.args.get('id_cliente')))

@api.get('/cuentas/opciones')
def opciones() -> tuple: return enviar(banca.opciones())

@api.post('/cuentas')
def abrir_cuenta() -> tuple: return enviar(banca.abrir_cuenta(cuerpo()))

@api.post('/cuentas/<int:identificador>/estado')
def estado(identificador: int) -> tuple: return enviar(banca.estado(identificador,cuerpo()))

@api.get('/cuentas/<int:identificador>/saldo')
def saldo(identificador: int) -> tuple: return enviar(banca.saldo(identificador))

@api.get('/cuentas/<int:identificador>/movimientos')
def movimientos(identificador: int) -> tuple: return enviar(banca.movimientos(identificador,request.args.get('limite',20)))

@api.get('/cuentas/<int:identificador>/historial')
def historial(identificador: int) -> tuple: return enviar(banca.historial(identificador))

@api.post('/depositar')
def depositar() -> tuple: return enviar(banca.operar('depositar',cuerpo()))

@api.post('/retirar')
def retirar() -> tuple: return enviar(banca.operar('retirar',cuerpo()))

@api.post('/transferir')
def transferir() -> tuple: return enviar(banca.operar('transferir',cuerpo()))

@api.get('/comision')
def comision() -> tuple: return enviar(banca.comision(request.args.get('monto'),request.args.get('id_cuenta')))

@api.get('/estado-cuenta/<int:identificador>')
def estado_cuenta(identificador: int) -> tuple: return enviar(reportes.estado_cuenta(identificador,request.args.get('anio'),request.args.get('mes')))

@api.get('/reporte/clientes')
def reporte_clientes() -> tuple: return enviar(reportes.clientes(request.args.get('id_cliente'),request.args.get('limite_movs',5)))

@api.post('/intereses/aplicar')
def intereses() -> tuple: return enviar(reportes.intereses(cuerpo()))

@api.post('/categorias/actualizar')
def categorias() -> tuple: return enviar(reportes.categorias())

@api.post('/simulador')
def simular() -> tuple: return enviar(simulador_service.simular(cuerpo()))

@api.get('/auditoria')
def auditoria() -> tuple: return enviar(banca.auditoria())

@api.get('/errores')
def errores() -> tuple: return enviar(banca.errores())

@api.post('/laboratorio/<caso>')
def laboratorio(caso: str) -> tuple: return enviar(laboratorio_service.demostrar(caso))


@api.get('/categorias/limites')
def limites_categorias() -> tuple: return enviar(banca.limites_categorias())


@api.put('/categorias/limites')
def editar_limites_categorias() -> tuple: return enviar(banca.limites_categorias(cuerpo()))
