"""Preparación de parámetros para reportes y procesos masivos."""
from app.repositories import reporte_repo, cliente_repo
from app.services.transacciones import ejecutar
from app.utils import validacion as v


def resumen(identificador: int) -> tuple[dict,int]:
    return ejecutar(lambda c:cliente_repo.resumen(c,identificador),["BLOQUE_RESUMEN_CLIENTE"],lectura=True)


def estado_cuenta(identificador: int, anio: object, mes: object) -> tuple[dict,int]:
    anio,mes = v.entero(anio,"anio",1,9998),v.entero(mes,"mes",1,12)
    return ejecutar(lambda c:reporte_repo.estado_cuenta(c,identificador,anio,mes),["FN_ESTADO_CUENTA_MENSUAL","T_MOV_FILA","T_MOV_TABLA"],lectura=True)


def clientes(identificador: object, limite: object) -> tuple[dict,int]:
    identificador = None if identificador in (None,"") else v.entero(identificador,"id_cliente")
    limite = v.entero(limite,"limite_movs",0,1000)
    return ejecutar(lambda c:reporte_repo.clientes(c,identificador,limite),["SP_REPORTE_CLIENTES"],lectura=True)


def intereses(datos: dict) -> tuple[dict,int]:
    mes = v.mes_referencia(datos.get("mes_ref"))
    return ejecutar(lambda c:reporte_repo.intereses(c,mes),["SP_APLICAR_INTERESES","TRG_MOVIMIENTOS_BI","TRG_MOVIMIENTOS_AI"])


def categorias() -> tuple[dict,int]:
    return ejecutar(reporte_repo.categorias,["SP_ACTUALIZAR_CATEGORIAS","FN_CATEGORIA_CLIENTE","LIMITES_CATEGORIAS"])
