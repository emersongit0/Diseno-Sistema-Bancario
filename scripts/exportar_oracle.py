"""Exportación manual Oracle: no carga .env ni consulta tablas ajenas."""
import argparse
import getpass
import json
from datetime import date,datetime
from decimal import Decimal
from pathlib import Path
from datos_portables import COLUMNAS,SECUENCIAS


def exportar(destino):
    try: import oracledb
    except ImportError: raise SystemExit('Instala la dependencia opcional: python -m pip install oracledb')
    dsn=input('DSN Oracle (host:puerto/servicio): ').strip()
    usuario=input('Usuario de Oracle: ').strip()
    clave=getpass.getpass('Contraseña de Oracle (no se guarda): ')
    contenido={'formato':'banco-oracle-mysql-v1','tablas':{},'secuencias':{},'limites_exportados':True}
    with oracledb.connect(user=usuario,password=clave,dsn=dsn) as c:
        with c.cursor() as cursor:
            cursor.execute('SET TRANSACTION READ ONLY')
            for tabla,columnas in COLUMNAS.items():
                try: cursor.execute('SELECT '+','.join(columnas)+' FROM '+tabla)
                except oracledb.DatabaseError as error:
                    if tabla=='TBL_LIMITES_CATEGORIAS' and getattr(error.args[0],'code',0)==942:
                        contenido['limites_exportados']=False;continue
                    raise
                contenido['tablas'][tabla]=[dict(zip(columnas,fila)) for fila in cursor]
            for secuencia in SECUENCIAS:
                cursor.execute('SELECT LAST_NUMBER FROM USER_SEQUENCES WHERE SEQUENCE_NAME=:nombre',nombre=secuencia)
                fila=cursor.fetchone()
                if fila: contenido['secuencias'][secuencia]=int(fila[0])
        c.rollback()
    def serializar(valor):
        if isinstance(valor,(date,datetime)): return valor.isoformat()
        if isinstance(valor,Decimal): return str(valor)
        raise TypeError('Tipo de dato no exportable')
    destino=Path(destino)
    if destino.exists(): raise ValueError('El archivo ya existe; elige otro nombre para no sobrescribirlo')
    destino.parent.mkdir(parents=True,exist_ok=True)
    with destino.open('x',encoding='utf-8') as f: json.dump(contenido,f,default=serializar,ensure_ascii=False,indent=2)
    print('EXPORTACION OK. Registros:',{t:len(f) for t,f in contenido['tablas'].items()})
    if not contenido['limites_exportados']: print('La tabla de límites no existía en Oracle: la importación usará los valores iniciales 5000/50000.')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--salida',default='exportaciones/banco_oracle.json');a=p.parse_args();exportar(a.salida)
