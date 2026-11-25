"""Contrato de todos los endpoints de B3.5 con servicios simulados."""
from unittest.mock import Mock
import pytest
from app.services import banca_service as banca,reporte_service as reportes,simulador_service as simulador,laboratorio_service as lab
from app.utils.resultado import respuesta

CASOS = [
 ('GET','/api/salud',banca,'salud',None),('GET','/api/clientes',banca,'clientes',None),
 ('POST','/api/clientes',banca,'crear_cliente',{}),('PUT','/api/clientes/1',banca,'editar_cliente',{}),
 ('GET','/api/clientes/1/resumen',reportes,'resumen',None),('GET','/api/categoria?saldo=5000',banca,'categoria',None),
 ('GET','/api/cuentas',banca,'cuentas',None),('GET','/api/cuentas/opciones',banca,'opciones',None),
 ('POST','/api/cuentas',banca,'abrir_cuenta',{}),('POST','/api/cuentas/1/estado',banca,'estado',{}),
 ('GET','/api/cuentas/1/saldo',banca,'saldo',None),('GET','/api/cuentas/1/movimientos?limite=5',banca,'movimientos',None),
 ('GET','/api/cuentas/1/historial',banca,'historial',None),
 ('POST','/api/depositar',banca,'operar',{}),('POST','/api/retirar',banca,'operar',{}),('POST','/api/transferir',banca,'operar',{}),
 ('GET','/api/comision?monto=100&id_cuenta=1',banca,'comision',None),
 ('GET','/api/estado-cuenta/1?anio=2026&mes=11',reportes,'estado_cuenta',None),
 ('GET','/api/reporte/clientes?id_cliente=1&limite_movs=2',reportes,'clientes',None),
 ('POST','/api/intereses/aplicar',reportes,'intereses',{}),('POST','/api/categorias/actualizar',reportes,'categorias',None),
 ('POST','/api/simulador',simulador,'simular',{}),('GET','/api/auditoria',banca,'auditoria',None),('GET','/api/errores',banca,'errores',None),
] + [('POST','/api/laboratorio/'+caso,lab,'demostrar',None) for caso in sorted(lab.ESTANDAR|lab.PROPIOS.keys())]

@pytest.mark.parametrize('metodo,url,modulo,nombre,datos',CASOS)
def test_contrato(cliente,monkeypatch,metodo,url,modulo,nombre,datos):
    simulado=Mock(return_value=(respuesta({'valor':1},objetos=['SP_DEPOSITAR']),200))
    monkeypatch.setattr(modulo,nombre,simulado)
    r=cliente.open(url,method=metodo,json=datos)
    assert r.status_code==200
    assert set(r.json)=={'ok','mensaje','codigo','datos','objetos_oracle'}
    assert r.json['ok'] is True and isinstance(r.json['objetos_oracle'],list)
    simulado.assert_called_once()

@pytest.mark.parametrize('metodo,url,datos',[
 ('POST','/api/depositar',{'id_cuenta':1,'monto':'NaN'}),
 ('POST','/api/depositar',{'id_cuenta':1,'monto':-1}),
 ('POST','/api/transferir',{'origen':1,'destino':2,'monto':'0.001'}),
 ('POST','/api/clientes',{'dni':'1','nombres':'Ana','apellidos':'Torres','email':'a@b.pe'}),
 ('POST','/api/intereses/aplicar',{'mes_ref':'2026-13'}),
 ('POST','/api/simulador',{'saldo_inicial':100,'tasa_anual':3,'meses':601,'aporte_mensual':0,'meta':1000}),
 ('GET','/api/estado-cuenta/1?anio=2026&mes=13',None),
 ('GET','/api/reporte/clientes?limite_movs=1.5',None),
])
def test_validacion_sin_bd(cliente,metodo,url,datos):
    r=cliente.open(url,method=metodo,json=datos)
    assert r.status_code==400 and r.json['ok'] is False

@pytest.mark.parametrize('datos',[None,[],1,'texto'])
def test_cuerpo_json_objeto(cliente,datos):
    r=cliente.post('/api/clientes',json=datos)
    assert r.status_code==400 and r.json['ok'] is False


def test_rutas_y_metodos_desconocidos(cliente):
    for r,codigo in [(cliente.get('/api/inexistente'),404),(cliente.put('/api/depositar',json={}),405)]:
        assert r.status_code==codigo and set(r.json)=={'ok','mensaje','codigo','datos','objetos_oracle'}


def test_serializacion_decimal_y_fechas(app):
    from datetime import datetime
    from decimal import Decimal
    import json
    with app.app_context():
        datos=json.loads(app.json.dumps({'monto':Decimal('1.50'),'fecha':datetime(2026,11,24,9,0)}))
    assert datos=={'monto':1.5,'fecha':'2026-11-24T09:00:00'}


@pytest.mark.parametrize('query,esperado',[('',None),('?id_cliente=3',3)])
def test_filtro_cuentas_conserva_listado(cliente,monkeypatch,query,esperado):
    from contextlib import contextmanager
    from app.db import pool
    from app.repositories import cuenta_repo
    from app.utils.resultado import Resultado
    @contextmanager
    def prestar(): yield Mock()
    monkeypatch.setattr(pool,'conexion',prestar)
    llamada=Mock(return_value=Resultado([{'id_cuenta':1000,'id_cliente':3,'tipo':'AHORROS','saldo':100}]))
    monkeypatch.setattr(cuenta_repo,'listar',llamada)
    r=cliente.get('/api/cuentas'+query)
    assert r.status_code==200 and r.json['datos'][0]['id_cliente']==3
    assert llamada.call_args.args[1]==esperado
    assert r.json['objetos_oracle']==['V_CUENTAS_RESUMEN','CUENTAS']

@pytest.mark.parametrize('valor',['','-1','0','abc','1.5','1 OR 1=1','NaN','10000000000'])
def test_filtro_cuentas_invalido_no_consulta(cliente,monkeypatch,valor):
    from app.repositories import cuenta_repo
    llamada=Mock();monkeypatch.setattr(cuenta_repo,'listar',llamada)
    r=cliente.get('/api/cuentas',query_string={'id_cliente':valor})
    assert r.status_code==400 and not r.json['ok']
    llamada.assert_not_called()



def test_filtro_duplicado_no_elige_cliente_arbitrario(cliente):
    r=cliente.get('/api/cuentas?id_cliente=1&id_cliente=2')
    assert r.status_code==400 and 'un solo' in r.json['mensaje']
