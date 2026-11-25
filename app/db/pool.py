"""Pool MySQL perezoso y transacciones explícitas por petición."""
from contextlib import contextmanager
from threading import Lock
import atexit
from flask import current_app
from mysql.connector.pooling import MySQLConnectionPool
from mysql.connector.constants import ClientFlag
from app.config import parametros_conexion
_CERROJO=Lock()


def obtener_pool():
    app=current_app._get_current_object()
    with _CERROJO:
        if 'mysql_pool' not in app.extensions:
            parametros=app.config.get('MYSQL_CONFIG') or parametros_conexion()
            app.extensions['mysql_pool']=MySQLConnectionPool(**parametros,pool_name='banco_'+str(id(app)),pool_size=5,pool_reset_session=True,client_flags=[ClientFlag.FOUND_ROWS],autocommit=False,charset='utf8mb4',use_unicode=True,use_pure=True,connection_timeout=15,read_timeout=15,write_timeout=15)
            cerrar=getattr(app.extensions['mysql_pool'],'_remove_connections',None)
            if cerrar: atexit.register(cerrar)
    return app.extensions['mysql_pool']


@contextmanager
def conexion():
    prestada=obtener_pool().get_connection()
    try:
        with prestada.cursor() as cursor:
            cursor.execute("SET SESSION time_zone='-05:00'")
            cursor.execute('SET SESSION innodb_lock_wait_timeout=5')
            cursor.execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED')
            cursor.execute('SET @banco_importacion=0')
        prestada.start_transaction()
        yield prestada
    finally:
        try: prestada.rollback()
        finally: prestada.close()
