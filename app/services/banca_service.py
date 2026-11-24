"""Capa delgada para clientes, cuentas y operaciones."""
from decimal import Decimal
from app.repositories import cliente_repo, cuenta_repo, movimiento_repo, auditoria_repo, reporte_repo, categoria_repo
from app.services.transacciones import ejecutar
from app.utils import validacion as v
from app.utils.errores import ErrorAplicacion


def salud() -> tuple[dict,int]:
    return ejecutar(reporte_repo.salud,[],lectura=True)


def clientes() -> tuple[dict,int]:
    return ejecutar(cliente_repo.listar,["CLIENTES"],lectura=True)


def crear_cliente(datos: dict) -> tuple[dict,int]:
    datos = v.cliente(datos,crear=True)
    return ejecutar(lambda c:cliente_repo.crear(c,datos),["CLIENTES","TRG_CLIENTES_BI","SQ_CLIENTE"])


def editar_cliente(identificador: int, datos: dict) -> tuple[dict,int]:
    datos = v.cliente(datos)
    return ejecutar(lambda c:cliente_repo.editar(c,identificador,datos),["CLIENTES","TRG_CLIENTES_BI"])


def categoria(saldo: object) -> tuple[dict,int]:
    saldo = v.importe(saldo,"saldo",minimo=Decimal(0))
    return ejecutar(lambda c:cliente_repo.categoria(c,saldo),["FN_CATEGORIA_CLIENTE"],lectura=True)


def cuentas(id_cliente: object = None) -> tuple[dict,int]:
    identificador = None if id_cliente is None else v.entero(id_cliente,"id_cliente")
    return ejecutar(lambda c:cuenta_repo.listar(c,identificador),["V_CUENTAS_RESUMEN","CUENTAS"],lectura=True)


def opciones() -> tuple[dict,int]:
    return ejecutar(cuenta_repo.opciones,["CUENTAS"],lectura=True)


def abrir_cuenta(datos: dict) -> tuple[dict,int]:
    tipo = v.texto(datos,"tipo",9)
    if tipo not in ("AHORROS","CORRIENTE"):
        raise ErrorAplicacion("Tipo de cuenta inválido")
    parametros = dict(id_cliente=v.entero(datos.get("id_cliente"),"id_cliente"),tipo=tipo,
        saldo_inicial=v.importe(datos.get("saldo_inicial",0),"saldo_inicial",minimo=Decimal(0)),
        tasa=None if datos.get("tasa") is None else v.importe(datos["tasa"],"tasa",minimo=Decimal(0),maximo=Decimal('999.99')))
    return ejecutar(lambda c:cuenta_repo.abrir(c,parametros),["SP_ABRIR_CUENTA","TRG_CUENTAS_BI","SQ_CUENTA","TRG_MOVIMIENTOS_BI","TRG_MOVIMIENTOS_AI"])


def estado(identificador: int, datos: dict) -> tuple[dict,int]:
    nuevo = datos.get("nuevo_estado",datos.get("estado"))
    if nuevo not in ("ACTIVA","BLOQUEADA"):
        raise ErrorAplicacion("Estado de cuenta inválido",400,-20007)
    return ejecutar(lambda c:cuenta_repo.cambiar_estado(c,identificador,nuevo),["SP_CAMBIAR_ESTADO_CUENTA","TRG_CUENTAS_AU"])


def saldo(identificador: int) -> tuple[dict,int]:
    return ejecutar(lambda c:cuenta_repo.saldo(c,identificador),["FN_SALDO_DISPONIBLE"],lectura=True)


def movimientos(identificador: int, limite: object) -> tuple[dict,int]:
    limite = v.entero(limite,"limite",1,1000)
    return ejecutar(lambda c:movimiento_repo.listar(c,identificador,limite),["MOVIMIENTOS","FN_SALDO_DISPONIBLE"],lectura=True)


def historial(identificador: int) -> tuple[dict,int]:
    return ejecutar(lambda c:cuenta_repo.historial(c,identificador),["V_ESTADO_CUENTA","FN_SALDO_DISPONIBLE"],lectura=True)


def operar(operacion: str, datos: dict) -> tuple[dict,int]:
    parametros = {"monto":v.importe(datos.get("monto"),"monto")}
    nombres = ("origen","destino") if operacion == "transferir" else ("id_cuenta",)
    parametros.update({n:v.entero(datos.get(n),n) for n in nombres})
    objetos = [movimiento_repo.OPERACIONES[operacion],"TRG_MOVIMIENTOS_BI","TRG_MOVIMIENTOS_AI"]
    objetos += ["FN_COMISION","FN_SALDO_DISPONIBLE"] if operacion == "transferir" else (["FN_SALDO_DISPONIBLE"] if operacion == "retirar" else [])
    return ejecutar(lambda c:movimiento_repo.operar(c,operacion,parametros),objetos)


def comision(monto: object, identificador: object) -> tuple[dict,int]:
    monto,identificador = v.importe(monto,"monto"),v.entero(identificador,"id_cuenta")
    return ejecutar(lambda c:cuenta_repo.comision(c,monto,identificador),["FN_COMISION","CUENTAS","CLIENTES"],lectura=True)


def auditoria() -> tuple[dict,int]:
    return ejecutar(auditoria_repo.listar,["AUDITORIA"],lectura=True)


def errores() -> tuple[dict,int]:
    return ejecutar(auditoria_repo.errores,["LOG_ERRORES"],lectura=True)


def limites_categorias(datos: dict | None = None) -> tuple[dict,int]:
    if datos is None:
        return ejecutar(categoria_repo.leer,["LIMITES_CATEGORIAS"],lectura=True)
    parametros = {n:v.importe(datos.get(n),n) for n in ('limite_gold','limite_premium')}
    parametros['version'] = v.entero(datos.get('version'),'version',1,9999999998)
    if parametros['limite_premium'] <= parametros['limite_gold']:
        raise ErrorAplicacion("El límite de Premium debe ser mayor que el de Gold.")
    return ejecutar(lambda c:categoria_repo.guardar(c,parametros),["LIMITES_CATEGORIAS"])
