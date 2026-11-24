"""Diez rutas con contexto, agrupación y explicación técnica sin abrir Oracle."""
from html.parser import HTMLParser
from pathlib import Path
import pytest

class Componentes(HTMLParser):
    def __init__(self):
        super().__init__();self.ids=[];self.activos=[];self.modulos=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.append(a['id'])
        if a.get('aria-current')=='page':self.activos.append(a.get('href'))
        if tag=='script' and a.get('type')=='module':self.modulos.append(a['src'])

@pytest.mark.parametrize('ruta',['/','/clientes','/cuentas','/operaciones','/estado-cuenta','/reporte','/intereses','/simulador','/auditoria','/laboratorio'])
def test_paginas_con_navegacion_y_componentes(cliente,ruta):
    r=cliente.get(ruta);assert r.status_code==200
    html=r.data.decode();parser=Componentes();parser.feed(html)
    assert len(parser.ids)==len(set(parser.ids))
    assert parser.activos==[ruta] and len(parser.modulos)==1
    for grupo in ['Inicio','Atención y operaciones','Administración','Consultas y supervisión','Pruebas y demostración']:
        assert grupo in html
    for identificador in ['objetos-oracle','oracle-contexto','toggle-oracle','ver-codigo','modal-codigo','modal-revision']:
        assert identificador in parser.ids
    assert 'Panel interno de gestión bancaria' in html
    assert 'no una traza automática' in html
    assert cliente.get(parser.modulos[0]).status_code==200

@pytest.mark.parametrize('ruta',[
 '/cuentas?id_cliente=1','/cuentas?id_cliente=abc','/cuentas?id_cuenta=1000',
 '/operaciones?id_cuenta=1000&tipo=transferir','/operaciones?id_cuenta=0&tipo=incorrecto',
 '/estado-cuenta?id_cuenta=1000','/reporte?id_cliente=1',
])
def test_abrir_contexto_solo_renderiza_sin_operar(cliente,ruta):
    # Las fixtures prohíben Oracle y dotenv: abrir una URL solo entrega HTML.
    assert cliente.get(ruta).status_code==200
