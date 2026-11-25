"""Índice local de objetos SQL MySQL, sin consultar la base de datos."""
from pathlib import Path
import re
RAIZ=Path(__file__).resolve().parents[2]


def indexar(raiz: Path=RAIZ) -> dict:
    indice={}
    for archivo in sorted((raiz/'sql/mysql').glob('*.sql')):
        texto=archivo.read_text(encoding='utf-8')
        for nombre,codigo in re.findall(r'^-- @OBJETO: (\w+)\s*\n(.*?)^-- @FIN\s*$',texto,re.M|re.S):
            if nombre in indice: raise ValueError('Objeto SQL duplicado.')
            tipo=re.search(r'CREATE(?: OR REPLACE)?(?: ALGORITHM=\w+)?\s+(\w+)',codigo,re.I)
            indice[nombre]=dict(objeto=nombre,tipo=tipo[1].upper() if tipo else 'SQL',archivo=archivo.relative_to(raiz).as_posix(),codigo=(codigo.strip()[:-2]+';' if codigo.strip().endswith('$$') else codigo.strip()))
    return indice
