"""Cobertura de cada fila de B3.4 y de ocultación de detalles técnicos."""
from types import SimpleNamespace
import oracledb
import pytest
from app.utils.errores import mapear, traducir, restriccion, ocultar_esquema, CONEXION, INCIERTA

@pytest.mark.parametrize('codigo,http,mensaje',[
    (-20001,409,'Saldo insuficiente'),(-20002,404,'Cuenta inexistente'),
    (-20003,409,'Cuenta bloqueada'),(-20004,400,'Monto inválido'),
    (-20005,400,'No se puede transferir a la misma cuenta'),(-20006,404,'Cliente inexistente'),
    (-20007,400,'Estado de cuenta inválido'),(-1,409,'Registro duplicado'),
    (-2291,400,'Referencia inexistente (cliente o cuenta no existe)'),(-2292,409,'Tiene registros relacionados'),
    (-2290,400,'Restricción violada'),(-1400,400,'Dato faltante o con formato o tamaño inválido'),
    (-1438,400,'Dato faltante o con formato o tamaño inválido'),(-12899,400,'Dato faltante o con formato o tamaño inválido'),
    (-1722,400,'Dato faltante o con formato o tamaño inválido'),
    (-60,409,'Conflicto de concurrencia, intenta de nuevo'),(-30006,409,'Cuenta ocupada por otra operación, intenta de nuevo'),
    (-99999,500,'Error interno'),
])
def test_tabla_y_excepcion_oracle(codigo,http,mensaje):
    assert mapear(codigo,'detalle privado') == (http,mensaje)
    error = oracledb.DatabaseError(SimpleNamespace(code=abs(codigo),message='detalle privado',full_code=''))
    assert traducir(error) == (http,codigo,mensaje)

@pytest.mark.parametrize('codigo,nombre,mensaje',[
    (-1,'UQ_CLIENTES_DNI','DNI ya registrado'),(-1,'UQ_CLIENTES_EMAIL','Email ya registrado'),
    (-1,'OTRA','Registro duplicado'),(-2290,'CK_CLIENTES_DNI','El DNI debe tener 8 dígitos'),
    (-2290,'CK_CUENTAS_SALDO','La operación dejaría saldo negativo'),
    (-2290,'CK_CUENTAS_TIPO','Tipo de cuenta inválido'),(-2290,'OTRA','Restricción violada'),
])
def test_restricciones(codigo,nombre,mensaje):
    texto = f'ORA: constraint (PRIVADO.{nombre}) violated'
    assert restriccion(texto) == nombre
    assert mapear(codigo,texto)[1] == mensaje

@pytest.mark.parametrize('identificador',['DPY-4011','DPY-6005','ORA-03113','ORA-03114'])
@pytest.mark.parametrize('escritura',[False,True])
def test_caidas(identificador,escritura):
    error = oracledb.OperationalError(identificador+': detalle privado')
    assert traducir(error,escritura)[::2] == (503,INCIERTA if escritura else CONEXION)


def test_mensaje_de_negocio_y_detalle_generico():
    assert mapear(-20001,'ORA-20001: Saldo insuficiente para monto más comisión.',negocio=True) == (409,'Saldo insuficiente para monto más comisión.')
    assert mapear(-2290,'detalle técnico',negocio=True) == (400,'Restricción violada')


def test_ocultar_detalles_extendidos():
    texto = 'ORA-00001: (PRIVADO.UQ_CLIENTES_DNI) on table PRIVADO.TBL_CLIENTES columns (DNI)'
    limpio = ocultar_esquema(texto)
    assert 'PRIVADO' not in limpio
    assert '(UQ_CLIENTES_DNI)' in limpio
