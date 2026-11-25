# Banco MySQL — cuentas y transferencias

Versión de la rama **migracion/MySQL**. Flask y las diez pantallas funcionan con MySQL local. La base de demostración instalada se llama **sistema_banco_mysql**. No depende de FreeSQL para funcionar.

## Probar ahora en este equipo

Desde la carpeta del proyecto:

```powershell
.\.venv\Scripts\python.exe run.py
```

Este comando inicia Flask usando la configuración MySQL local ya preparada. Abre **http://127.0.0.1:5000**. Detén el servidor anterior si estaba abierto; para detener este servidor usa Ctrl+C. Recarga con Ctrl+F5 para obtener los módulos nuevos.

Alternativa:

```powershell
.\iniciar_mysql.ps1
```

El script prepara Python/dependencias si faltan, comprueba MySQL, instala la demo únicamente si la base está vacía y abre Flask. Conserva los datos existentes. Si Windows impide ejecutar scripts locales, usa el primer comando, o `powershell -ExecutionPolicy Bypass -File .\iniciar_mysql.ps1` para aplicar la excepción solo a ese proceso.

## Qué datos hay

La instalación local contiene **6 clientes, 8 cuentas y 30 movimientos** de demostración, con Ana Torres y Luis Vargas. Las comprobaciones del laboratorio también pueden dejar registros de error. No se han copiado los registros actuales de tu cuenta Oracle: para conservarlos usa la exportación/importación documentada abajo. Las operaciones de la aplicación alteran los conteos iniciales; no vuelvas a cargar la demo para reiniciarlos.

## Instalación desde el ZIP o en otro equipo

Requisitos: Python 3.11+ y MySQL 8.0.16 o posterior (probado: 9.7.1). MySQL debe estar instalado y ejecutándose; el ZIP no contiene el servidor MySQL.

1. Extrae el paquete y entra en `sistema_banco_mysql`.
2. Ejecuta `iniciar_mysql.ps1`. Si falta `mysql.local.json`, solicita el usuario y la contraseña local sin mostrarla.
3. La primera ejecución crea el entorno, instala dependencias y prepara la base nueva con demo. No sobrescribe una base con tablas.
4. Abre la dirección local indicada.

La configuración privada usa `mysql.local.json`, ignorado por Git. Hay un ejemplo vacío en `mysql.local.example.json`. También se admiten MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD y MYSQL_DATABASE como variables del proceso. BANCO_MYSQL_CONFIG permite elegir otro archivo privado. El antiguo archivo .env de Oracle no se lee.

Instalación SQL alternativa en Workbench: `INSTALAR_MYSQL.sql` contiene base, tablas, vistas, funciones, triggers, procedimientos y demo. **Solo se ejecuta sobre una base nueva**, no sobre esta instalación ya preparada. No contiene contraseñas ni elimina bases.

## Transferir los registros actuales de Oracle

[docs/MIGRACION_MYSQL.md](docs/MIGRACION_MYSQL.md) explica el exportador manual y el importador. Conservan IDs, números, saldos, fechas, movimientos, auditoría, errores, límites y siguiente numeración. La importación exige otra base vacía; no mezcla ni sobrescribe la demo local. La comprobación automática probó el formato con datos de prueba; la exportación remota real todavía no se ha ejecutado.

## Pruebas

```powershell
.\.venv\Scripts\python.exe -m pytest -q
```

Ejecuta la suite MySQL con mocks, sin abrir conexiones. Resultado de esta entrega: **112 pruebas correctas**.

```powershell
.\.venv\Scripts\python.exe scripts/verificar_mysql.py
```

Crea bases temporales propias y prueba realmente las operaciones, las revierte o elimina al terminar. Usa MySQL local; no contacta Oracle y no modifica la base activa. Debe imprimir **PRUEBA MYSQL REAL OK**. La prueba de navegador también comprobó las diez pantallas, cotización, reporte, límites y gráfico real en escritorio/móvil.

## Archivos y diferencias

- SQL activo: `sql/mysql/01_esquema.sql`, `02_funciones_triggers.sql`, `03_procedimientos.sql` y `datos/04_datos_prueba.sql`.
- Instalación/conexión/transferencia: `scripts/` y `probar_conexion.py`.
- [Migración y equivalencias](docs/MIGRACION_MYSQL.md), [especificación actual](docs/ESPECIFICACION.md), [guía actual de sustentación](docs/GUIA_SUSTENTACION.md), [matriz MySQL](docs/MATRIZ_OBJETOS.md).
- Referencia original: `sql/oracle`, `docs/oracle`, `tests/oracle_reference`. No se ejecuta durante el arranque ni se mezcla con MySQL.

Los sinónimos son vistas actualizables; las secuencias se sustituyen por AUTO_INCREMENT/contador; bloques y función pipelined pasan a procedimientos con JSON. La lógica financiera sigue dentro de MySQL. El registro de errores después de rollback se coordina desde Flask. Las escrituras no se reintentan.

## Entregable

`scripts/empaquetar_mysql.py` produce `entregables/sistema_banco_mysql.zip` con aplicación, SQL, scripts, documentación y pruebas. No incluye contraseñas, exportaciones de datos, .env, entorno virtual ni Git. El usuario realiza commit y push.
