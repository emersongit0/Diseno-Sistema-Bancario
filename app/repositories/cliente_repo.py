"""Lecturas y DML de clientes mediante su sinónimo."""
from typing import Any
import oracledb
from app.repositories.base import consultar, funcion, bloque
from app.utils.resultado import Resultado
from app.utils.errores import ErrorAplicacion


def listar(conexion: Any) -> Resultado:
    return Resultado(consultar(conexion,"SELECT ID_CLIENTE,DNI,NOMBRES,APELLIDOS,EMAIL,CATEGORIA,FECHA_REGISTRO FROM CLIENTES ORDER BY ID_CLIENTE"))


def crear(conexion: Any, datos: dict) -> Resultado:
    with conexion.cursor() as cursor:
        identificador = cursor.var(oracledb.DB_TYPE_NUMBER)
        cursor.execute("INSERT INTO CLIENTES (DNI,NOMBRES,APELLIDOS,EMAIL) VALUES (:dni,:nombres,:apellidos,:email) RETURNING ID_CLIENTE INTO :id",datos | {"id":identificador})
        valor = identificador.getvalue()
        return Resultado({"id_cliente":int(valor[0] if isinstance(valor,list) else valor)},mensaje="Cliente creado.")


def editar(conexion: Any, identificador: int, datos: dict) -> Resultado:
    with conexion.cursor() as cursor:
        cursor.execute("UPDATE CLIENTES SET NOMBRES=:nombres,APELLIDOS=:apellidos,EMAIL=:email WHERE ID_CLIENTE=:id",datos | {"id":identificador})
        if cursor.rowcount == 0:
            raise ErrorAplicacion("Cliente inexistente",404,-20006)
        return Resultado({"id_cliente":identificador},mensaje="Cliente actualizado.")


def resumen(conexion: Any, identificador: int) -> Resultado:
    return bloque(conexion,"BLOQUE_RESUMEN_CLIENTE",{"p_id_cliente":identificador},{"p_json":"json"})


def categoria(conexion: Any, saldo) -> Resultado:
    return Resultado({"categoria":funcion(conexion,"FN_CATEGORIA_CLIENTE",[saldo],texto=True)})
