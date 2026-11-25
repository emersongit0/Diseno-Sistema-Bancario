"""Prueba real reproducible en una base MySQL temporal propia, sin Oracle."""
import json
import sys
import uuid
from datetime import datetime
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo
RAIZ=Path(__file__).resolve().parents[1];sys.path.insert(0,str(RAIZ));sys.path.insert(0,str(RAIZ/'scripts'))
from app import create_app
from app.config import parametros_conexion
from instalar_mysql import instalar,conectar
from importar_oracle_mysql import importar,COLUMNAS


def verificar():
 cfg=parametros_conexion();cfg['database']='banco_qa_mysql_'+uuid.uuid4().hex[:10]
 instalar(demo=True,parametros=cfg)
 app=create_app({'TESTING':True,'MYSQL_CONFIG':cfg})
 def pedir(cliente,metodo,ruta,datos=None,estado=200):
  r=cliente.open(ruta,method=metodo,json=datos)
  assert r.status_code==estado,(metodo,ruta,r.status_code,r.json)
  assert set(r.json)=={'ok','mensaje','codigo','datos','objetos_oracle'},ruta
  return r.json
 def filas(sql,args=()):
  with conectar(cfg) as c:
   with c.cursor() as cur: cur.execute(sql,args);return cur.fetchall()
 def saldo(i):return filas('SELECT SALDO FROM CUENTAS WHERE ID_CUENTA=%s',(i,))[0][0]
 try:
  with app.test_client() as c:
   for ruta in ['/','/clientes','/cuentas','/operaciones','/estado-cuenta','/reporte','/intereses','/simulador','/auditoria','/laboratorio']:assert c.get(ruta).status_code==200
   pedir(c,'GET','/api/salud');assert len(pedir(c,'GET','/api/clientes')['datos'])==6
   assert len(pedir(c,'GET','/api/cuentas')['datos'])==8
   assert len(pedir(c,'GET','/api/cuentas?id_cliente=1')['datos'])==2
   resumen=pedir(c,'GET','/api/clientes/1/resumen')['datos']['json'];assert resumen['saldo_total']==4198.5
   pedir(c,'PUT','/api/clientes/1',{'nombres':'Ana','apellidos':'Torres','email':'demo1@banco.example'})
   pedir(c,'POST','/api/clientes',{'dni':'71000001','nombres':'Duplicado','apellidos':'QA','email':'otro@example.test'},409)
   nuevo=pedir(c,'POST','/api/clientes',{'dni':'99000001','nombres':'prueba','apellidos':'mysql','email':'mysql.qa@example.test'})['datos']['id_cliente']
   cuenta=pedir(c,'POST','/api/cuentas',{'id_cliente':nuevo,'tipo':'AHORROS','saldo_inicial':0})['datos']['id_cuenta']
   assert saldo(cuenta)==0
   antes=saldo(1000);pedir(c,'POST','/api/depositar',{'id_cuenta':1000,'monto':50});pedir(c,'POST','/api/retirar',{'id_cuenta':1000,'monto':10});assert saldo(1000)==antes+40
   comision=pedir(c,'GET','/api/comision?id_cuenta=1000&monto=100')['datos'];assert comision['comision']==1.5
   antes=saldo(1000);destino=saldo(1010);n=filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0];a=filas('SELECT COUNT(*) FROM AUDITORIA')[0][0]
   pedir(c,'POST','/api/transferir',{'origen':1000,'destino':1010,'monto':100})
   assert saldo(1000)==antes-Decimal('101.50') and saldo(1010)==destino+100
   assert filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]==n+3 and filas('SELECT COUNT(*) FROM AUDITORIA')[0][0]==a+3
   antes=saldo(1000);n=filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]
   pedir(c,'POST','/api/transferir',{'origen':1000,'destino':1010,'monto':999999999},409)
   assert saldo(1000)==antes and filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]==n
   # Fallo después del envío y la comisión: no debe quedar ningún movimiento parcial.
   antes=saldo(1000);destino=saldo(1010);n=filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0];a=filas('SELECT COUNT(*) FROM AUDITORIA')[0][0]
   with conectar(cfg) as ddl:
    with ddl.cursor() as cur:cur.execute("CREATE TRIGGER QA_FALLAR_RECIBIDA BEFORE INSERT ON TBL_MOVIMIENTOS FOR EACH ROW FOLLOWS TRG_MOVIMIENTOS_BI BEGIN IF NEW.TIPO='TRANSF_RECIBIDA' THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Fallo inyectado en la tercera inserción'; END IF; END")
   pedir(c,'POST','/api/transferir',{'origen':1000,'destino':1010,'monto':10},400)
   assert saldo(1000)==antes and saldo(1010)==destino and filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]==n and filas('SELECT COUNT(*) FROM AUDITORIA')[0][0]==a
   with conectar(cfg) as ddl:
    with ddl.cursor() as cur:cur.execute('DROP TRIGGER QA_FALLAR_RECIBIDA')
   # Espera de bloqueo acotada con dos conexiones reales.
   with conectar(cfg) as primera,conectar(cfg) as segunda:
    primera.start_transaction()
    with primera.cursor() as cur:cur.execute('SELECT ID_CUENTA FROM CUENTAS WHERE ID_CUENTA=1000 FOR UPDATE');cur.fetchone()
    with segunda.cursor() as cur:
     cur.execute('SET SESSION innodb_lock_wait_timeout=1');segunda.start_transaction()
     r=cur.callproc('SP_DEPOSITAR',[1000,1,None,None,None]);assert r[-3]=='ERROR' and r[-2]==-30006
    primera.rollback();segunda.rollback()
   # Un CALL directo con instantánea antigua también respeta un bloqueo reciente.
   with conectar(cfg) as primera,conectar(cfg) as segunda:
    segunda.start_transaction()
    with segunda.cursor() as cur:cur.execute('SELECT COUNT(*) FROM CUENTAS');cur.fetchone()
    primera.start_transaction()
    with primera.cursor() as cur:cur.execute("UPDATE CUENTAS SET ESTADO='BLOQUEADA' WHERE ID_CUENTA=1010")
    primera.commit()
    with segunda.cursor() as cur:
     r=cur.callproc('SP_TRANSFERIR',[1000,1010,10,None,None,None]);assert r[-3]=='ERROR' and r[-2]==-20003
    segunda.rollback()
    primera.start_transaction()
    with primera.cursor() as cur:cur.execute("UPDATE CUENTAS SET ESTADO='ACTIVA' WHERE ID_CUENTA=1010")
    primera.commit()
   pedir(c,'POST','/api/cuentas/1010/estado',{'nuevo_estado':'BLOQUEADA'})
   pedir(c,'POST','/api/depositar',{'id_cuenta':1010,'monto':1},409)
   pedir(c,'POST','/api/cuentas/1010/estado',{'nuevo_estado':'ACTIVA'})
   limites=pedir(c,'GET','/api/categorias/limites')['datos']
   pedir(c,'PUT','/api/categorias/limites',{'limite_gold':1000,'limite_premium':100000,'version':limites['version']})
   pedir(c,'PUT','/api/categorias/limites',{'limite_gold':2000,'limite_premium':100000,'version':limites['version']},409)
   assert pedir(c,'GET','/api/categoria?saldo=1000')['datos']['categoria']=='GOLD'
   pedir(c,'POST','/api/categorias/actualizar',{})
   assert pedir(c,'GET','/api/clientes/1/resumen')['datos']['json']['categoria_registrada']=='GOLD'
   mes=datetime.now(ZoneInfo('America/Lima')).strftime('%Y-%m')
   primer=pedir(c,'POST','/api/intereses/aplicar',{'mes_ref':mes})['datos'];assert primer['n_cuentas']==8
   n=filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]
   segundo=pedir(c,'POST','/api/intereses/aplicar',{'mes_ref':mes})['datos'];assert segundo['n_cuentas']==0 and filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]==n
   anio,m=mes.split('-');mensual=pedir(c,'GET',f'/api/estado-cuenta/1000?anio={anio}&mes={m}')['datos'];assert mensual and Decimal(str(mensual[-1]['saldo_acumulado']))==saldo(1000)
   reporte=pedir(c,'GET','/api/reporte/clientes?id_cliente=1&limite_movs=2')['datos']['json'];assert isinstance(reporte[0]['cuentas'],list) and all(len(x['movimientos'])<=2 for x in reporte[0]['cuentas'])
   assert all(x['movimientos']==[] for x in pedir(c,'GET','/api/reporte/clientes?id_cliente=1&limite_movs=0')['datos']['json'][0]['cuentas'])
   sim=pedir(c,'POST','/api/simulador',{'saldo_inicial':1000,'tasa_anual':12,'meses':2,'aporte_mensual':100,'meta':2000})['datos'];assert sim['saldo_final']==1221.1 and sim['meses_meta']==9
   sim=pedir(c,'POST','/api/simulador',{'id_cuenta':1000,'meses':0,'aporte_mensual':0,'meta':1})['datos'];assert Decimal(str(sim['saldo_final']))==saldo(1000) and sim['meses_meta']==0
   base_saldos=filas('SELECT ID_CUENTA,SALDO,ESTADO FROM CUENTAS ORDER BY ID_CUENTA');n=filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]
   for caso in ['no_data_found','too_many_rows','dup_val_on_index','zero_divide','value_error','when_others','reraise','saldo_insuficiente','cuenta_inexistente','cuenta_bloqueada','monto_invalido','misma_cuenta','cliente_inexistente','estado_invalido']:pedir(c,'POST','/api/laboratorio/'+caso,{})
   assert filas('SELECT ID_CUENTA,SALDO,ESTADO FROM CUENTAS ORDER BY ID_CUENTA')==base_saldos and filas('SELECT COUNT(*) FROM MOVIMIENTOS')[0][0]==n
   assert pedir(c,'GET','/api/errores')['datos']
   for objeto in app.extensions['codigo_plsql']:pedir(c,'GET','/api/codigo/'+objeto)
   # Exportación de datos de prueba e importación real: verificar IDs, saldos e historial sin duplicar triggers.
   datos={'formato':'banco-oracle-mysql-v1','tablas':{},'secuencias':{}}
   with conectar(cfg) as origen:
    cur=origen.cursor()
    for tabla,columnas in COLUMNAS.items():
     cur.execute('SELECT '+','.join(columnas)+' FROM '+tabla);datos['tablas'][tabla]=[dict(zip(columnas,f)) for f in cur.fetchall()]
   archivo=RAIZ/'work/mysql_qa_export.json'
   archivo.write_text(json.dumps(datos,default=lambda x:x.isoformat() if hasattr(x,'isoformat') else str(x),ensure_ascii=False),encoding='utf-8')
   destino=cfg|{'database':cfg['database']+'_import'};instalar(parametros=destino);importar(archivo,destino)
   with conectar(destino) as imp:
    cur=imp.cursor();cur.execute('SELECT ID_CUENTA,SALDO,ESTADO FROM CUENTAS ORDER BY ID_CUENTA');assert cur.fetchall()==base_saldos
    cur.execute('SELECT COUNT(*) FROM MOVIMIENTOS');assert cur.fetchone()[0]==n
    cur.execute('SELECT COUNT(*) FROM AUDITORIA');assert cur.fetchone()[0]==len(datos['tablas']['TBL_AUDITORIA'])
    cur.execute('SELECT ID_CUENTA FROM CUENTAS ORDER BY ID_CUENTA DESC LIMIT 1');maximo=cur.fetchone()[0]
    imp.commit();imp.start_transaction();r=cur.callproc('SP_ABRIR_CUENTA',[1,'AHORROS',0,None,None,None,None,None,None]);assert r[-3]=='OK' and r[4]>maximo;imp.rollback()
   print('PRUEBA MYSQL REAL OK: diez pantallas, CRUD, apertura, depósito, retiro, transferencia atómica/comisión/auditoría, bloqueo, límites/versiones, categorías, intereses sin duplicar, cursor mensual, reporte JSON, simulador, 14 casos, catálogo e importación con IDs/saldos/historial conservados.')
 finally:
  pool=app.extensions.get('mysql_pool')
  if pool and hasattr(pool,'_remove_connections'):pool._remove_connections()
  # Solo los dos esquemas temporales con nombre generado por esta ejecución.
  sinbase={k:v for k,v in cfg.items() if k!='database'}
  with conectar(sinbase) as admin:
   with admin.cursor() as cur:
    for nombre in [cfg['database'],cfg['database']+'_import']:
     assert nombre.startswith('banco_qa_mysql_') and nombre.replace('_','').isalnum()
     cur.execute('DROP DATABASE IF EXISTS `'+nombre+'`')

if __name__=='__main__':verificar()
