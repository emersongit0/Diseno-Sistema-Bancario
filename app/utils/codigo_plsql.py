"""Índice local por marcadores; nunca consulta fuentes Oracle ni rutas del usuario."""
from pathlib import Path
import re

RAIZ = Path(__file__).resolve().parents[2]
BLOQUES = {"BLOQUE_SIMULADOR_INTERES","BLOQUE_RESUMEN_CLIENTE"}


def indexar(raiz: Path = RAIZ) -> dict[str,dict]:
    """Carga únicamente los SQL de producción y los dos bloques permitidos."""
    indice = {}
    archivos = sorted((raiz / "sql").glob("*.sql")) + sorted((raiz / "sql/bloques").glob("*.sql"))
    for archivo in archivos:
        if archivo.name.startswith(("00","10_","99_")):
            continue
        texto = archivo.read_text(encoding="utf-8")
        for nombre,codigo in re.findall(r"^-- @OBJETO: (\w+)\s*\n(.*?)^-- @FIN\s*$",texto,re.M|re.S):
            if nombre in indice:
                raise ValueError("Marcador de objeto duplicado.")
            tipo = re.search(r"CREATE(?: OR REPLACE)?\s+(\w+)",codigo,re.I)
            indice[nombre] = dict(objeto=nombre,tipo=tipo[1].upper() if tipo else "BLOQUE",
                                  archivo=archivo.relative_to(raiz).as_posix(),codigo=codigo.strip())
    return indice


def codigo_bloque(indice: dict, nombre: str) -> str:
    """Entrega solo uno de los dos bloques autorizados, sin separador de script."""
    if nombre not in BLOQUES:
        raise ValueError("Bloque no permitido.")
    lineas = indice[nombre]["codigo"].splitlines()
    if lineas and lineas[-1].strip() == "/":
        lineas.pop()
    return "\n".join(lineas)
