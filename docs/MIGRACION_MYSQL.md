# Migración Oracle → MySQL

## Estado de esta entrega

Rama: migracion/MySQL. MySQL local detectado y probado: 9.7.1, puerto 3306. Base instalada: sistema_banco_mysql. Credenciales en archivo privado ignorado por Git; no se publican. La aplicación ya usa MySQL y tiene demo 6/8/30. Oracle no fue consultado ni alterado. Las tablas AD_ quedan fuera de todo exportador/importador.

La migración de estructura, reglas, rutinas, backend y pantallas está implementada y probada. **No confundir con haber copiado tus registros actuales de FreeSQL**: eso requiere la exportación manual siguiente. El origen remoto no se ha leído y no se inventa su contenido.

## Exportar Oracle e importar todos sus registros

Hazlo mientras tu servicio Oracle esté disponible. La exportación es de solo lectura, consistente mediante SET TRANSACTION READ ONLY. Solicita DSN, usuario y contraseña de Oracle de forma interactiva; no abre .env y no guarda la contraseña.

```powershell
.\.venv\Scripts\python.exe -m pip install oracledb
```

Instala el controlador opcional exclusivamente para exportar el origen. La aplicación MySQL no lo necesita.

```powershell
.\.venv\Scripts\python.exe scripts/exportar_oracle.py --salida exportaciones/banco_oracle.json
```

Exporta únicamente las seis tablas propias del banco y consulta las cinco secuencias propias por nombre. Si la tabla de límites aún no existía en Oracle, se informa y se mantienen los límites iniciales en MySQL. El archivo contiene datos del banco: permanece fuera de Git y del ZIP.

```powershell
.\.venv\Scripts\python.exe scripts/importar_oracle_mysql.py exportaciones/banco_oracle.json --database sistema_banco_importado --instalar --activar
```

Crea otra base nueva, importa y valida los registros, y solo tras éxito activa esa base en la configuración privada local. No reemplaza sistema_banco_mysql. Reinicia Flask para usar la base importada. Si el destino ya tiene datos, se detiene. No uses --activar si quieres revisar la base importada antes de seleccionarla.

La carga preserva IDs, números de cuenta, saldos, fechas, categorías, movimientos, auditoría y errores. Desactiva los efectos de triggers solo para la conexión de importación, para no sumar otra vez los movimientos ni duplicar auditoría. Compara conteos y verifica que la suma de movimientos explique cada saldo. Ajusta contador de cuentas y AUTO_INCREMENT para no reutilizar IDs existentes. Mantiene claves foráneas y restricciones activas. No mezcla bases, no copia usuarios/permisos de Oracle ni hace DROP de datos existentes.

Prueba realizada: exportación de un conjunto MySQL de prueba al formato portable e importación en otra base temporal, con comparación de IDs/saldos/historial/auditoría y apertura posterior. Esto prueba el importador; no acredita que el origen Oracle real se haya exportado. No se probó wallet Oracle en esta entrega; si el origen exige wallet, el exportador necesita esa adaptación antes de ejecutarlo allí.

## Equivalencias y diferencias reales

| Oracle original | MySQL actual | Efecto |
| --- | --- | --- |
| NUMBER / VARCHAR2 / TIMESTAMP | DECIMAL, BIGINT, VARCHAR, DATETIME(6) | Moneda con dos decimales; texto utf8mb4; sesión local -05:00. |
| Cinco secuencias | AUTO_INCREMENT para clientes/movimientos/auditoría/log; TBL_SECUENCIAS para cuentas | Cuenta conserva inicio 1000 y salto 10. Contador transaccional puede reutilizar números revertidos; Oracle NEXTVAL no se revertía. IDs confirmados siguen siendo únicos. |
| Sinónimos CLIENTES/CUENTAS/etc. | Seis vistas simples actualizables con esos nombres | Conserva el acceso estable a las tablas; no afirmar que MySQL soporta CREATE SYNONYM. |
| FN_ESTADO_CUENTA_MENSUAL PIPELINED y tipos SQL | SP_ESTADO_CUENTA_MENSUAL con cursor explícito y JSON OUT | Misma tabla mensual con saldo anterior; ya no hay T_MOV_FILA/T_MOV_TABLA ni PIPE ROW. Año soportado: 1000–9998. |
| Bloques anónimos | SP_SIMULADOR_INTERES y SP_RESUMEN_CLIENTE | Procedimientos almacenados reales, llamados con parámetros; no ejecutar texto SQL del usuario. |
| FOR PL/SQL | WHILE / LOOP SQL/PSM | Conserva recorrido y reglas; no se presenta FOR PL/SQL como implementado en MySQL. |
| Cursores parametrizados | Cursores que leen variables locales del nivel externo | Reporte anidado cliente/cuenta/movimiento; no parámetros formales en DECLARE CURSOR MySQL. |
| %TYPE, %ROWTYPE, CONSTANT | Variables con tipos explícitos y límites literales | Diferencia de lenguaje declarada en guía. |
| SQL%ROWCOUNT / SQL%FOUND | ROW_COUNT() y evaluación de conteos | Intereses devuelven cuentas actualizadas/omitidas. |
| RAISE_APPLICATION_ERROR, SQLCODE, SQLERRM | SIGNAL, MYSQL_ERRNO, MESSAGE_TEXT, GET DIAGNOSTICS, RESIGNAL | Códigos de negocio 20001–20007 mantienen compatibilidad negativa en la API; laboratorio muestra los errores nativos MySQL. |
| PRAGMA AUTONOMOUS_TRANSACTION | Rollback principal y registro mediante otra conexión/transacción desde Flask | No hay autonomía dentro del procedimiento. Ejecutar una rutina directamente por SQL no crea por sí solo el log independiente de la API. |
| Trigger BEFORE INSERT OR UPDATE | Dos triggers de clientes, uno por evento | MySQL exige un evento por trigger. Seis triggers totales. |
| FOR UPDATE WAIT 5 | FOR UPDATE + innodb_lock_wait_timeout=5 por sesión | Bloqueos ordenados de cuentas y error HTTP 409 por espera agotada. |

No se movieron reglas financieras a JavaScript o Python. Python valida formato, gestiona transacciones, presenta sumas y transforma JSON. Saldo, comisión, categoría, interés y simulación se calculan en MySQL.

## API y pantallas

Se mantienen las diez rutas y los endpoints de negocio. El campo JSON histórico objetos_oracle se conserva por compatibilidad del frontend, pero contiene nombres reales MySQL. Algunos nombres internos de archivos e IDs HTML también se mantienen; no implican llamadas a Oracle. El panel y el código visible muestran MySQL y leen exclusivamente sql/mysql. El catálogo coincide con 38 objetos indexados.

## Verificación y seguridad del destino

112 pruebas unitarias sin conexión, prueba real integral con bases temporales propias y navegador real contra MySQL. La prueba integral cubre fallo forzado de la tercera inserción de una transferencia (saldo, movimientos y auditoría revierten), bloqueo entre dos conexiones, repetición del periodo de intereses, rechazo de versiones antiguas de límites y conservación de datos al importar. Las bases temporales se eliminan por sus nombres generados por la prueba; no se hace limpieza amplia.

El instalador rechaza tablas existentes. --continuar solo reanuda los objetos que faltan en una instalación parcial propia; no reemplaza definiciones existentes. Para actualizar una rutina ya instalada usa un script de migración explícito o una base nueva, no --continuar. La carga demo solo acepta clientes/cuentas/movimientos vacíos.

## Fuentes técnicas

- [Restricciones de rutinas MySQL](https://dev.mysql.com/doc/refman/8.0/en/stored-program-restrictions.html): diferencias de transacciones, funciones y triggers.
- [SIGNAL](https://dev.mysql.com/doc/refman/8.0/en/signal.html) y [GET DIAGNOSTICS](https://dev.mysql.com/doc/refman/8.0/en/get-diagnostics.html): errores nativos y handlers.
- [Connector/Python callproc](https://dev.mysql.com/doc/connector-python/en/connector-python-api-mysqlcursor-callproc.html): parámetros IN/OUT del adaptador.

Aislamiento de la aplicación: READ COMMITTED. Las lecturas críticas de saldo/estado/categoría de una transferencia son FOR UPDATE; no reutilizan una instantánea antigua de REPEATABLE READ. La rutina fue actualizada en la base local y la prueba real incluye un cambio de estado entre dos conexiones.
