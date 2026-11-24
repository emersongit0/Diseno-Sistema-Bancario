"""Validación del simulador de solo lectura."""
from decimal import Decimal
from app.repositories import reporte_repo
from app.services.transacciones import ejecutar
from app.utils import validacion as v


def simular(datos: dict) -> tuple[dict,int]:
    cuenta = datos.get("id_cuenta")
    cuenta = None if cuenta in (None,"") else v.entero(cuenta,"id_cuenta")
    parametros = dict(id_cuenta=cuenta,meses=v.entero(datos.get("meses"),"meses",0,600),
        aporte_mensual=v.importe(datos.get("aporte_mensual",0),"aporte_mensual",minimo=Decimal(0)),
        meta=v.importe(datos.get("meta"),"meta"),
        saldo_inicial=None if cuenta else v.importe(datos.get("saldo_inicial"),"saldo_inicial",minimo=Decimal(0)),
        tasa_anual=None if cuenta else v.importe(datos.get("tasa_anual"),"tasa_anual",minimo=Decimal(0),maximo=Decimal('999.99')))
    return ejecutar(lambda c:reporte_repo.simular(c,parametros),["BLOQUE_SIMULADOR_INTERES"],lectura=True)
