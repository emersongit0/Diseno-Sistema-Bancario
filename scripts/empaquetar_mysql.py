"""Paquete reproducible por lista permitida: nunca incluye secretos ni dumps."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import hashlib
RAIZ=Path(__file__).resolve().parents[1]
EXTENSIONES={'.py','.js','.css','.html','.json','.sql','.md','.txt','.ini','.ps1'}


def empaquetar():
    destino=RAIZ/'entregables';destino.mkdir(exist_ok=True)
    rutas=[]
    for carpeta in ['app','sql','scripts','tests','docs']:
        for p in (RAIZ/carpeta).rglob('*'):
            if not p.is_file() or p.suffix not in EXTENSIONES or '__pycache__' in p.parts:continue
            if p.name.startswith('snapshot_ad_'):continue
            rutas.append(p)
    for nombre in ['README.md','AGENTS.md','requirements.txt','pytest.ini','run.py','probar_conexion.py','iniciar_mysql.ps1','mysql.local.example.json','INSTALAR_MYSQL.sql','.gitignore']:
        rutas.append(RAIZ/nombre)
    archivo=destino/'sistema_banco_mysql.zip'
    with ZipFile(archivo,'w',compression=ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(set(rutas)):
            relativo=p.relative_to(RAIZ)
            if p.name in {'.env','mysql.local.json'} or any(x in relativo.parts for x in ['.git','.venv','work','exportaciones','entregables']):raise ValueError('Archivo privado rechazado del paquete')
            z.write(p,Path('sistema_banco_mysql')/relativo)
    with ZipFile(archivo) as z:
        assert z.testzip() is None
        assert not any(n.endswith('/mysql.local.json') or '/.env' in n or '/.venv/' in n or '/work/' in n or '/exportaciones/' in n for n in z.namelist())
    checksum=hashlib.sha256(archivo.read_bytes()).hexdigest()
    (destino/'SHA256.txt').write_text(checksum+'  '+archivo.name+'\n',encoding='utf-8')
    print('ENTREGABLE OK:',archivo.name,'Archivos:',len(rutas),'Bytes:',archivo.stat().st_size)

if __name__=='__main__':empaquetar()
