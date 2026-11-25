# Especificación activa — Banco MySQL

La petición del 24/11/2026 autoriza migrar la rama migracion/MySQL completa a MySQL local para operar sin FreeSQL. La especificación Oracle original se conserva en docs/oracle/ESPECIFICACION.md y su SQL en sql/oracle. Esta especificación corresponde al programa actual.

## Alcance y reglas

Diez pantallas Flask, moneda S/, dos decimales, clientes con DNI/correo únicos y nombres en mayúsculas. Cuentas AHORROS/CORRIENTE, activas/bloqueadas. Saldo no negativo. No se duplican reglas financieras en frontend/Python. SQL activo: sql/mysql. Servidor MySQL 8.0.16+; probado 9.7.1.

Depósito/retiro/transferencia usan procedimientos. Apertura recibe cliente/tipo/depósito/tasa; por defecto 3.00% ahorros o 0.50% corriente. Transferencia bloquea ambas cuentas por ID y registra envío/comisión/recepción. Comisión: BASICO 1.5%, GOLD 0.8%, PREMIUM 0.3%, mínimo S/1, redondeo a dos decimales. La categoría registrada se usa al cobrar comisión.

Intereses mensuales sobre cuentas activas, tasa/saldo positivos y periodo aún no aplicado. Redondeo mensual; importes cero se omiten. Los triggers mantienen saldo y auditoría. Actualizar categorías suma saldos por cliente y guarda solo diferencias. Límites editables: Gold/Premium positivos y ordenados, inicialmente 5000/50000; guardar configuración no actualiza clientes automáticamente; se controla versión y bloqueo.

Simulador de 0 a 600 meses, cuenta opcional reemplaza saldo/tasa manuales, aportes al final del mes, meta positiva. No hace DML. Proyección y meses a la meta son cálculos independientes. Estado mensual usa saldo anterior y cursor explícito, años 1000–9998. Reporte jerárquico de clientes/cuentas/últimos N movimientos por cuenta, límite 0–1000.

## Persistencia y objetos

Siete tablas: seis del dominio original y TBL_SECUENCIAS para el contador de cuentas. Nueve vistas: seis de compatibilidad, SQ_CUENTA y dos de negocio. Tres funciones: saldo, categoría, comisión. Trece procedimientos: log, apertura, depósito, retiro, transferencia, estado, intereses, categorías, reporte, laboratorio, resumen, simulador y estado mensual. Seis triggers: clientes INSERT/UPDATE, cuenta INSERT, movimiento BEFORE/AFTER, cuenta UPDATE. Total: 38 objetos indexados, todos MySQL.

El detalle de equivalencias y limitaciones de lenguaje está en MIGRACION_MYSQL.md. No existen sinónimos, tipos pipelined, bloques anónimos ni transacciones autónomas Oracle en esta versión. Las vistas de compatibilidad son vistas MySQL reales; los antiguos bloques son procedimientos.

## Backend, transacciones y privacidad

mysql-connector-python, pool perezoso, transacción por petición, parámetros separados del SQL. Sesión -05:00, espera de bloqueo cinco segundos. Commit solo tras éxito; rollback por error y en laboratorio/lecturas. Las escrituras no se reintentan; lecturas pueden reintentarse una vez por desconexión. Después del rollback, el servicio puede registrar un error en otra conexión y confirmar solo ese log.

Contrato JSON conservado: ok, mensaje, codigo, datos, objetos_oracle (nombre histórico de compatibilidad). Códigos de negocio negativos -20001 a -20007 en API; errores nativos MySQL traducidos por contexto. SQL del modal solo desde archivos indexados, sin ejecutar texto libre. Configuración privada en mysql.local.json o variables MYSQL_*. El archivo .env de Oracle nunca se carga.

## Instalación, datos y validación

Base destino nueva/vacía, sin borrar datos existentes. La instalación local actual usa demo 6/8/30. Transferir registros actuales de Oracle requiere exportación manual consistente e importación en otra base vacía. Se preservan IDs, saldos, fechas e historial, sin volver a aplicar triggers. Nunca exportar ni consultar contenido AD_. El ZIP excluye credenciales, exportaciones, .env y entorno virtual.

Pruebas unitarias aisladas en tests/mysql; prueba real separada en scripts/verificar_mysql.py con bases temporales propias. La evidencia de la entrega no afirma haber exportado la base Oracle real. Commits y push a cargo del usuario.

Aislamiento de la aplicación: READ COMMITTED. Las lecturas críticas de saldo/estado/categoría de una transferencia son FOR UPDATE; no reutilizan una instantánea antigua de REPEATABLE READ. La rutina fue actualizada en la base local y la prueba real incluye un cambio de estado entre dos conexiones.
