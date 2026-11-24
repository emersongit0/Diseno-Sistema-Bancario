"""Bloqueo obligatorio de conexiones reales durante pytest."""

import oracledb
import pytest


@pytest.fixture(autouse=True)
def bloquear_base_de_datos(monkeypatch: pytest.MonkeyPatch) -> None:
    """Impide conexiones y pools reales incluso si un test olvida simularlos."""
    def denegar(*args: object, **kwargs: object) -> None:
        raise AssertionError("Las pruebas no pueden conectarse a Oracle.")

    for nombre in ("connect", "create_pool", "connect_async", "create_pool_async"):
        monkeypatch.setattr(oracledb, nombre, denegar)


@pytest.fixture
def app():
    from app import create_app
    return create_app({"TESTING":True})


@pytest.fixture
def cliente(app):
    return app.test_client()


@pytest.fixture(autouse=True)
def bloquear_archivo_env(monkeypatch):
    from app import config
    def prohibir(*args,**kwargs):
        raise AssertionError("Las pruebas no pueden leer el archivo de credenciales.")
    monkeypatch.setattr(config,"load_dotenv",prohibir)
