"""Impide referencias directas a tablas físicas desde Python, JS o HTML."""
from pathlib import Path


def test_sin_nombres_fisicos():
    raiz=Path(__file__).resolve().parents[1]
    patron='TB'+'L_'
    archivos=[p for p in (raiz/'app').rglob('*') if p.suffix in ('.py','.js','.html')]
    archivos += [raiz/'run.py',raiz/'probar_conexion.py']
    infractores=[str(p.relative_to(raiz)) for p in archivos if patron in p.read_text(encoding='utf-8')]
    assert not infractores,infractores
