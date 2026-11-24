"""Persistencia de límites mediante el sinónimo; restricciones en Oracle."""
from typing import Any
from app.repositories.base import consultar
from app.utils.resultado import Resultado
from app.utils.errores import ErrorAplicacion


def leer(conexion: Any) -> Resultado:
    filas = consultar(conexion,"SELECT LIMITE_GOLD,LIMITE_PREMIUM,VERSION FROM LIMITES_CATEGORIAS WHERE ID_CONFIG=1")
    if not filas:
        raise ErrorAplicacion("Falta instalar la configuración de categorías.",409)
    return Resultado(filas[0])


def guardar(conexion: Any, datos: dict) -> Resultado:
    with conexion.cursor() as cursor:
        cursor.execute("SELECT VERSION FROM LIMITES_CATEGORIAS WHERE ID_CONFIG=1 FOR UPDATE WAIT 5")
        fila = cursor.fetchone()
        if not fila or fila[0] != datos['version']:
            raise ErrorAplicacion("Los límites cambiaron. Cancela la edición y vuelve a abrirla para cargar los valores vigentes.",409)
        cursor.execute("UPDATE LIMITES_CATEGORIAS SET LIMITE_GOLD=:limite_gold,LIMITE_PREMIUM=:limite_premium,VERSION=VERSION+1 WHERE ID_CONFIG=1",{n:datos[n] for n in ('limite_gold','limite_premium')})
    resultado = leer(conexion)
    resultado.mensaje = "Límites guardados. Usa Actualizar categorías para aplicarlos a los clientes."
    return resultado
