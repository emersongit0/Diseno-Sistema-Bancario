"""Lecturas y DML de clientes mediante su vista de compatibilidad."""
from typing import Any
from app.repositories.base import consultar, funcion, procedimiento
from app.utils.resultado import Resultado
from app.utils.errores import ErrorAplicacion


def listar(conexion: Any) -> Resultado:
    return Resultado(consultar(conexion,"SELECT ID_CLIENTE,DNI,NOMBRES,APELLIDOS,EMAIL,CATEGORIA,FECHA_REGISTRO FROM CLIENTES ORDER BY ID_CLIENTE"))


def crear(conexion: Any, datos: dict) -> Resultado:
    with conexion.cursor() as cursor:
        cursor.execute("INSERT INTO CLIENTES (DNI,NOMBRES,APELLIDOS,EMAIL) VALUES (%(dni)s,%(nombres)s,%(apellidos)s,%(email)s)",datos)
        return Resultado({"id_cliente":int(cursor.lastrowid)},mensaje="Cliente creado.")


def editar(conexion: Any, identificador: int, datos: dict) -> Resultado:
    with conexion.cursor() as cursor:
        cursor.execute("UPDATE CLIENTES SET NOMBRES=%(nombres)s,APELLIDOS=%(apellidos)s,EMAIL=%(email)s WHERE ID_CLIENTE=%(id)s",datos | {"id":identificador})
        if cursor.rowcount == 0:
            raise ErrorAplicacion("Cliente inexistente",404,-20006)
        return Resultado({"id_cliente":identificador},mensaje="Cliente actualizado.")


def resumen(conexion: Any, identificador: int) -> Resultado:
    return procedimiento(conexion,"SP_RESUMEN_CLIENTE",[identificador],{"json":"json"})


def categoria(conexion: Any, saldo) -> Resultado:
    return Resultado({"categoria":funcion(conexion,"FN_CATEGORIA_CLIENTE",[saldo],texto=True)})
