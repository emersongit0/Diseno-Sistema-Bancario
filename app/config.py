"""Configuración MySQL local; nunca carga el archivo .env de MySQL."""
import json
import os
from pathlib import Path
RAIZ=Path(__file__).resolve().parent.parent


def parametros_conexion() -> dict:
    ruta=Path(os.getenv('BANCO_MYSQL_CONFIG',str(RAIZ/'mysql.local.json')))
    datos=json.loads(ruta.read_text(encoding='utf-8')) if ruta.is_file() else {}
    for clave,variable in [('host','MYSQL_HOST'),('port','MYSQL_PORT'),('user','MYSQL_USER'),('password','MYSQL_PASSWORD'),('database','MYSQL_DATABASE')]:
        if variable in os.environ: datos[clave]=os.environ[variable]
    datos.setdefault('host','127.0.0.1');datos.setdefault('port',3306);datos.setdefault('database','sistema_banco_mysql');datos.setdefault('user','root')
    if not datos.get('password'): raise ValueError('Configura MYSQL_PASSWORD o mysql.local.json (archivo privado ignorado por Git).')
    datos['port']=int(datos['port'])
    return {n:datos[n] for n in ('host','port','user','password','database')}
