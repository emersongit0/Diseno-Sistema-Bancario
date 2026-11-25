"""Pruebas unitarias aisladas del servidor y de la configuración privada."""
import pytest
import mysql.connector

@pytest.fixture(autouse=True)
def bloquear_base(monkeypatch):
    def denegar(*a,**k): raise AssertionError('pytest no debe conectar a una base de datos')
    monkeypatch.setattr(mysql.connector,'connect',denegar)
    from app.db import pool
    monkeypatch.setattr(pool,'MySQLConnectionPool',denegar)
    from app import config
    monkeypatch.setattr(config,'parametros_conexion',denegar)
    monkeypatch.setattr(pool,'parametros_conexion',denegar)

@pytest.fixture
def app():
    from app import create_app
    return create_app({'TESTING':True})

@pytest.fixture
def cliente(app): return app.test_client()
