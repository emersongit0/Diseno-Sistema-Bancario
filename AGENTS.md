# Banco MySQL — rama migracion/MySQL

## Autorización actual
El usuario pidió migrar toda la base y aplicación a MySQL, autorizó código/SQL y pruebas con su servidor local. Este encargo sustituye los límites de edición Oracle y la entrega por fases para esta rama. No hacer staging, commit ni push: los realiza el usuario. No tocar digasnostico_UI_EX.md.

## Seguridad y datos
- Nunca leer ni modificar .env. La aplicación MySQL no lo carga. No ejecutar consultas contra Oracle desde el agente. No consultar ni alterar tablas AD_.
- mysql.local.json es configuración privada ignorada por Git. No imprimirlo, copiarlo al entregable ni versionar contraseñas. El usuario proporcionó las credenciales para configurar MySQL local; nunca repetirlas en documentación.
- Base activa: sistema_banco_mysql, servidor local 127.0.0.1:3306. No sobrescribir bases existentes ni ejecutar limpieza amplia. El instalador solo crea en una base nueva/vacía y rechaza datos existentes.
- Los datos actuales de Oracle NO fueron transferidos: la base local se inició con la demostración 6/8/30. Existe exportador manual sin .env y un importador que exige destino vacío. No afirmar conservación de los registros remotos hasta tener y validar esa exportación.

## Implementación actual
Flask, mysql-connector-python, MySQL 8.0.16+ / 9.x, SQL/PSM, InnoDB, UTF-8, soles. Probado realmente con MySQL 9.7.1 y Python 3.13. SQL activo en sql/mysql; Oracle histórico en sql/oracle; documentación original en docs/oracle. Las reglas financieras siguen en funciones/procedimientos/triggers MySQL.

Conexión perezosa por aplicación; transacción explícita; sesión America/Lima por desplazamiento -05:00; innodb_lock_wait_timeout=5. Binds obligatorios. Lecturas reintentan una vez; escrituras nunca. MySQL no tiene transacciones autónomas: Flask revierte primero y registra el error en otra conexión/transacción. Los procedimientos no confirman negocio.

38 objetos indexables: siete tablas (incluye contador), nueve vistas (seis compatibilidad, SQ_CUENTA y dos de negocio), tres funciones, trece procedimientos y seis triggers. IDs comunes usan AUTO_INCREMENT; cuenta conserva saltos de diez con contador transaccional. SQL completo opcional: INSTALAR_MYSQL.sql, solo base nueva. No indexar el SQL combinado ni el auxiliar transitorio de carga.

Mantener diez pantallas y contrato API. objetos_oracle sigue siendo un campo histórico de compatibilidad pero contiene nombres reales MySQL; no se ejecuta PL/SQL. El módulo/índice conservan algunos nombres de archivo históricos para evitar romper enlaces. Catálogo debe coincidir con los 38 objetos MySQL. SELECT/INSERT/UPDATE de la aplicación acceden mediante vistas de compatibilidad, no sinónimos inexistentes.

## Pruebas y entrega
pytest ejecuta tests/mysql, con conexiones/configuración privada bloqueadas. Las pruebas Oracle archivadas en tests/oracle_reference no son la suite activa. scripts/verificar_mysql.py usa bases temporales propias generadas y las retira al finalizar; no modifica la base activa. Incluye caída en tercera inserción, bloqueo acotado, intereses idempotentes e importación de fixture con IDs/historial intactos. QA navegador contra servidor local temporal, sin escrituras bancarias en la base activa.

Entregable generado mediante scripts/empaquetar_mysql.py. Excluir .env, mysql.local.json, .venv, work, exportaciones, .git y diagnósticos personales. Arranque del usuario: iniciar_mysql.ps1 o .venv/Scripts/python.exe run.py. El script de arranque pide contraseña sin eco solo si falta configuración privada.

Aislamiento de la aplicación: READ COMMITTED. Las lecturas críticas de saldo/estado/categoría de una transferencia son FOR UPDATE; no reutilizan una instantánea antigua de REPEATABLE READ. La rutina fue actualizada en la base local y la prueba real incluye un cambio de estado entre dos conexiones.

Entrega MySQL validada: 112 pruebas unitarias correctas, prueba real integral final en MySQL 9.7.1 con reversión al fallar la tercera inserción, espera acotada y estado actualizado pese a instantánea antigua; instalación completa desde SQL único; importación de fixture con IDs/saldos/historial intactos; navegador real en diez pantallas y móvil. La base activa sigue 6 clientes/8 cuentas/30 movimientos demo. No se consultó Oracle ni .env. Paquete por lista permitida y SHA256 en entregables. Sin staging/commit/push.
