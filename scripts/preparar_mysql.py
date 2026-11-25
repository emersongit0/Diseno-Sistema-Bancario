"""Completa solo una instalación nueva; nunca borra una base existente."""
import sys
from pathlib import Path
RAIZ=Path(__file__).resolve().parents[1];sys.path.insert(0,str(RAIZ))
from app.config import parametros_conexion
from instalar_mysql import instalar,conectar

if __name__=='__main__':
    cfg=parametros_conexion();servidor={k:v for k,v in cfg.items() if k!='database'}
    with conectar(servidor) as c:
        with c.cursor() as cur:
            cur.execute('SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=%s',(cfg['database'],))
            tablas=cur.fetchone()[0]
    if not tablas: instalar(demo=True,parametros=cfg)
    else:
        with conectar(cfg) as c:
            with c.cursor() as cur:
                cur.execute('SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA=%s',(cfg['database'],))
                if cur.fetchone()[0]!=16: raise SystemExit('Instalación incompleta o base distinta. Revisa docs/MIGRACION_MYSQL.md antes de reanudar; no se sobrescribió nada.')
        print('MySQL preparado; se conservan los datos existentes.')
