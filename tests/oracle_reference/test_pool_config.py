"""Pool y configuración probados con valores ficticios, sin leer .env."""
from unittest.mock import Mock
import pytest
from app import config
from app.db import pool

@pytest.mark.parametrize('wallet',[False,True])
def test_config_wallet_solo_si_definida(monkeypatch,wallet):
    cargador=Mock()
    monkeypatch.setattr(config,'load_dotenv',cargador)
    for nombre in ['DB_USER','DB_PASSWORD','DB_DSN','DB_WALLET_DIR','DB_WALLET_PASSWORD','BANCO_ENV_FILE']:
        monkeypatch.delenv(nombre,raising=False)
    for nombre,valor in {'DB_USER':'demo','DB_PASSWORD':'ficticia','DB_DSN':'example.invalid:1521/demo'}.items():
        monkeypatch.setenv(nombre,valor)
    if wallet:
        monkeypatch.setenv('DB_WALLET_DIR','C:/wallet-ficticio')
        monkeypatch.setenv('DB_WALLET_PASSWORD','ficticia-wallet')
        monkeypatch.setenv('BANCO_ENV_FILE','C:/config-ficticia.env')
    parametros=config.parametros_conexion()
    assert parametros['user']=='demo'
    assert ('wallet_location' in parametros)==wallet
    assert ('wallet_password' in parametros)==wallet
    if wallet:
        assert parametros['config_dir']==parametros['wallet_location']=='C:/wallet-ficticio'
        assert str(cargador.call_args.args[0]).replace('\\','/')=='C:/config-ficticia.env'
    assert cargador.call_args.kwargs=={'override':False}


def test_pool_perezoso_y_timeout(app,monkeypatch):
    from unittest.mock import MagicMock
    prestamo=MagicMock()
    creador=Mock(return_value=prestamo)
    monkeypatch.setattr(pool,'parametros_conexion',lambda:dict(user='demo',password='ficticia',dsn='example.invalid/demo'))
    monkeypatch.setattr(pool.oracledb,'create_pool',creador)
    monkeypatch.setenv('POOL_MIN','1');monkeypatch.setenv('POOL_MAX','3')
    assert 'oracle_pool' not in app.extensions
    with app.app_context():
        with pool.conexion() as conexion:
            assert conexion.call_timeout==15000
        with pool.conexion(): pass
    creador.assert_called_once()
    kwargs=creador.call_args.kwargs
    assert kwargs['min']==1 and kwargs['max']==3 and kwargs['ping_interval']==60
    assert kwargs['retry_count']==0 and kwargs['wait_timeout']==15000
    assert prestamo.acquire.call_count==2
