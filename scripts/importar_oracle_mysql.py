"""Importa una exportación propia sobre tablas vacías; mantiene IDs y saldos."""
import argparse
import json
import re
import sys
from datetime import datetime,date
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo
from datos_portables import COLUMNAS,SECUENCIAS
from instalar_mysql import instalar,conectar,RAIZ
sys.path.insert(0,str(RAIZ))
from app.config import parametros_conexion


def validar_exportacion(datos):
    if datos.get('formato')!='banco-oracle-mysql-v1': raise ValueError('Formato de exportación desconocido')
    tablas=datos.get('tablas',{})
    if set(tablas)-set(COLUMNAS) or not set(COLUMNAS).difference({'TBL_LIMITES_CATEGORIAS'}).issubset(tablas): raise ValueError('La exportación debe contener únicamente las tablas propias esperadas')
    for tabla,filas in tablas.items():
        for fila in filas:
            if set(fila)!=set(COLUMNAS[tabla]): raise ValueError('Columnas inesperadas en '+tabla)
    for nombre,valor in datos.get('secuencias',{}).items():
        if nombre not in SECUENCIAS or not 1<=int(valor)<=9999999999: raise ValueError('Secuencia inválida en exportación')
    ids={int(c['ID_CUENTA']) for c in tablas['TBL_CUENTAS']}
    totales={i:Decimal(0) for i in ids}
    for m in tablas['TBL_MOVIMIENTOS']:
        cuenta=int(m['ID_CUENTA'])
        if cuenta not in ids: raise ValueError('Movimiento con cuenta inexistente')
        monto=Decimal(str(m['MONTO']))
        if not monto.is_finite() or monto<=0: raise ValueError('Monto inválido en exportación')
        totales[cuenta]+=monto if m['TIPO'] in ('DEPOSITO','TRANSF_RECIBIDA','INTERES') else -monto
    for c in tablas['TBL_CUENTAS']:
        if totales[int(c['ID_CUENTA'])]!=Decimal(str(c['SALDO'])): raise ValueError('Saldo inconsistente con los movimientos de una cuenta; no se importa parcialmente')
    return tablas


def convertir(columna,valor):
    if valor is None: return None
    if columna.startswith('FECHA') and isinstance(valor,str):
        dt=datetime.fromisoformat(valor)
        if dt.tzinfo: dt=dt.astimezone(ZoneInfo('America/Lima')).replace(tzinfo=None)
        return dt.date() if columna=='FECHA_ULT_INTERES' else dt
    return valor


def importar(archivo,parametros):
    datos=json.loads(Path(archivo).read_text(encoding='utf-8'),parse_float=Decimal)
    tablas=validar_exportacion(datos)
    with conectar(parametros) as c:
        cursor=c.cursor()
        for tabla in COLUMNAS:
            if tabla=='TBL_LIMITES_CATEGORIAS': continue
            cursor.execute('SELECT COUNT(*) FROM '+tabla)
            if cursor.fetchone()[0]: raise ValueError('Destino no vacío: se rechaza la importación para no sobrescribir datos')
        c.commit();c.start_transaction()
        try:
            cursor.execute('SET @banco_importacion=1')
            cursor.execute("SET SESSION time_zone='-05:00'")
            for tabla,columnas in COLUMNAS.items():
                if tabla=='TBL_LIMITES_CATEGORIAS':
                    filas=tablas.get(tabla,[])
                    if filas:
                        if len(filas)!=1 or int(filas[0]['ID_CONFIG'])!=1: raise ValueError('Configuración de límites inválida')
                        f=filas[0];cursor.execute('UPDATE TBL_LIMITES_CATEGORIAS SET LIMITE_GOLD=%s,LIMITE_PREMIUM=%s,VERSION=%s WHERE ID_CONFIG=1',(f['LIMITE_GOLD'],f['LIMITE_PREMIUM'],f['VERSION']))
                    continue
                valores=[tuple(convertir(n,f[n]) for n in columnas) for f in tablas[tabla]]
                if valores: cursor.executemany('INSERT INTO '+tabla+' ('+','.join(columnas)+') VALUES ('+','.join(['%s']*len(columnas))+')',valores)
                cursor.execute('SELECT COUNT(*) FROM '+tabla)
                if cursor.fetchone()[0]!=len(tablas[tabla]): raise ValueError('Conteos distintos tras importar '+tabla)
            maximo=max([990]+[int(f['ID_CUENTA']) for f in tablas['TBL_CUENTAS']])
            siguiente=int(datos.get('secuencias',{}).get('SQ_CUENTA',maximo+10))
            cursor.execute("UPDATE TBL_SECUENCIAS SET VALOR=%s WHERE NOMBRE='SQ_CUENTA'",(max(maximo,siguiente-10),))
            cursor.execute('SET @banco_importacion=0');c.commit()
        except Exception:
            c.rollback();cursor.execute('SET @banco_importacion=0');raise
        # ALTER es DDL: solo tras confirmar y comparar los registros importados.
        for secuencia,tabla in SECUENCIAS.items():
            if secuencia=='SQ_CUENTA':continue
            siguiente=int(datos.get('secuencias',{}).get(secuencia,1))
            if siguiente<1:raise ValueError('Valor de secuencia inválido')
            cursor.execute('ALTER TABLE '+tabla+' AUTO_INCREMENT='+str(siguiente))
        cursor.close()
    print('IMPORTACION MYSQL OK:',{t:len(f) for t,f in tablas.items()})

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('archivo');p.add_argument('--database',default='sistema_banco_importado');p.add_argument('--instalar',action='store_true');p.add_argument('--activar',action='store_true');a=p.parse_args()
    if not re.fullmatch(r'[a-zA-Z][a-zA-Z0-9_]{0,63}',a.database):raise SystemExit('Nombre de base inválido')
    cfg=parametros_conexion();cfg['database']=a.database
    if a.instalar: instalar(parametros=cfg)
    importar(a.archivo,cfg)
    if a.activar:
        (RAIZ/'mysql.local.json').write_text(json.dumps(cfg,ensure_ascii=False),encoding='utf-8');print('Base importada activada para la aplicación. Reinicia Flask.')
