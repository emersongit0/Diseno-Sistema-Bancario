"""Resultado interno independiente de Flask y del controlador MySQL."""
from dataclasses import dataclass
from typing import Any

@dataclass
class Resultado:
    datos: Any = None
    estado: str = "OK"
    codigo: int = 0
    mensaje: str = "Consulta realizada."


def respuesta(datos: Any = None, mensaje: str = "Consulta realizada.", codigo: int = 0,
              objetos: list[str] | None = None, ok: bool = True) -> dict:
    """Construye el contrato JSON común."""
    return dict(ok=ok, mensaje=mensaje, codigo=codigo, datos=datos, objetos_oracle=objetos or [])
