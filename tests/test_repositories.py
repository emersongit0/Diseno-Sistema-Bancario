"""Contrato de cursores, orden de OUT y binds reales sin abrir Oracle."""
from decimal import Decimal
from unittest.mock import Mock
from app.repositories import base,cliente_repo,cuenta_repo,reporte_repo
import oracledb

class Var:
    def __init__(self,tipo): self.tipo,self.valor=tipo,None
    def getvalue(self): return self.valor

class Lob:
    def __init__(self,valor,cursor): self.valor,self.cursor=valor,cursor
    def read(self):
        assert not self.cursor.cerrado
        return self.valor

class Cursor:
    def __init__(self): self.variables=[];self.cerrado=False;self.llamada=None
    def __enter__(self): return self
    def __exit__(self,*args): self.cerrado=True
    def var(self,tipo,**kwargs):
        var=Var(tipo);self.variables.append(var);return var
    def callproc(self,nombre,parametros):
        self.llamada=(nombre,parametros)
        self.variables[0].valor=Lob('[{"id_cliente":1}]',self)
        for var,valor in zip(self.variables[-3:],['OK',0,'Reporte generado.']): var.valor=valor
    def execute(self,codigo,binds):
        self.llamada=(codigo,binds)
        for n,v in binds.items():
            if not isinstance(v,Var): continue
            v.valor={'p_estado':'OK','p_codigo':0,'p_mensaje':'Simulación completada.',
                     'p_saldo_final':1221.1,'p_meses_meta':2}.get(n)
        if 'p_proyeccion' in binds:
            binds['p_proyeccion'].valor=Lob('[{"mes":0,"saldo":1000}]',self)


def test_callproc_orden_out_y_clob():
    cursor=Cursor();conexion=Mock();conexion.cursor.return_value=cursor
    r=base.procedimiento(conexion,'SP_REPORTE_CLIENTES',[1,5],{'json':'json'})
    assert cursor.llamada[0]=='SP_REPORTE_CLIENTES'
    assert cursor.llamada[1][:2]==[1,5]
    assert cursor.variables[0].tipo==oracledb.DB_TYPE_CLOB
    assert r.estado=='OK' and r.codigo==0 and r.datos=={'json':[{'id_cliente':1}]}
    assert cursor.cerrado


def test_simulador_binds_exactos_y_sin_separador(app):
    cursor=Cursor();conexion=Mock();conexion.cursor.return_value=cursor
    entradas=dict(id_cuenta=None,saldo_inicial=Decimal(1000),tasa_anual=Decimal(12),meses=2,aporte_mensual=Decimal(100),meta=Decimal(2000))
    with app.app_context(): r=reporte_repo.simular(conexion,entradas)
    codigo,binds=cursor.llamada
    assert codigo.rstrip().endswith('END;') and '-- @OBJETO' not in codigo
    assert set(binds)=={'p_'+n for n in entradas}|{'p_saldo_final','p_meses_meta','p_proyeccion','p_estado','p_codigo','p_mensaje'}
    assert binds['p_saldo_inicial']==Decimal(1000) and binds['p_id_cuenta'] is None
    assert r.datos['saldo_final']==1221.1 and r.datos['proyeccion']==[{'mes':0,'saldo':1000}]


def test_decimal_de_funcion_y_comision(monkeypatch):
    from unittest.mock import MagicMock
    conexion=MagicMock();conexion.cursor.return_value.__enter__.return_value.callfunc.return_value=1.5
    assert base.funcion(conexion,'FN_COMISION',[100,'BASICO'])==Decimal('1.5')
    monkeypatch.setattr(cuenta_repo,'consultar',lambda *args:[{'categoria':'BASICO'}])
    resultado=cuenta_repo.comision(conexion,Decimal(100),1)
    assert resultado.datos['total_debitar']==Decimal('101.5')


def test_insert_cliente_usa_binds_sin_concatenar():
    from unittest.mock import MagicMock
    conexion=MagicMock();cursor=conexion.cursor.return_value.__enter__.return_value
    cursor.var.return_value.getvalue.return_value=[1]
    datos={'dni':'12345678','nombres':"O'BRIEN",'apellidos':'Torres','email':'a@b.pe'}
    r=cliente_repo.crear(conexion,datos)
    sql,binds=cursor.execute.call_args.args
    assert "O'BRIEN" not in sql and binds['nombres']=="O'BRIEN" and r.datos['id_cliente']==1
