"""Demostraciones controladas de excepciones; siempre revierten la transacción."""
from decimal import Decimal
import re
from app.repositories import reporte_repo, cuenta_repo, movimiento_repo
from app.services.transacciones import ejecutar
from app.utils.resultado import Resultado
from app.utils.errores import ErrorAplicacion, ocultar_esquema, mapear

ESTANDAR = {"no_data_found","too_many_rows","dup_val_on_index","zero_divide","value_error","when_others","reraise"}
PROPIOS = {"saldo_insuficiente":"SP_RETIRAR","cuenta_inexistente":"SP_DEPOSITAR",
    "cuenta_bloqueada":"SP_DEPOSITAR","monto_invalido":"SP_DEPOSITAR","misma_cuenta":"SP_TRANSFERIR",
    "cliente_inexistente":"SP_ABRIR_CUENTA","estado_invalido":"SP_CAMBIAR_ESTADO_CUENTA"}
ESPERADOS = dict(zip(PROPIOS,[-20001,-20002,-20003,-20004,-20005,-20006,-20007]))


def _demostrar(conexion, caso: str) -> Resultado:
    if caso in ESTANDAR:
        resultado = reporte_repo.laboratorio(conexion,caso)
        if resultado.estado != "OK":
            return resultado
        detalle = resultado.datos["detalle"]
        match = re.search(r"MYSQL_ERRNO=(-?\d+); MESSAGE_TEXT=(.*)",detalle,re.S)
        if not match:
            raise RuntimeError("Detalle de laboratorio inválido.")
        codigo,texto = int(match[1]),match[2]
    else:
        identificador = cuenta_repo.primera_activa(conexion)
        if identificador is None:
            raise ErrorAplicacion("Crea una cuenta primero",409,-20002)
        datos = {"id_cuenta":identificador,"monto":Decimal('999999999999.99')}
        if caso == "saldo_insuficiente":
            resultado = movimiento_repo.operar(conexion,"retirar",datos)
        elif caso in ("cuenta_inexistente","monto_invalido","cuenta_bloqueada"):
            if caso == "cuenta_bloqueada":
                bloqueo = cuenta_repo.cambiar_estado(conexion,identificador,"BLOQUEADA")
                if bloqueo.estado != "OK":
                    return bloqueo
            datos = dict(id_cuenta=-1 if caso == "cuenta_inexistente" else identificador,
                         monto=Decimal(-1) if caso == "monto_invalido" else Decimal(1))
            resultado = movimiento_repo.operar(conexion,"depositar",datos)
        elif caso == "misma_cuenta":
            resultado = movimiento_repo.operar(conexion,"transferir",dict(origen=identificador,destino=identificador,monto=Decimal(1)))
        elif caso == "cliente_inexistente":
            resultado = cuenta_repo.abrir(conexion,dict(id_cliente=-1,tipo="AHORROS",saldo_inicial=Decimal(0),tasa=None))
        else:
            resultado = cuenta_repo.cambiar_estado(conexion,identificador,"CERRADA")
        codigo,texto = resultado.codigo,resultado.mensaje
        if resultado.estado != "ERROR" or codigo != ESPERADOS[caso]:
            raise RuntimeError("No se capturó la excepción esperada.")
    http,_ = mapear(codigo,texto)
    return Resultado(dict(codigo=codigo,sqlerrm=ocultar_esquema(texto),http=http),mensaje="Excepción esperada capturada.")


def demostrar(caso: str) -> tuple[dict,int]:
    if caso not in ESTANDAR | PROPIOS.keys():
        raise ErrorAplicacion("Caso de laboratorio desconocido",404,404)
    objetos = ["SP_LAB_ERRORES","SP_LOG_ERROR"] if caso in ESTANDAR else [PROPIOS[caso],"CUENTAS","SP_LOG_ERROR"]
    if caso == "cuenta_bloqueada":
        objetos += ["SP_CAMBIAR_ESTADO_CUENTA","TRG_CUENTAS_AU"]
    return ejecutar(lambda c:_demostrar(c,caso),objetos,laboratorio=True)
