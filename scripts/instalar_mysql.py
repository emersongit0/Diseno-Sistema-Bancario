"""Instala MySQL en una base nueva, sin DROP ni lectura del .env Oracle."""
import argparse
import re
import sys
from pathlib import Path
import mysql.connector
RAIZ=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(RAIZ))
from app.config import parametros_conexion


def sentencias(texto):
    delimitador=';';buffer=[]
    for linea in texto.splitlines():
        if linea.strip().upper().startswith('DELIMITER '):
            delimitador=linea.strip().split()[1];continue
        buffer.append(linea)
        if linea.rstrip().endswith(delimitador):
            sql='\n'.join(buffer).strip()[:-len(delimitador)].strip();buffer=[]
            if sql: yield sql
    if any(x.strip() and not x.lstrip().startswith('--') for x in buffer): raise ValueError('SQL sin delimitador final')


def conectar(parametros):
    return mysql.connector.connect(**parametros,autocommit=False,charset='utf8mb4',use_pure=True,connection_timeout=15)


def sembrar(c):
    cur=c.cursor()
    for tabla in ('CLIENTES','CUENTAS','MOVIMIENTOS'):
        cur.execute('SELECT COUNT(*) FROM '+tabla)
        if cur.fetchone()[0]: raise ValueError('La carga demo requiere tablas vacías; no se modificaron los datos existentes')
    c.commit();c.start_transaction()
    def llamar(nombre,args,out=0):
        r=cur.callproc(nombre,list(args)+[None]*out+[None,None,None])
        if r[-3]!='OK': raise RuntimeError(nombre+': '+str(r[-1]))
        return r[len(args):len(args)+out]
    personas=[('71000001','Ana','Torres'),('71000002','Luis','Vargas'),('71000003','María','Quispe'),('71000004','José','Rojas'),('71000005','Lucía','Castillo'),('71000006','Diego','Flores')]
    clientes=[]
    for i,(dni,nombre,apellido) in enumerate(personas,1):
        cur.execute('INSERT INTO CLIENTES(DNI,NOMBRES,APELLIDOS,EMAIL) VALUES(%s,%s,%s,%s)',(dni,nombre,apellido,f'demo{i}@banco.example'));clientes.append(cur.lastrowid)
    cuentas=[]
    for i,tipo,saldo in [(0,'AHORROS',1000),(1,'CORRIENTE',2000),(2,'AHORROS',10000),(3,'CORRIENTE',15000),(4,'AHORROS',60000),(5,'AHORROS',80000),(0,'CORRIENTE',3000),(2,'AHORROS',12000)]:
        cuenta,nro=llamar('SP_ABRIR_CUENTA',[clientes[i],tipo,saldo,None],2);cuentas.append(cuenta)
    for cuenta in cuentas:
        llamar('SP_DEPOSITAR',[cuenta,200]);llamar('SP_RETIRAR',[cuenta,50])
    llamar('SP_ACTUALIZAR_CATEGORIAS',[],2)
    llamar('SP_TRANSFERIR',[cuentas[0],cuentas[1],100]);llamar('SP_TRANSFERIR',[cuentas[4],cuentas[3],500])
    llamar('SP_ACTUALIZAR_CATEGORIAS',[],2)
    for tabla,esperado in [('CLIENTES',6),('CUENTAS',8),('MOVIMIENTOS',30)]:
        cur.execute('SELECT COUNT(*) FROM '+tabla)
        if cur.fetchone()[0]!=esperado: raise RuntimeError('Conteo inesperado en '+tabla)
    c.commit();cur.close();print('DATOS MYSQL OK: 6 clientes, 8 cuentas y 30 movimientos.')


def instalar(demo=False,continuar=False,parametros=None):
    parametros=dict(parametros or parametros_conexion());nombre=parametros.pop('database')
    if not re.fullmatch(r'[a-zA-Z][a-zA-Z0-9_]{0,63}',nombre): raise ValueError('Nombre de base inválido')
    with conectar(parametros) as c:
        cur=c.cursor();cur.execute('SELECT VERSION()');version=cur.fetchone()[0];print('Servidor MySQL:',version)
        numeros=tuple(int(x) for x in re.match(r'(\d+)\.(\d+)\.(\d+)',version).groups())
        if numeros<(8,0,16) or 'mariadb' in version.lower(): raise ValueError('Se requiere MySQL 8.0.16+; no se modifica el servidor incompatible')
        cur.execute('SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=%s',(nombre,))
        if cur.fetchone()[0] and not continuar: raise ValueError('La base destino ya tiene tablas. No se sobrescribe. Usa otra base vacía; --continuar solo reanuda una instalación parcial propia.')
        cur.execute('CREATE DATABASE IF NOT EXISTS `'+nombre+'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');c.database=nombre
        cur.execute("SET SESSION time_zone='-05:00'");cur.execute('SET SESSION innodb_lock_wait_timeout=5')
        for archivo in sorted((RAIZ/'sql/mysql').glob('0[123]_*.sql')):
            print('Instalando',archivo.name)
            for sql in sentencias(archivo.read_text(encoding='utf-8')):
                crear=re.search(r'CREATE(?: OR REPLACE)?(?: ALGORITHM=\w+)?\s+(TABLE|VIEW|FUNCTION|PROCEDURE|TRIGGER)\s+(\w+)',sql,re.I)
                if continuar and crear:
                    tipo,objeto=crear.groups()
                    fuente='TABLES' if tipo.upper() in ('TABLE','VIEW') else 'TRIGGERS' if tipo.upper()=='TRIGGER' else 'ROUTINES'
                    columna='TABLE_NAME' if fuente=='TABLES' else 'TRIGGER_NAME' if fuente=='TRIGGERS' else 'ROUTINE_NAME'
                    cur.execute(f'SELECT COUNT(*) FROM INFORMATION_SCHEMA.{fuente} WHERE {fuente[:-1] if fuente=="ROUTINES" else "TRIGGER" if fuente=="TRIGGERS" else "TABLE"}_SCHEMA=%s AND {columna}=%s',(nombre,objeto))
                    if cur.fetchone()[0]: continue
                if continuar and re.search(r'INSERT INTO TBL_(SECUENCIAS|LIMITES_CATEGORIAS)',sql):
                    sql=sql.replace('INSERT INTO','INSERT IGNORE INTO',1)
                cur.execute(sql)
            c.commit()
        cur.close()
        if demo: sembrar(c)
    print('MYSQL INSTALADO:',nombre)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--demo',action='store_true');parser.add_argument('--continuar',action='store_true');args=parser.parse_args()
    try: instalar(args.demo,args.continuar)
    except Exception as error:
        print('Instalación detenida:',type(error).__name__,str(error) if isinstance(error,ValueError) else f'MySQL {getattr(error,"errno",0)}: {getattr(error,"msg","No se pudo completar la instalación")}');sys.exit(1)
