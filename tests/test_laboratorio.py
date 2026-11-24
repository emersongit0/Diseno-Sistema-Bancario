"""Casos reales del laboratorio con repositorios simulados y rollback obligatorio."""
from contextlib import contextmanager
from unittest.mock import Mock
import pytest
from app.db import pool
from app.services import laboratorio_service as lab
from app.repositories import reporte_repo,cuenta_repo,movimiento_repo
from app.utils.resultado import Resultado

@pytest.mark.parametrize('caso,codigo',list(lab.ESPERADOS.items()))
def test_casos_propios_revierte_errores_esperados(monkeypatch,caso,codigo):
    conexion=Mock()
    @contextmanager
    def prestar(): yield conexion
    monkeypatch.setattr(pool,'conexion',prestar)
    monkeypatch.setattr(cuenta_repo,'primera_activa',lambda c:123)
    error=Resultado(None,'ERROR',codigo,'ORA: (PRIVADO.RESTRICCION)')
    monkeypatch.setattr(movimiento_repo,'operar',lambda *args:error)
    monkeypatch.setattr(cuenta_repo,'abrir',lambda *args:error)
    monkeypatch.setattr(cuenta_repo,'cambiar_estado',lambda c,i,e:Resultado() if e=='BLOQUEADA' else error)
    r,http=lab.demostrar(caso)
    assert http==200 and r['ok'] and r['datos']['codigo']==codigo
    assert 'PRIVADO' not in r['datos']['sqlerrm']
    conexion.rollback.assert_called_once();conexion.commit.assert_not_called()


def test_laboratorio_sin_cuentas_y_caso_desconocido(cliente,monkeypatch):
    conexion=Mock()
    @contextmanager
    def prestar(): yield conexion
    monkeypatch.setattr(pool,'conexion',prestar)
    monkeypatch.setattr(cuenta_repo,'primera_activa',lambda c:None)
    r=cliente.post('/api/laboratorio/saldo_insuficiente')
    assert r.status_code==409 and r.json['mensaje']=='Crea una cuenta primero'
    assert cliente.post('/api/laboratorio/no_existe').status_code==404
    conexion.commit.assert_not_called()


def test_excepcion_estandar_con_detalle_extendido(monkeypatch):
    conexion=Mock()
    @contextmanager
    def prestar(): yield conexion
    monkeypatch.setattr(pool,'conexion',prestar)
    monkeypatch.setattr(reporte_repo,'laboratorio',lambda *args:Resultado({'detalle':'SQLCODE=-1; SQLERRM=ORA-00001: (PRIVADO.UQ_CLIENTES_DNI) table PRIVADO.TBL_CLIENTES'}))
    r,http=lab.demostrar('dup_val_on_index')
    assert http==200 and r['datos']['http']==409 and r['datos']['codigo']==-1
    assert 'PRIVADO' not in r['datos']['sqlerrm']
    conexion.rollback.assert_called_once()
