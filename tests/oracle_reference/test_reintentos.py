"""Pruebas de transacciones reales del servicio con conexiones simuladas."""
from contextlib import contextmanager
from types import SimpleNamespace
from unittest.mock import Mock
import oracledb
import pytest
from app.db import pool
from app.services.transacciones import ejecutar
from app.utils.resultado import Resultado
from app.utils.errores import INCIERTA, CONEXION


def conexion_falsa(monkeypatch, error_adquirir=None):
    conexion = Mock()
    entradas = []
    @contextmanager
    def prestar():
        entradas.append(1)
        if error_adquirir:
            raise error_adquirir
        yield conexion
    monkeypatch.setattr(pool,'conexion',prestar)
    return conexion,entradas


def test_lectura_reintenta_una_vez(monkeypatch):
    conexion,entradas = conexion_falsa(monkeypatch)
    operacion = Mock(side_effect=[oracledb.OperationalError('DPY-4011'),Resultado({'saldo':12})])
    respuesta,http = ejecutar(operacion,['CUENTAS'],lectura=True)
    assert http == 200 and respuesta['datos']=={'saldo':12}
    assert operacion.call_count == len(entradas) == 2
    conexion.commit.assert_not_called()


def test_lectura_se_detiene_tras_segunda_caida(monkeypatch):
    _,entradas = conexion_falsa(monkeypatch)
    operacion = Mock(side_effect=oracledb.OperationalError('DPY-6005'))
    respuesta,http = ejecutar(operacion,[],lectura=True)
    assert http==503 and respuesta['mensaje']==CONEXION
    assert operacion.call_count==len(entradas)==2

@pytest.mark.parametrize('fase',['ejecucion','commit'])
def test_escritura_no_se_repite_y_es_incierta(monkeypatch,fase):
    conexion,entradas=conexion_falsa(monkeypatch)
    error=oracledb.OperationalError('DPY-4011')
    operacion=Mock(return_value=Resultado())
    if fase=='ejecucion': operacion.side_effect=error
    else: conexion.commit.side_effect=error
    respuesta,http=ejecutar(operacion,['SP_DEPOSITAR'])
    assert http==503 and respuesta['mensaje']==INCIERTA
    assert operacion.call_count==len(entradas)==1
    conexion.rollback.assert_called()


def test_caida_antes_de_escribir_no_inventa_confirmacion(monkeypatch):
    conexion,entradas=conexion_falsa(monkeypatch,oracledb.OperationalError('DPY-6005'))
    operacion=Mock()
    respuesta,http=ejecutar(operacion,[])
    assert http==503 and respuesta['mensaje']==CONEXION and len(entradas)==1
    operacion.assert_not_called()


def test_error_out_revierte_y_conserva_contexto(monkeypatch):
    conexion,_=conexion_falsa(monkeypatch)
    respuesta,http=ejecutar(lambda c:Resultado(None,'ERROR',-20001,'Saldo insuficiente para comisión.'),['SP_TRANSFERIR'])
    assert http==409 and respuesta['mensaje']=='Saldo insuficiente para comisión.'
    conexion.rollback.assert_called_once()
    conexion.commit.assert_not_called()


def test_laboratorio_siempre_rollback(monkeypatch):
    conexion,_=conexion_falsa(monkeypatch)
    assert ejecutar(lambda c:Resultado(),[],laboratorio=True)[1]==200
    conexion.rollback.assert_called_once()
    conexion.commit.assert_not_called()


def test_commit_solo_si_ok(monkeypatch):
    conexion,_=conexion_falsa(monkeypatch)
    assert ejecutar(lambda c:Resultado(),[])[1]==200
    conexion.commit.assert_called_once()


def test_error_no_recuperable_no_reintenta(monkeypatch):
    _,entradas=conexion_falsa(monkeypatch)
    operacion=Mock(side_effect=oracledb.DatabaseError(SimpleNamespace(code=2290,message='constraint (PRIVADO.CK_CUENTAS_SALDO)',full_code='')))
    assert ejecutar(operacion,[],lectura=True)[1]==400
    assert operacion.call_count==len(entradas)==1


@pytest.mark.parametrize('metodo,url,datos,modulo,nombre',[
    ('POST','/api/clientes',{'dni':'12345678','nombres':'Ana','apellidos':'Torres','email':'a@b.pe'},'cliente_repo','crear'),
    ('PUT','/api/clientes/1',{'nombres':'Ana','apellidos':'Torres','email':'a@b.pe'},'cliente_repo','editar'),
    ('POST','/api/cuentas',{'id_cliente':1,'tipo':'AHORROS'},'cuenta_repo','abrir'),
    ('POST','/api/cuentas/1/estado',{'estado':'BLOQUEADA'},'cuenta_repo','cambiar_estado'),
    ('POST','/api/depositar',{'id_cuenta':1,'monto':1},'movimiento_repo','operar'),
    ('POST','/api/retirar',{'id_cuenta':1,'monto':1},'movimiento_repo','operar'),
    ('POST','/api/transferir',{'origen':1,'destino':2,'monto':1},'movimiento_repo','operar'),
    ('POST','/api/intereses/aplicar',{},'reporte_repo','intereses'),
    ('POST','/api/categorias/actualizar',{},'reporte_repo','categorias'),
    ('POST','/api/laboratorio/no_data_found',{},'reporte_repo','laboratorio'),
])
def test_post_put_no_reintentan(cliente,monkeypatch,metodo,url,datos,modulo,nombre):
    from app import repositories
    import importlib
    repo=importlib.import_module('app.repositories.'+modulo)
    _,entradas=conexion_falsa(monkeypatch)
    llamada=Mock(side_effect=oracledb.OperationalError('DPY-4011'))
    monkeypatch.setattr(repo,nombre,llamada)
    r=cliente.open(url,method=metodo,json=datos)
    assert r.status_code==503 and r.json['mensaje']==INCIERTA
    assert llamada.call_count==len(entradas)==1

@pytest.mark.parametrize('metodo,url,datos,nombre',[
    ('GET','/api/salud',None,'salud'),
    ('POST','/api/simulador',{'saldo_inicial':1000,'tasa_anual':12,'meses':2,'aporte_mensual':100,'meta':2000},'simular'),
])
def test_salud_simulador_solo_un_reintento(cliente,monkeypatch,metodo,url,datos,nombre):
    from app.repositories import reporte_repo
    _,entradas=conexion_falsa(monkeypatch)
    llamada=Mock(side_effect=[oracledb.OperationalError('DPY-4011'),Resultado({'ok':True})])
    monkeypatch.setattr(reporte_repo,nombre,llamada)
    r=cliente.open(url,method=metodo,json=datos)
    assert r.status_code==200 and llamada.call_count==len(entradas)==2
