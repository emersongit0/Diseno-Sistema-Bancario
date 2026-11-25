"""Comprueba MySQL local sin mostrar credenciales ni consultar Oracle."""
import mysql.connector
from app.config import parametros_conexion

if __name__=='__main__':
    with mysql.connector.connect(**parametros_conexion()) as c:
        with c.cursor() as cur:
            cur.execute('SELECT VERSION(),DATABASE()')
            version,base=cur.fetchone()
            print('MYSQL CONECTADO. Versión:',version,'Base:',base)
