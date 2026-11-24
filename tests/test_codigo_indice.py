"""Cobertura del índice con la lista independiente B2.2."""
from app.utils.codigo_plsql import indexar,codigo_bloque
import pytest

ESPERADOS = set("""TBL_CLIENTES TBL_CUENTAS TBL_MOVIMIENTOS TBL_AUDITORIA TBL_LOG_ERRORES
SQ_CLIENTE SQ_CUENTA SQ_MOVIMIENTO SQ_AUDITORIA SQ_LOG T_MOV_FILA T_MOV_TABLA
V_ESTADO_CUENTA V_CUENTAS_RESUMEN FN_SALDO_DISPONIBLE FN_CATEGORIA_CLIENTE FN_COMISION FN_ESTADO_CUENTA_MENSUAL
SP_LOG_ERROR SP_ABRIR_CUENTA SP_DEPOSITAR SP_RETIRAR SP_TRANSFERIR SP_CAMBIAR_ESTADO_CUENTA
SP_APLICAR_INTERESES SP_ACTUALIZAR_CATEGORIAS SP_REPORTE_CLIENTES SP_LAB_ERRORES
TRG_CLIENTES_BI TRG_CUENTAS_BI TRG_MOVIMIENTOS_BI TRG_MOVIMIENTOS_AI TRG_CUENTAS_AU
CLIENTES CUENTAS MOVIMIENTOS AUDITORIA LOG_ERRORES BLOQUE_SIMULADOR_INTERES BLOQUE_RESUMEN_CLIENTE""".split())


def test_cuarenta_entradas(cliente):
    indice=indexar()
    assert len(indice)==40 and set(indice)==ESPERADOS
    for nombre in ESPERADOS:
        respuesta=cliente.get('/api/codigo/'+nombre)
        assert respuesta.status_code==200
        assert set(respuesta.json['datos'])=={'objeto','tipo','archivo','codigo'}
        assert respuesta.json['datos']['objeto']==nombre


def test_desconocido_y_ruta_ajena(cliente):
    assert cliente.get('/api/codigo/NO_EXISTE').status_code==404
    assert cliente.get('/api/codigo/..%2F.env').status_code==404


def test_solo_dos_bloques_y_sin_separador():
    indice=indexar()
    for nombre in ['BLOQUE_SIMULADOR_INTERES','BLOQUE_RESUMEN_CLIENTE']:
        codigo=codigo_bloque(indice,nombre)
        assert codigo.endswith('END;') and '-- @OBJETO' not in codigo
    with pytest.raises(ValueError): codigo_bloque(indice,'SP_TRANSFERIR')
