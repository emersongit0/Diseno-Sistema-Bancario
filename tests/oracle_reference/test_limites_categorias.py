"""Edición de límites: validación, persistencia y concurrencia sin Oracle."""
from decimal import Decimal
from unittest.mock import MagicMock
import pytest
from app.repositories import categoria_repo
from app.services import banca_service
from app.utils.resultado import Resultado
from app.utils.errores import ErrorAplicacion


def test_leer_y_guardar_desde_api(cliente, monkeypatch):
    vigente = {'limite_gold': Decimal('5000'), 'limite_premium': Decimal('50000'), 'version': 1}
    llamadas = []
    def ejecutar(op, objetos, **opciones):
        return {'ok': True, 'datos': op(None).datos, 'mensaje': 'OK', 'codigo': 0, 'objetos_oracle': objetos}, 200
    monkeypatch.setattr(banca_service, 'ejecutar', ejecutar)
    monkeypatch.setattr(categoria_repo, 'leer', lambda c: Resultado(vigente))
    def guardar(c, datos):
        llamadas.append(datos)
        return Resultado(datos | {'version': 2})
    monkeypatch.setattr(categoria_repo, 'guardar', guardar)
    assert cliente.get('/api/categorias/limites').json['datos']['version'] == 1
    r = cliente.put('/api/categorias/limites', json={'limite_gold': '10000.25', 'limite_premium': '70000', 'version': 1})
    assert r.status_code == 200 and r.json['datos']['version'] == 2
    assert llamadas == [{'limite_gold': Decimal('10000.25'), 'limite_premium': Decimal('70000'), 'version': 1}]


@pytest.mark.parametrize('datos', [
    {}, {'limite_gold': 0, 'limite_premium': 50000, 'version': 1},
    {'limite_gold': 10000, 'limite_premium': 10000, 'version': 1},
    {'limite_gold': 10000, 'limite_premium': 9999, 'version': 1},
    {'limite_gold': 'NaN', 'limite_premium': 50000, 'version': 1},
    {'limite_gold': '5000.001', 'limite_premium': 50000, 'version': 1},
    {'limite_gold': 5000, 'limite_premium': 50000},
])
def test_invalido_no_inicia_transaccion(cliente, monkeypatch, datos):
    def prohibido(*a, **k): raise AssertionError('No debe abrir una transacción')
    monkeypatch.setattr(banca_service, 'ejecutar', prohibido)
    assert cliente.put('/api/categorias/limites', json=datos).status_code == 400


def test_version_ajena_no_sobrescribe():
    c = MagicMock(); cursor = c.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = (2,)
    with pytest.raises(ErrorAplicacion) as error:
        categoria_repo.guardar(c, {'limite_gold': 10000, 'limite_premium': 60000, 'version': 1})
    assert error.value.http == 409 and cursor.execute.call_count == 1
    assert 'FOR UPDATE WAIT 5' in cursor.execute.call_args.args[0]


def test_guardar_usa_binds_y_no_commit(monkeypatch):
    c = MagicMock(); cursor = c.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = (1,)
    monkeypatch.setattr(categoria_repo, 'leer', lambda c: Resultado({'version': 2}))
    datos = {'limite_gold': Decimal('10000'), 'limite_premium': Decimal('60000'), 'version': 1}
    r = categoria_repo.guardar(c, datos)
    sql, binds = cursor.execute.call_args.args
    assert ':limite_gold' in sql and binds == {n: datos[n] for n in ('limite_gold', 'limite_premium')}
    assert r.datos['version'] == 2
    c.commit.assert_not_called()


def test_interfaz_sin_revision_agregada(cliente):
    html = cliente.get('/intereses').text
    assert 'Editar límites' in html and 'Guardar límites' in html
    assert 'Recalcular' not in html and 'revision-categorias' not in html
    assert 'Actualizar categorías de clientes' in html


def test_actualizar_clientes_bloquea_configuracion(monkeypatch):
    from app.repositories import reporte_repo
    c = MagicMock(); cursor = c.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = (3,)
    llamadas = []
    def procedimiento(*args):
        assert cursor.execute.call_count == 1
        llamadas.append(args)
        return Resultado({'n_procesados': 6, 'n_cambios': 2})
    monkeypatch.setattr(reporte_repo, 'procedimiento', procedimiento)
    r = reporte_repo.categorias(c)
    assert 'FOR UPDATE WAIT 5' in cursor.execute.call_args.args[0]
    assert llamadas[0][1] == 'SP_ACTUALIZAR_CATEGORIAS' and r.datos['n_cambios'] == 2


def test_falta_configuracion_no_actualiza_clientes(monkeypatch):
    from app.repositories import reporte_repo
    c = MagicMock(); c.cursor.return_value.__enter__.return_value.fetchone.return_value = None
    p = MagicMock(); monkeypatch.setattr(reporte_repo, 'procedimiento', p)
    with pytest.raises(ErrorAplicacion): reporte_repo.categorias(c)
    p.assert_not_called()
