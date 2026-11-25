"""Contrato de MySQL, catálogo, validación y transacciones sin servidor."""
import json
import re
from pathlib import Path
from unittest.mock import MagicMock
import mysql.connector
import pytest
from app.repositories import base,categoria_repo
from app.services import banca_service,transacciones
from app.utils.codigo_plsql import indexar
from app.utils.errores import ErrorAplicacion,traducir
from app.utils.resultado import Resultado


def test_catalogo_real_y_paginas(cliente):
    indice=indexar();assert len(indice)==38
    catalogo=json.loads(Path('app/static/datos/objetos_oracle.json').read_text(encoding='utf-8'))
    assert set(catalogo)==set(indice)
    for nombre,item in indice.items():
        r=cliente.get('/api/codigo/'+nombre)
        assert r.status_code==200 and r.json['datos']['objeto']==nombre
        assert catalogo[nombre]['tipo']==item['tipo']
    assert cliente.get('/api/codigo/NO_EXISTE').status_code==404
    assert 'SP_ESTADO_CUENTA_MENSUAL' in indice and 'FN_ESTADO_CUENTA_MENSUAL' not in indice


@pytest.mark.parametrize('codigo,esperado',[(20001,409),(20002,404),(20003,409),(20004,400),(20005,400),(20006,404),(20007,400),(1062,409),(1452,400),(3819,400),(1213,409),(1205,409),(1045,503),(1049,503),(1146,503),(1305,503)])
def test_errores_mysql(codigo,esperado):
    http,numero,mensaje=traducir(mysql.connector.Error(msg='Fallo de prueba',errno=codigo))
    assert http==esperado and numero==-codigo


def test_caida_escritura_incierta():
    http,codigo,mensaje=traducir(mysql.connector.Error(msg='Lost connection',errno=2013),durante_escritura=True)
    assert http==503 and 'confirmar' in mensaje


def test_binds_y_limite_mysql():
    c=MagicMock();cur=c.cursor.return_value.__enter__.return_value;cur.description=[('ID',)];cur.fetchall.return_value=[(1,)]
    r=base.consultar(c,'SELECT ID FROM CLIENTES WHERE ID=:id FETCH FIRST :limite ROWS ONLY',{'id':1,'limite':20})
    assert r==[{'id':1}]
    sql,datos=cur.execute.call_args.args
    assert 'LIMIT %(limite)s' in sql and '%(id)s' in sql and datos=={'id':1,'limite':20}


def test_callproc_out_y_json():
    c=MagicMock();cur=c.cursor.return_value.__enter__.return_value;cur.callproc.return_value=(1,'{"nivel":"GOLD"}','OK',0,'Listo')
    r=base.procedimiento(c,'SP_RESUMEN_CLIENTE',[1],{'json':'json'})
    assert r.datos['json']['nivel']=='GOLD' and r.estado=='OK'
    with pytest.raises(ValueError):base.procedimiento(c,'TEXTO_LIBRE',[])


@pytest.mark.parametrize('datos',[{}, {'limite_gold':0,'limite_premium':50000,'version':1},{'limite_gold':5000,'limite_premium':5000,'version':1},{'limite_gold':'NaN','limite_premium':50000,'version':1},{'limite_gold':'1.001','limite_premium':50000,'version':1}])
def test_limites_invalidos_no_conectan(cliente,datos):
    r=cliente.put('/api/categorias/limites',json=datos)
    assert r.status_code==400


def test_version_obsoleta_no_escribe():
    c=MagicMock();cur=c.cursor.return_value.__enter__.return_value;cur.fetchone.return_value=(2,)
    with pytest.raises(ErrorAplicacion):categoria_repo.guardar(c,{'limite_gold':10000,'limite_premium':60000,'version':1})
    assert cur.execute.call_count==1 and 'FOR UPDATE' in cur.execute.call_args.args[0]


def test_transacciones_y_error_persistente(monkeypatch):
    from contextlib import contextmanager
    c=MagicMock();llamadas=[]
    @contextmanager
    def conexion(): yield c
    monkeypatch.setattr(transacciones.pool,'conexion',conexion)
    monkeypatch.setattr(transacciones,'registrar_error',lambda *a:llamadas.append(a))
    r,http=transacciones.ejecutar(lambda c:Resultado({},'ERROR',-20001,'Saldo insuficiente.'),['SP_RETIRAR'])
    assert http==409 and not r['ok'] and c.rollback.called and not c.commit.called and len(llamadas)==1


@pytest.mark.parametrize('lectura,intentos',[(True,2),(False,1)])
def test_solo_lecturas_reintentan(monkeypatch,lectura,intentos):
    from contextlib import contextmanager
    llamadas=[]
    @contextmanager
    def conexion():
        llamadas.append(1);raise mysql.connector.Error(msg='Lost',errno=2013);yield
    monkeypatch.setattr(transacciones.pool,'conexion',conexion)
    r,http=transacciones.ejecutar(lambda c:Resultado({}),[],lectura=lectura)
    assert http==503 and len(llamadas)==intentos


def test_sql_produccion_sin_plsql_ni_credenciales():
    for p in Path('sql/mysql').glob('*.sql'):
        s='\n'.join(l for l in p.read_text(encoding='utf-8').splitlines() if not l.lstrip().startswith('--'))
        assert 'RAISE_APPLICATION_ERROR' not in s and 'CREATE USER' not in s and 'DROP DATABASE' not in s
    for p in Path('app').rglob('*.py'):
        s=p.read_text(encoding='utf-8')
        assert 'import oracledb' not in s
    assert 'mysql.local.json' in Path('.gitignore').read_text(encoding='utf-8')


def test_importacion_rechaza_saldo_inconsistente():
    import sys
    sys.path.insert(0,str(Path('scripts').resolve()))
    from importar_oracle_mysql import validar_exportacion
    from datos_portables import COLUMNAS
    tablas={nombre:[] for nombre in COLUMNAS}
    tablas['TBL_CUENTAS']=[dict.fromkeys(COLUMNAS['TBL_CUENTAS'])]
    tablas['TBL_CUENTAS'][0].update(ID_CUENTA=1000,SALDO='10.00')
    with pytest.raises(ValueError,match='Saldo inconsistente'):
        validar_exportacion({'formato':'banco-oracle-mysql-v1','tablas':tablas})


def test_importacion_rechaza_tablas_ajenas():
    import sys
    sys.path.insert(0,str(Path('scripts').resolve()))
    from importar_oracle_mysql import validar_exportacion
    from datos_portables import COLUMNAS
    tablas={nombre:[] for nombre in COLUMNAS};tablas['AJENA']=[]
    with pytest.raises(ValueError,match='únicamente'):
        validar_exportacion({'formato':'banco-oracle-mysql-v1','tablas':tablas})
