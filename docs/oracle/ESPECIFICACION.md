# Prompt — Banco Oracle: Cuentas y Transferencias

## PARTE A. REGLAS DEL AGENTE (se declaran una sola vez)

**A1. Modo de trabajo.** Eres un agente de código que trabaja DIRECTAMENTE en la carpeta(C:\Users\emerson solano perez\Documents\AÑO 3 - 2026\CICLO 6\DISEÑO DE BASE DE DATOS\sistema_banco). CREA y EDITA los archivos tú mismo; no me muestres el código en el chat salvo que te lo pida. Ejecuta los comandos necesarios (venv, pip, pytest, git) pidiendo mi permiso cuando la herramienta lo exija. Cada archivo se escribe completo, sin «...» ni «el resto igual». Si una ambigüedad te bloquea, elige la opción más simple, anótalo en una línea del resumen y sigue.

**A2. Fases y palabras de paso.** Trabaja por fases (Parte C). Al cerrar cada una dame solo un resumen breve: archivos creados o modificados, qué debo ejecutar YO (hoja de trabajo de FreeSQL o terminal) y el resultado esperado. Luego DETENTE. Solo avanzas cuando yo escriba «continúa», que significa «ejecuté lo pedido y el criterio de salida se cumplió». Si algo falla, pegaré el error en lugar de escribir «continúa» y tú lo corriges. Excepción: tras la Fase 0 espera específicamente «privilegios OK».

**A3. Seguridad.**

- Nunca leas, muestres, copies ni subas a Git mi archivo `.env`, y nunca me pidas la contraseña de la base de datos. Yo creo `.env` copiando `.env.example`. En la Fase 0 crea `.claude/settings.json` con reglas de denegación de lectura (`permissions.deny`: `Read(./.env)` y `Read(**/.env)`) y anota en AGENTS.md que, si el agente no es Claude Code, debo configurar el equivalente.
- Nunca ejecutes scripts SQL contra mi base de datos por tu cuenta (salvo la Fase 7 opcional, solo si la pido). Tampoco ejecutes `run.py` ni `probar_conexion.py`: los ejecuto yo.
- pytest NO se conecta a la base de datos: usa mocks y el bloqueo de `conftest.py` (B3.6).
- Mi esquema contiene tablas ajenas (prefijo AD\_). Nunca las leas, modifiques ni borres. La única consulta permitida sobre ellas es la de nombres en USER\_TABLES de `00b_snapshot_ad.sql`.

**A4. Contingencias de privilegios.** Si algún CREATE (TABLE, SEQUENCE, VIEW, SYNONYM, TYPE, FUNCTION, PROCEDURE, TRIGGER) falla por falta de privilegios, DETENTE y avísame con el error exacto. Solo aplica los planes que yo apruebe:

- (a) Sin CREATE TYPE: reemplaza FN\_ESTADO\_CUENTA\_MENSUAL por SP\_ESTADO\_CUENTA\_MENSUAL(IN id\_cuenta, IN anio, IN mes, OUT json CLOB + los OUT estándar), manteniendo el cursor explícito con OPEN/FETCH/CLOSE y armando el JSON con JSON\_ARRAY\_T/JSON\_OBJECT\_T; elimina T\_MOV\_FILA y T\_MOV\_TABLA y actualiza B2.2, la matriz y AGENTS.md.
- (b) Sin CREATE SYNONYM: no improvises; avísame.
- (c) Sin conexión externa viable desde Python (TCPS, wallet, firewall): ver B3.3, Plan B.

**A5. Trazabilidad y memoria.**

- `docs/ESPECIFICACION.md` (este documento) es la fuente de verdad. AL INICIAR cada fase, relee las secciones B que la gobiernan y las filas de la matriz que le corresponden. Nunca la modifiques sin mi permiso.
- En la Fase 0 crea `docs/MATRIZ_OBJETOS.md` (plantilla en B5) y `AGENTS.md` (stack, convenciones, lista cerrada B2.2, reglas de seguridad, palabras de paso y fases completadas). `CLAUDE.md` contiene ÚNICAMENTE la línea `@AGENTS.md`.
- Estados de la matriz: Pendiente → Creado (lo marcas tú al terminar de escribir el archivo) → Verificado. Solo marcas «Verificado» cuando yo escribo «continúa» (o «privilegios OK»), y únicamente en las filas cubiertas por la prueba de la fase cerrada. Jamás lo marques por tu cuenta.
- Al cerrar CADA fase actualiza la matriz y la lista de fases en AGENTS.md.

**A6. Criterio de salida.** Cada fase termina con un criterio de salida verificable (Parte C). No declares la fase cerrada hasta que se cumpla; si algo falla, dime qué y propón la corrección.

**A7. Git.** En la Fase 0 ejecuta `git init`. Antes de cada commit ejecuta `git status` y confirma que `.env` no aparece. Al cerrar cada fase haz un commit «Fase N: descripción» (con mi permiso). Nunca hagas push salvo que yo lo pida.

## PARTE B. ESPECIFICACIÓN DEL PRODUCTO

### B0. Objetivo y temario del curso

Construir la aplicación web «Banco Oracle: Cuentas y Transferencias». Su propósito ESENCIAL es DEMOSTRAR, con pantallas y acciones reales, el desarrollo de objetos y la programación PL/SQL en Oracle Database. Es un trabajo universitario: cada pantalla muestra qué objeto Oracle usa. La lógica de negocio vive en PL/SQL; el backend es una capa delgada.

Temario (el docente usó el esquema HR solo como referencia; aquí se crean tablas propias del sistema bancario):

- Puntos 1 y 2 (complementarios, no se muestran en pantalla): 1 = preparación de la BD y del usuario, que en este proyecto es mi esquema de FreeSQL (`probar_conexion.py` y `00_prueba_privilegios.sql`); 2 = CREATE TABLE, INSERT, SELECT, UPDATE (scripts 01 y 10 y las acciones de alta/edición de clientes).
- Puntos 3 a 16 (se demuestran con acciones en pantalla): 3 Vistas · 4 Secuencias · 5 Sinónimos · 6 Cursores explícitos · 7 Cursores implícitos · 8 Cursores con parámetros y anidados · 9 Bloques anónimos · 10 Variables, constantes, %TYPE y %ROWTYPE · 11 FOR, LOOP y WHILE · 12 IF/ELSIF/ELSE · 13 Procedimientos IN/OUT · 14 Funciones · 15 Triggers BEFORE y AFTER · 16 Excepciones y manejo de errores.

### B1. Entorno

- Base de datos: Oracle FreeSQL (freesql.com), esquema personal en la nube. Me conecto con host, puerto, servicio, usuario y contraseña del panel «Detalles de conexión». Oracle 21c XE NO es opción (mi Windows Home no lo soporta).
- Backend: Python 3.11+ con Flask y python-oracledb en modo THIN. Dependencias (pip, requirements.txt): flask, oracledb, python-dotenv, pytest.
- Frontend: plantillas Jinja2 + HTML + Tailwind CSS (CDN) + JavaScript vanilla (módulos ES, fetch).
- Editor VS Code, Git, Windows Home (comandos en PowerShell). Moneda: soles (S/).

### B2. Base de datos

#### B2.1 Reglas de los scripts SQL

- Un solo esquema (el mío). PROHIBIDO: CREATE USER, ALTER SESSION SET CONTAINER, CONNECT, SYSTEM, GRANT hacia otros usuarios y prefijos de esquema.
- Los pego yo en la hoja de trabajo de FreeSQL y los ejecuto como SCRIPT. Cada bloque PL/SQL (procedimiento, función, trigger, tipo, bloque anónimo) termina con una línea que solo contiene `/`. Un archivo .sql por tema, de tamaño moderado y numerados.
- Re-ejecución: los scripts 04 a 09 usan CREATE OR REPLACE y se pueden repetir. Los scripts 01, 02, 03 y 10 NO se pueden repetir: para rehacerlos ejecuto antes `99_limpiar.sql`, que debe tolerar objetos inexistentes (cada DROP va en un bloque que ignora ORA-00942, -02289, -04043, -01432 y -04080 y re-lanza cualquier otro error).
- Los procedimientos NO hacen COMMIT (lo hace Flask). Usa PL/SQL estándar y clásico.
- Bloqueos: todo `SELECT ... FOR UPDATE` lleva `WAIT 5`, para que una transacción olvidada abierta en mi hoja de trabajo no cuelgue la aplicación (ORA-30006 se mapea a 409, ver B3.4).
- Todo trigger de fila se declara `FOR EACH ROW`.
- MARCADORES (obligatorios): TODO objeto va precedido de la línea `-- @OBJETO: NOMBRE_EXACTO` y seguido de `-- @FIN`, incluidas tablas, secuencias, tipos, vistas, sinónimos, triggers, funciones, procedimientos y los dos bloques anónimos (BLOQUE\_SIMULADOR\_INTERES y BLOQUE\_RESUMEN\_CLIENTE). Así el modal «Ver código PL/SQL» extrae cada objeto por nombre aunque el script agrupe varios.
- Nombra TODAS las restricciones: PK\_, FK\_, UQ\_ y CK\_ (ver B2.3), para poder mapear sus errores a mensajes claros.
- Todo script de pruebas (`sql/smoke/smoke_plsql.sql`) termina cada sección con `ROLLBACK;`, salvo donde se pruebe a propósito el registro en el log.

#### B2.2 Lista cerrada de objetos (única fuente para 99\_limpiar.sql, la whitelist del modal y el test de cobertura)

- Tablas (6): TBL\_CLIENTES, TBL\_CUENTAS, TBL\_MOVIMIENTOS, TBL\_AUDITORIA, TBL\_LOG\_ERRORES, TBL\_LIMITES\_CATEGORIAS.
- Secuencias (5): SQ\_CLIENTE, SQ\_CUENTA, SQ\_MOVIMIENTO, SQ\_AUDITORIA, SQ\_LOG.
- Tipos (2): T\_MOV\_FILA, T\_MOV\_TABLA.
- Vistas (2): V\_ESTADO\_CUENTA, V\_CUENTAS\_RESUMEN.
- Funciones (4): FN\_SALDO\_DISPONIBLE, FN\_CATEGORIA\_CLIENTE, FN\_COMISION, FN\_ESTADO\_CUENTA\_MENSUAL.
- Procedimientos (10): SP\_LOG\_ERROR, SP\_ABRIR\_CUENTA, SP\_DEPOSITAR, SP\_RETIRAR, SP\_TRANSFERIR, SP\_CAMBIAR\_ESTADO\_CUENTA, SP\_APLICAR\_INTERESES, SP\_ACTUALIZAR\_CATEGORIAS, SP\_REPORTE\_CLIENTES, SP\_LAB\_ERRORES.
- Triggers (5): TRG\_CLIENTES\_BI, TRG\_CUENTAS\_BI, TRG\_MOVIMIENTOS\_BI, TRG\_MOVIMIENTOS\_AI, TRG\_CUENTAS\_AU.
- Sinónimos (6): CLIENTES, CUENTAS, MOVIMIENTOS, AUDITORIA, LOG\_ERRORES, LIMITES\_CATEGORIAS.
- Bloques anónimos (2, son archivos y no objetos de la BD): BLOQUE\_SIMULADOR\_INTERES (`sql/bloques/simulador_interes.sql`) y BLOQUE\_RESUMEN\_CLIENTE (`sql/bloques/resumen_cliente.sql`).

Total actual: 40 objetos de BD + 2 bloques = 42 entradas indexables (incluye la ampliación de límites editables solicitada el 24/11/2026). No inventes objetos fuera de esta lista salvo auxiliares justificados que añadas a ella, a la matriz y a AGENTS.md.

#### B2.3 Tablas (script 01)

Todas con PK, FK, CHECK y `COMMENT ON`. Nombres en MAYÚSCULAS y en español. Restricciones con estos nombres exactos:

- TBL\_CLIENTES(ID\_CLIENTE, DNI VARCHAR2(8), NOMBRES, APELLIDOS, EMAIL, CATEGORIA DEFAULT 'BASICO', FECHA\_REGISTRO DEFAULT SYSDATE). PK\_CLIENTES; UQ\_CLIENTES\_DNI; UQ\_CLIENTES\_EMAIL; CK\_CLIENTES\_DNI (`REGEXP_LIKE(DNI, '^[0-9]{8}$')`); CK\_CLIENTES\_CATEGORIA (IN 'BASICO','GOLD','PREMIUM').
- TBL\_CUENTAS(ID\_CUENTA, NRO\_CUENTA, ID\_CLIENTE, TIPO, SALDO NUMBER(14,2) DEFAULT 0, TASA\_INTERES\_ANUAL NUMBER(5,2), ESTADO DEFAULT 'ACTIVA', FECHA\_APERTURA DEFAULT SYSDATE, FECHA\_ULT\_INTERES). PK\_CUENTAS; UQ\_CUENTAS\_NRO; FK\_CUENTAS\_CLIENTE; CK\_CUENTAS\_TIPO (IN 'AHORROS','CORRIENTE'); CK\_CUENTAS\_ESTADO (IN 'ACTIVA','BLOQUEADA'); CK\_CUENTAS\_SALDO (SALDO >= 0).
- TBL\_MOVIMIENTOS(ID\_MOVIMIENTO, ID\_CUENTA, TIPO, MONTO NUMBER(14,2), SALDO\_POSTERIOR NUMBER(14,2), FECHA TIMESTAMP, DESCRIPCION, ID\_CUENTA\_RELACIONADA NULL). PK\_MOVIMIENTOS; FK\_MOV\_CUENTA; FK\_MOV\_CUENTA\_REL; CK\_MOV\_TIPO (IN 'DEPOSITO','RETIRO','TRANSF\_ENVIADA','TRANSF\_RECIBIDA','INTERES','COMISION').
- TBL\_AUDITORIA(ID\_AUDITORIA, TABLA, OPERACION, ID\_REGISTRO, USUARIO\_BD, FECHA, DETALLE VARCHAR2(500)). PK\_AUDITORIA.
- TBL\_LOG\_ERRORES(ID\_LOG, PROCEDIMIENTO, CODIGO, MENSAJE, FECHA). PK\_LOG\_ERRORES. El CHECK de saldo es la última barrera; la validación de negocio ocurre antes, en los procedimientos.

#### B2.4 Secuencias (02) y tipos (03)

- SQ\_CUENTA: START WITH 1000 INCREMENT BY 10 NOCACHE. SQ\_MOVIMIENTO: START WITH 1 INCREMENT BY 1. SQ\_CLIENTE (1, +1). SQ\_AUDITORIA y SQ\_LOG (auxiliares).
- T\_MOV\_FILA (OBJECT: fecha, tipo, descripcion, monto, saldo\_acumulado) y T\_MOV\_TABLA (TABLE OF T\_MOV\_FILA).

#### B2.5 Vistas (04)

- V\_ESTADO\_CUENTA: movimientos unidos con cuenta y cliente (id\_cuenta, nro\_cuenta, cliente completo, tipo, monto, saldo\_posterior, fecha, descripción).
- V\_CUENTAS\_RESUMEN: por cuenta: id, nro\_cuenta, titular, categoría, saldo, estado, cantidad de movimientos, total depositado y total retirado.

#### B2.6 Funciones y utilidad (script 05)

- SP\_LOG\_ERROR(p\_proc, p\_codigo, p\_mensaje) con PRAGMA AUTONOMOUS\_TRANSACTION: registra en TBL\_LOG\_ERRORES aunque el llamador haga ROLLBACK. Va primero.
- FN\_SALDO\_DISPONIBLE(p\_id\_cuenta) RETURN NUMBER: SELECT INTO; NO\_DATA\_FOUND lanza -20002.
- FN\_CATEGORIA\_CLIENTE(p\_saldo\_total) RETURN VARCHAR2 con IF/ELSIF/ELSE: lee los límites vigentes en TBL\_LIMITES\_CATEGORIAS. Menos de LIMITE\_GOLD es BASICO; desde LIMITE\_GOLD hasta antes de LIMITE\_PREMIUM es GOLD; desde LIMITE\_PREMIUM es PREMIUM. Valores iniciales: 5,000 y 50,000.
- FN\_COMISION(p\_monto, p\_categoria DEFAULT 'BASICO') RETURN NUMBER: tasas BASICO 1.5%, GOLD 0.8%, PREMIUM 0.3%. Comisión = ROUND(GREATEST(monto \* tasa, 1.00), 2): mínimo S/ 1.00 para TODAS las categorías y 2 decimales. Monto <= 0 lanza -20004. Usa constantes (CONSTANT) e IF/ELSIF/ELSE. Valores de referencia: (100,'BASICO') = 1.50; (10,'BASICO') = 1.00; (1000,'GOLD') = 8.00; (1000,'PREMIUM') = 3.00.

#### B2.7 Excepciones propias

RAISE\_APPLICATION\_ERROR: -20001 saldo insuficiente · -20002 cuenta inexistente · -20003 cuenta bloqueada · -20004 monto inválido (<= 0) · -20005 transferencia a la misma cuenta · -20006 cliente inexistente · -20007 estado de cuenta inválido (auxiliar, lo usa SP\_CAMBIAR\_ESTADO\_CUENTA). Usa PRAGMA EXCEPTION\_INIT donde convenga, incluido ORA-30006 (tiempo de espera de bloqueo).

#### B2.8 Triggers (script 06)

- TRG\_CLIENTES\_BI (BEFORE INSERT OR UPDATE OF NOMBRES, APELLIDOS, FOR EACH ROW): pasa nombres y apellidos a MAYÚSCULAS; asigna ID con SQ\_CLIENTE si viene nulo.
- TRG\_CUENTAS\_BI (BEFORE INSERT): UN solo NEXTVAL de SQ\_CUENTA guardado en una variable v\_id; de ahí salen ID\_CUENTA = v\_id y NRO\_CUENTA = '191-' || LPAD(v\_id, 8, '0').
- TRG\_MOVIMIENTOS\_BI (BEFORE INSERT): valida MONTO > 0 (si no, -20004), asigna ID con SQ\_MOVIMIENTO, fecha actual y SALDO\_POSTERIOR = saldo vigente de TBL\_CUENTAS más o menos el monto según el tipo. Comenta que el saldo vigente ya incluye el efecto del movimiento anterior porque TRG\_MOVIMIENTOS\_AI se ejecuta al terminar cada INSERT (por eso la COMISION de una transferencia ve el saldo ya descontado de TRANSF\_ENVIADA).
- TRG\_MOVIMIENTOS\_AI (AFTER INSERT): actualiza TBL\_CUENTAS.SALDO (suma en DEPOSITO, TRANSF\_RECIBIDA, INTERES; resta en RETIRO, TRANSF\_ENVIADA, COMISION) y escribe en TBL\_AUDITORIA.
- TRG\_CUENTAS\_AU (AFTER UPDATE OF ESTADO): audita bloqueos y desbloqueos. No se dispara al cambiar el saldo ni FECHA\_ULT\_INTERES. REGLA CLAVE: el saldo SOLO lo modifica TRG\_MOVIMIENTOS\_AI; los procedimientos únicamente insertan movimientos. Comenta por qué esto evita el error de tabla mutante (los triggers sobre TBL\_MOVIMIENTOS solo modifican o leen otra tabla, TBL\_CUENTAS) y la doble actualización del saldo.

#### B2.9 Procedimientos (script 07)

CONVENCIÓN: todos los procedimientos de negocio (todos menos SP\_LOG\_ERROR) terminan con los parámetros OUT p\_estado ('OK'/'ERROR'), p\_codigo (0 si OK; SQLCODE si error) y p\_mensaje. Abajo solo se listan los parámetros propios. Usan SAVEPOINT; capturan con WHEN específicos y WHEN OTHERS; ante error hacen ROLLBACK TO SAVEPOINT, llaman a SP\_LOG\_ERROR y devuelven estado, código y mensaje. No hacen COMMIT.

ORDEN DE VALIDACIÓN de los procedimientos que mueven dinero (cada paso lanza su código): (1) monto > 0, si no -20004; (2) la cuenta existe, si no -20002, y se bloquea con `SELECT ... FOR UPDATE WAIT 5` ANTES de insertar el movimiento (así el UPDATE del trigger nunca queda esperando); (3) ESTADO = 'ACTIVA', si no -20003; (4) solo en retiros, saldo >= monto con FN\_SALDO\_DISPONIBLE, si no -20001. Un ORA-30006 se captura y se devuelve como p\_codigo -30006.

- SP\_ABRIR\_CUENTA(IN id\_cliente, IN tipo, IN saldo\_inicial DEFAULT 0, IN tasa DEFAULT NULL, OUT id\_cuenta, OUT nro\_cuenta). Saldo inicial < 0 es -20004; cliente inexistente es -20006. Tasa por defecto según tipo: AHORROS 3.00, CORRIENTE 0.50. Saldo inicial > 0 se registra como DEPOSITO. Un tipo inválido lo rechaza CK\_CUENTAS\_TIPO.
- SP\_DEPOSITAR(IN id\_cuenta, IN monto): pasos 1 a 3 del orden de validación.
- SP\_RETIRAR(IN id\_cuenta, IN monto): pasos 1 a 4.
- SP\_TRANSFERIR(IN origen, IN destino, IN monto): monto (-20004); origen distinto de destino (-20005); bloquea ambas cuentas con un solo `SELECT ... ORDER BY ID_CUENTA FOR UPDATE WAIT 5` (evita deadlocks; si no encuentra las dos, -20002); ambas ACTIVA (-20003); saldo >= monto + comisión (-20001), con FN\_COMISION según la categoría del titular del origen. Inserta TRANSF\_ENVIADA (monto) y COMISION en el origen y TRANSF\_RECIBIDA (monto) en el destino. El mensaje informa la comisión cobrada.
- SP\_CAMBIAR\_ESTADO\_CUENTA(IN id\_cuenta, IN nuevo\_estado): cuenta inexistente (-20002), bloqueo con WAIT 5, estado distinto de ACTIVA/BLOQUEADA (-20007).
- SP\_APLICAR\_INTERESES(IN p\_mes\_ref DATE DEFAULT SYSDATE, OUT n\_cuentas, OUT n\_omitidas): cuenta ELEGIBLE = ACTIVA, tasa > 0, saldo > 0 y sin interés aplicado en el mes de referencia (FECHA\_ULT\_INTERES IS NULL o menor que TRUNC(p\_mes\_ref,'MM')). Un FOR loop inserta un movimiento INTERES = ROUND(saldo \* tasa / 100 / 12, 2) por cada cuenta elegible. Luego un UPDATE masivo con el mismo criterio fija FECHA\_ULT\_INTERES = TRUNC(p\_mes\_ref,'MM'); n\_cuentas = SQL%ROWCOUNT de ese UPDATE (solo cuentas que recibieron interés) y se evalúa SQL%FOUND (cursor implícito). n\_omitidas = activas no elegibles. Mensaje: «Se actualizaron N cuentas (M omitidas)». Aplicarlo dos veces en el mismo mes NO duplica intereses (el parámetro permite simular meses distintos en la demo).
- SP\_ACTUALIZAR\_CATEGORIAS(OUT n\_procesados, OUT n\_cambios): recorre clientes con LOOP / EXIT WHEN, suma los saldos de sus cuentas, calcula la categoría con FN\_CATEGORIA\_CLIENTE y hace UPDATE solo si cambia.
- SP\_REPORTE\_CLIENTES(IN p\_id\_cliente DEFAULT NULL, IN p\_limite\_movs DEFAULT 5, OUT json CLOB): CURSORES ANIDADOS Y CON PARÁMETROS: cursor de clientes, c\_cuentas(p\_cli) y c\_movs(p\_cta, p\_limite) con p\_limite\_movs como límite. Construye la jerarquía con JSON\_OBJECT\_T / JSON\_ARRAY\_T.
- SP\_LAB\_ERRORES(IN p\_caso, OUT p\_detalle): casos NO\_DATA\_FOUND, TOO\_MANY\_ROWS, DUP\_VAL\_ON\_INDEX (usa SAVEPOINT, intenta insertar un cliente con un DNI ya existente y hace ROLLBACK TO), ZERO\_DIVIDE, VALUE\_ERROR, WHEN\_OTHERS (provoca p. ej. TO\_NUMBER('abc') y lo atrapa el handler genérico) y RERAISE (bloque interno que captura, registra con SP\_LOG\_ERROR y vuelve a lanzar con RAISE; el externo lo atrapa). Cada caso captura con su handler específico y devuelve SQLCODE y SQLERRM en p\_detalle; p\_estado es 'OK' cuando la excepción esperada fue capturada. No deja cambios persistentes (salvo el registro del log).

#### B2.10 Función pipelined con cursor explícito (script 08)

FN\_ESTADO\_CUENTA\_MENSUAL(p\_id\_cuenta, p\_anio, p\_mes) RETURN T\_MOV\_TABLA PIPELINED: DECLARA el cursor y usa OPEN / FETCH / CLOSE explícitos (con %NOTFOUND o EXIT WHEN), acumula el saldo con variables %TYPE y devuelve cada fila con PIPE ROW. Flask la consume con `SELECT * FROM TABLE(FN_ESTADO_CUENTA_MENSUAL(:id, :anio, :mes))`.

#### B2.11 Bloques anónimos (sql/bloques/)

DECLARE ... BEGIN ... EXCEPTION ... END, ejecutados por Flask con variables BIND (nunca concatenar texto). Solo se ejecutan estos dos archivos (whitelist); jamás texto libre del usuario. Cada archivo termina en `/` (para pegarlo en FreeSQL); el servicio quita los marcadores y esa línea final antes de ejecutarlo.

- BLOQUE\_SIMULADOR\_INTERES: binds de entrada: saldo inicial, tasa anual, meses (máx. 600), aporte mensual, meta e id\_cuenta OPCIONAL. Si viene id\_cuenta, lee la cuenta con una variable %ROWTYPE de TBL\_CUENTAS y usa su saldo y tasa (cuenta inexistente: estado ERROR con código -20002). Usa constantes y %TYPE, un FOR para la proyección mes a mes y un WHILE con tope (v\_mes < c\_max\_meses) para calcular en cuántos meses se alcanza la meta; si no se alcanza, devuelve NULL con un mensaje claro. Sin DML. Devuelve por OUT: saldo final, meses a la meta, proyección en JSON (CLOB), estado y mensaje.
- BLOQUE\_RESUMEN\_CLIENTE: bind id\_cliente. Usa una variable %ROWTYPE de TBL\_CLIENTES, suma el saldo total con %TYPE e IF/ELSIF/ELSE para el nivel del cliente (incluye cuánto falta para la siguiente categoría). Devuelve el resumen en JSON (CLOB), estado y mensaje.
- PRUEBA EN FREESQL: los binds (sobre todo OUT y CLOB) pueden no funcionar al pegar el bloque tal cual en la hoja de trabajo. Por eso la sección F2B de `smoke_plsql.sql` incluye, para cada bloque, una VERSIÓN DE PRUEBA derivada mecánicamente del archivo: los binds se sustituyen por variables locales con valores de ejemplo y el resultado se imprime con DBMS\_OUTPUT. La prueba real con binds se hace desde Flask en la Fase 4.

#### B2.12 Sinónimos (script 09)

CLIENTES a TBL\_CLIENTES, CUENTAS a TBL\_CUENTAS, MOVIMIENTOS a TBL\_MOVIMIENTOS, AUDITORIA a TBL\_AUDITORIA, LOG\_ERRORES a TBL\_LOG\_ERRORES, todos en mi mismo esquema. Los objetos de la BD (triggers, vistas, procedimientos, funciones) referencian los nombres TBL\_ directamente. Flask usa SOLO los sinónimos para tablas (lecturas y DML directo) y los nombres reales para vistas, procedimientos y funciones; ningún .py, .js ni .html de la aplicación menciona «TBL\_».

#### B2.13 Datos de prueba, limpieza y snapshot

- 10\_datos\_prueba.sql (se ejecuta una sola vez tras una limpieza): inserta clientes directamente y todo lo demás con los procedimientos (para que los triggers corran): 6 clientes, 8 cuentas, unos 30 movimientos que den las 3 categorías, y COMMIT al final.
- 99\_limpiar.sql: elimina SOLO los objetos de B2.2, nombrándolos uno por uno, en orden inverso de dependencias (sinónimos, triggers, procedimientos, funciones, vistas, tablas hijas, tablas padre, tipos T\_MOV\_TABLA y luego T\_MOV\_FILA, secuencias). Jamás un bucle que borre «todo lo del usuario». Usa un procedimiento local dentro de un único bloque anónimo que recibe cada sentencia DROP literal y tolera los errores indicados en B2.1.
- 00b\_snapshot\_ad.sql: dos consultas sobre USER\_TABLES con `table_name LIKE 'AD!_%' ESCAPE '!'`: el total y la lista de nombres con ORDER BY table\_name. Yo guardo la salida en docs/snapshot\_ad\_antes.txt (Fase 0) y docs/snapshot\_ad\_despues.txt (Fase 3). Limitación declarada: compara nombres y cantidad, no el contenido de las filas (leerlas está prohibido).

### B3. Backend

#### B3.1 Estructura

```
banco-oracle/
├── AGENTS.md · CLAUDE.md (solo «@AGENTS.md») · .claude/settings.json · .env.example · .gitignore (.env, .venv, __pycache__) · requirements.txt · run.py · probar_conexion.py · README.md
├── docs/ (ESPECIFICACION.md, MATRIZ_OBJETOS.md, snapshot_ad_antes.txt, snapshot_ad_despues.txt)
├── sql/ (00_prueba_privilegios, 00b_snapshot_ad, 01_tablas, 02_secuencias, 03_tipos, 04_vistas, 05_funciones, 06_triggers, 07_procedimientos, 08_funcion_pipelined, 09_sinonimos, 10_datos_prueba, 99_limpiar, bloques/, smoke/smoke_plsql.sql)
├── app/
│   ├── __init__.py (create_app, blueprints) · config.py (lee el .env desde BANCO_ENV_FILE o, si no existe, ./.env)
│   ├── db/pool.py
│   ├── repositories/ cliente_repo, cuenta_repo, movimiento_repo, reporte_repo, auditoria_repo (aquí SOLO se llama a Oracle)
│   ├── services/ banca_service, reporte_service, simulador_service, laboratorio_service
│   ├── routes/ paginas.py (HTML) y api_*.py (JSON)
│   ├── utils/ errores.py, json_provider.py (Decimal y fechas), codigo_plsql.py
│   ├── templates/ (base.html + una por pantalla) · static/ (js/ un módulo por pantalla + api.js, css/)
└── tests/ conftest.py, test_humo.py, test_api.py, test_errores.py, test_reintentos.py, test_sin_tbl.py, test_codigo_indice.py, comparar_snapshots.py
```

Hay una sola carpeta de pruebas Python (`tests/`) y una sola de pruebas SQL (`sql/smoke/`).

#### B3.2 Reglas de código

- Código limpio: funciones cortas de una sola responsabilidad, nombres en español, type hints, docstrings breves, cero SQL/PL/SQL dentro de rutas y servicios (solo en repositories y archivos .sql). Logging con el módulo logging (sin print).
- python-oracledb thin; una conexión por request con context manager; `callproc`/`callfunc` con `cursor.var()` para los OUT (CLOB: DB\_TYPE\_CLOB y `.read()`). Solo binds. `call_timeout` de 15000 ms en cada conexión, para que ninguna llamada se quede colgada.
- Transacciones: el servicio hace commit si p\_estado == 'OK'; rollback en caso contrario o ante excepción. El servicio del laboratorio hace SIEMPRE rollback.
- Toda respuesta JSON: `{ok, mensaje, codigo, datos, objetos_oracle}`; `objetos_oracle` lista los objetos usados (ej. \["SP\_TRANSFERIR","FN\_COMISION","TRG\_MOVIMIENTOS\_AI"\]). Cuando se lee una tabla, se lista el sinónimo, no el nombre TBL\_.
- Reintento: UNA sola vez y SOLO en operaciones de lectura (GET, /api/salud, simulador). Los POST/PUT que escriben NUNCA se reintentan (podrían duplicar una operación ya confirmada).
- Las credenciales jamás se imprimen en logs ni se envían al frontend.

#### B3.3 Conexión y Plan B

- `.env`: DB\_USER, DB\_PASSWORD, DB\_DSN (formato host:puerto/servicio, o el DSN completo o `tcps://` que muestre el panel), POOL\_MIN=1, POOL\_MAX=3 y, SOLO si FreeSQL lo exige, DB\_WALLET\_DIR y DB\_WALLET\_PASSWORD. `pool.py` Y `probar_conexion.py` usan los parámetros de wallet únicamente si están definidos. `ping_interval=60`.
- Si en la Fase 0 la conexión desde Python no es viable (TCPS o wallet inviable, puerto bloqueado), DETENTE y avísame. Plan B (solo si yo lo pido): Oracle Database Free en Docker con WSL2, servicio FREEPDB1, con un script aparte para crear el usuario local; el proyecto solo cambia el `.env`.

#### B3.4 Mapeo de errores (errores.py; vale para excepciones de oracledb y para el p\_codigo de los procedimientos)

| Código (SQLCODE) | HTTP | Mensaje |
| --- | --- | --- |
| -20001 | 409 | Saldo insuficiente |
| -20002 | 404 | Cuenta inexistente |
| -20003 | 409 | Cuenta bloqueada |
| -20004 | 400 | Monto inválido |
| -20005 | 400 | No se puede transferir a la misma cuenta |
| -20006 | 404 | Cliente inexistente |
| -20007 | 400 | Estado de cuenta inválido |
| -1 (ORA-00001) | 409 | Duplicado; por restricción: UQ\_CLIENTES\_DNI = «DNI ya registrado», UQ\_CLIENTES\_EMAIL = «Email ya registrado», otra = «Registro duplicado» |
| -2291 (ORA-02291) | 400 | Referencia inexistente (cliente o cuenta no existe) |
| -2292 (ORA-02292) | 409 | Tiene registros relacionados |
| -2290 (ORA-02290) | 400 | Restricción violada; por restricción: CK\_CLIENTES\_DNI = «El DNI debe tener 8 dígitos», CK\_CUENTAS\_SALDO = «La operación dejaría saldo negativo», CK\_CUENTAS\_TIPO = «Tipo de cuenta inválido», otra = «Restricción violada» |
| -1400, -1438, -12899, -1722 | 400 | Dato faltante o con formato o tamaño inválido |
| -60 (ORA-00060) | 409 | Conflicto de concurrencia, intenta de nuevo |
| -30006 (ORA-30006) | 409 | Cuenta ocupada por otra operación, intenta de nuevo |
| conexión (DPY-4011, DPY-6005, ORA-03113, ORA-03114) antes de ejecutar, o en una lectura | 503 | No se pudo conectar a la base de datos, revisa tu internet |
| la misma caída DURANTE una escritura o su commit | 503 | No se pudo confirmar la operación; revisa el estado de cuenta antes de repetirla |
| cualquier otro | 500 | Error interno (detalle solo en el log) |

Reglas de mensaje: (1) para los códigos de negocio (-20001 a -20007) el texto que se muestra es el `p_mensaje` del procedimiento (ya trae contexto, como la comisión), y errores.py aporta el HTTP; (2) para errores de oracledb y WHEN OTHERS manda el texto de la tabla; (3) SQLERRM nunca llega al frontend, salvo en el Laboratorio, donde se muestra tal cual pero con el nombre del esquema oculto (sustituye `(ESQUEMA.RESTRICCION)` por `(RESTRICCION)`); (4) el nombre de la restricción se extrae del SQLERRM con una expresión regular que toma el segundo grupo de `\(([^.]+)\.([^)]+)\)`.

#### B3.5 Endpoints (con su fuente Oracle)

- GET /api/salud: SELECT 1 FROM dual.
- Clientes: GET /api/clientes (sinónimo CLIENTES) · POST /api/clientes (INSERT en CLIENTES; dispara TRG\_CLIENTES\_BI) · PUT /api/clientes/\<id> (UPDATE en CLIENTES: nombres, apellidos, email) · GET /api/clientes/\<id>/resumen (BLOQUE\_RESUMEN\_CLIENTE) · GET /api/categoria?saldo= (FN\_CATEGORIA\_CLIENTE).
- Cuentas: GET /api/cuentas (vista V\_CUENTAS\_RESUMEN) · GET /api/cuentas/opciones (sinónimo CUENTAS: id, nro, estado, saldo; para los selectores) · POST /api/cuentas (SP\_ABRIR\_CUENTA) · POST /api/cuentas/\<id>/estado (SP\_CAMBIAR\_ESTADO\_CUENTA) · GET /api/cuentas/\<id>/saldo (FN\_SALDO\_DISPONIBLE) · GET /api/cuentas/\<id>/movimientos?limite=20 (sinónimo MOVIMIENTOS) · GET /api/cuentas/\<id>/historial (vista V\_ESTADO\_CUENTA).
- Operaciones: POST /api/depositar, /api/retirar, /api/transferir (SP\_DEPOSITAR, SP\_RETIRAR, SP\_TRANSFERIR) · GET /api/comision?monto=&id\_cuenta= (FN\_COMISION con la categoría del titular, consultada con los sinónimos CUENTAS y CLIENTES; devuelve comisión y total a debitar).
- Reportes: GET /api/estado-cuenta/\<id>?anio=&mes= (FN\_ESTADO\_CUENTA\_MENSUAL) · GET /api/reporte/clientes?id\_cliente=&limite\_movs=5 (SP\_REPORTE\_CLIENTES).
- Intereses y categorías: POST /api/intereses/aplicar (`mes_ref` opcional con formato `YYYY-MM`, que el servicio convierte al primer día del mes; SP\_APLICAR\_INTERESES) · POST /api/categorias/actualizar (SP\_ACTUALIZAR\_CATEGORIAS) · POST /api/simulador (BLOQUE\_SIMULADOR\_INTERES).
- Auditoría: GET /api/auditoria (sinónimo AUDITORIA) · GET /api/errores (sinónimo LOG\_ERRORES).
- Laboratorio: POST /api/laboratorio/\<caso>. Casos estándar (no\_data\_found, too\_many\_rows, dup\_val\_on\_index, zero\_divide, value\_error, when\_others, reraise): SP\_LAB\_ERRORES. Casos propios, que llaman a los procedimientos reales con datos inválidos sobre la primera cuenta ACTIVA que devuelva el sinónimo CUENTAS (si no hay ninguna, mensaje «Crea una cuenta primero») y siempre terminan en rollback: saldo\_insuficiente (SP\_RETIRAR con un monto enorme), cuenta\_inexistente (SP\_DEPOSITAR con id -1 y monto válido), cuenta\_bloqueada (bloquea con SP\_CAMBIAR\_ESTADO\_CUENTA, intenta SP\_DEPOSITAR y hace rollback), monto\_invalido (SP\_DEPOSITAR con monto negativo), misma\_cuenta (SP\_TRANSFERIR con origen = destino), cliente\_inexistente (SP\_ABRIR\_CUENTA con cliente -1) y estado\_invalido (SP\_CAMBIAR\_ESTADO\_CUENTA con 'CERRADA'). La respuesta incluye código, SQLERRM (con esquema oculto) y HTTP que correspondería.
- GET /api/codigo/\<objeto>: `codigo_plsql.py` indexa al arrancar, por los marcadores `-- @OBJETO`, los archivos `sql/*.sql` (excepto `00*`, `10_datos_prueba`, `99_limpiar` y `smoke/`) y `sql/bloques/`. La whitelist son los nombres encontrados (sin rutas del usuario, sin USER\_SOURCE). Devuelve `{objeto, tipo, archivo, codigo}` y funciona igual para tablas, vistas, secuencias, sinónimos, tipos, triggers, funciones, procedimientos y bloques. Nombre desconocido: 404.

#### B3.6 Pruebas Python (pytest, siempre sin base de datos)

- `conftest.py`: fixture autouse que reemplaza `oracledb.connect`, `oracledb.create_pool` y `oracledb.connect_async` por funciones que lanzan un error; así ninguna prueba puede tocar la base. Los repositorios se simulan con monkeypatch.
- `test_humo.py` (Fase 0): importa pytest y comprueba algo trivial, para que la suite exista desde la Fase 0.
- `test_errores.py`: una prueba por cada fila de B3.4, incluidas las dos variantes de 503 y la extracción del nombre de restricción.
- `test_reintentos.py`: las lecturas se reintentan UNA vez; ningún POST/PUT se reintenta; una caída durante escritura devuelve el 503 de «No se pudo confirmar la operación».
- `test_sin_tbl.py`: falla si «TBL\_» aparece en cualquier .py, .js o .html dentro de `app/`, `run.py` o `probar_conexion.py`. Construye el patrón como `'TB' + 'L_'` y no escanea la carpeta `tests/`, para no encontrarse a sí mismo.
- `test_codigo_indice.py`: verifica que `codigo_plsql.py` indexa las 42 entradas de B2.2 (lee solo archivos .sql; no usa base de datos) y que un nombre desconocido da 404.
- `test_api.py`: contrato de cada endpoint de B3.5 con servicios simulados (forma `{ok, mensaje, codigo, datos, objetos_oracle}`).
- `comparar_snapshots.py` es un script (no se recolecta como prueba): normaliza espacios y fin de línea de docs/snapshot\_ad\_antes.txt y docs/snapshot\_ad\_despues.txt y avisa si difieren.

### B4. Frontend

- Tailwind: barra lateral, tarjetas, tablas, modales y toasts verdes/rojas; responsive. JavaScript vanilla con módulos ES, un módulo por pantalla y `api.js` común para fetch con manejo de errores.
- En CADA pantalla: panel «Objetos Oracle usados» (chips con el campo objetos\_oracle de la respuesta) y botón «Ver código PL/SQL» que abre un modal con el código de cada objeto vía /api/codigo/\<objeto>. Es obligatorio: es lo que se muestra al docente.
- Pantallas: 1 Dashboard (V\_CUENTAS\_RESUMEN + indicador verde/rojo «Base de datos conectada» vía /api/salud) · 2 Clientes (alta, edición y botón «Ver resumen» con BLOQUE\_RESUMEN\_CLIENTE) · 3 Cuentas (apertura con SQ\_CUENTA, bloqueo/desbloqueo, lista y botón «Ver historial» que abre un modal con dos pestañas: «Historial» con V\_ESTADO\_CUENTA y «Últimos movimientos» con el sinónimo MOVIMIENTOS) · 4 Operaciones (depósito, retiro, transferencia; al elegir cuenta muestra el saldo disponible y, mientras se escribe el monto, la comisión en vivo con debounce de 300 ms vía /api/comision y el total a debitar) · 5 Estado de cuenta mensual (cursor explícito) · 6 Reporte jerárquico (árbol cliente, cuentas y movimientos; control del límite de movimientos) · 7 Intereses y categorías (selector de mes, aplicar con mensaje «Se actualizaron N cuentas (M omitidas)», actualizar categorías, consulta de categoría por saldo) · 8 Simulador (bloque anónimo, cuenta opcional) · 9 Auditoría y log de errores · 10 Laboratorio de errores (un botón por caso; muestra código, mensaje y HTTP devueltos).

### B5. Matriz (plantilla de docs/MATRIZ\_OBJETOS.md; la creas en la Fase 0 con TODAS las filas en «Pendiente»)

Columnas: Punto | Objeto | Archivo SQL | Pantalla | Endpoint | Prueba | Estado. La columna Prueba cierra la cadena requisito, objeto, pantalla, endpoint y prueba: indica la sección del smoke (F1, F2A, F2B, F3) o el test de pytest que lo verifica. Filas mínimas:

- 3 Vistas: V\_CUENTAS\_RESUMEN (Dashboard y Cuentas) y V\_ESTADO\_CUENTA (modal «Ver historial» de Cuentas).
- 4 Secuencias: SQ\_CUENTA (apertura de cuentas) y SQ\_MOVIMIENTO (operaciones).
- 5 Sinónimos: los cinco (listados, selectores y DML de clientes).
- 6 Cursor explícito: FN\_ESTADO\_CUENTA\_MENSUAL (Estado de cuenta mensual).
- 7 Cursor implícito: SQL%FOUND y SQL%ROWCOUNT en SP\_APLICAR\_INTERESES (Intereses).
- 8 Cursores con parámetros y anidados: SP\_REPORTE\_CLIENTES (Reporte jerárquico).
- 9 Bloques anónimos: BLOQUE\_SIMULADOR\_INTERES (Simulador) y BLOQUE\_RESUMEN\_CLIENTE (Clientes).
- 10 Variables, constantes, %TYPE y %ROWTYPE: constantes y %TYPE en el simulador; %ROWTYPE de TBL\_CUENTAS en el simulador y de TBL\_CLIENTES en el resumen.
- 11 FOR, LOOP, WHILE: FOR en SP\_APLICAR\_INTERESES y en el simulador; LOOP en SP\_ACTUALIZAR\_CATEGORIAS; WHILE en el simulador.
- 12 IF/ELSIF/ELSE: FN\_CATEGORIA\_CLIENTE, FN\_COMISION y el nivel de BLOQUE\_RESUMEN\_CLIENTE.
- 13 Procedimientos IN/OUT: los de Operaciones y Cuentas.
- 14 Funciones: FN\_SALDO\_DISPONIBLE y FN\_COMISION (comisión en vivo).
- 15 Triggers BEFORE/AFTER: los cinco triggers.
- 16 Excepciones: SP\_LAB\_ERRORES, SP\_LOG\_ERROR y las excepciones -20001 a -20007 (Laboratorio de errores). Añade filas con el archivo, la pantalla y el endpoint exactos conforme avances.

## PARTE C. FASES CON CRITERIO DE SALIDA

**Fase 0 (verificación y base).** Crea: estructura de carpetas; `git init`; entorno virtual y dependencias; requirements.txt; .gitignore; .env.example (DB\_USER, DB\_PASSWORD, DB\_DSN, POOL\_MIN, POOL\_MAX y, comentados, DB\_WALLET\_DIR y DB\_WALLET\_PASSWORD); `.claude/settings.json` (A3); AGENTS.md y CLAUDE.md (A5); docs/MATRIZ\_OBJETOS.md (plantilla B5); `tests/conftest.py` y `tests/test_humo.py` (B3.6); `probar_conexion.py` (usa config.py o la misma lógica de lectura del .env, con soporte de wallet opcional; ejecuta SELECT USER FROM dual); `sql/00_prueba_privilegios.sql` (crea y elimina objetos de prueba: tabla, secuencia, vista, sinónimo sobre mi propia tabla, tipo, procedimiento y trigger, y consulta USER\_OBJECTS; incluye una consulta que verifique que ningún nombre de B2.2 existe ya en mi esquema) y `sql/00b_snapshot_ad.sql`. Si docs/ESPECIFICACION.md no existe, DETENTE y pídemelo. Salida: `pytest` pasa (1 prueba, test\_humo); `git status` no muestra `.env`; yo confirmo que probar\_conexion.py imprime mi usuario, que 00\_prueba\_privilegios.sql corrió sin errores, que ningún nombre de B2.2 existe ya y que guardé docs/snapshot\_ad\_antes.txt. Espera «privilegios OK».

**Fase 1.** Scripts 01 a 03 y la sección F1 de `sql/smoke/smoke_plsql.sql`. Salida: ejecutada F1, USER\_OBJECTS muestra 5 tablas, 5 secuencias y 2 tipos en estado VALID, y USER\_ERRORS no devuelve filas.

**Fase 2A.** Scripts 04 a 06 (vistas, funciones con SP\_LOG\_ERROR, triggers) y la sección F2A. Salida: vistas, funciones, SP\_LOG\_ERROR y triggers en estado VALID; USER\_ERRORS vacío; FN\_COMISION devuelve los valores de referencia de B2.6 (1.50, 1.00, 8.00 y 3.00); FN\_CATEGORIA\_CLIENTE devuelve BASICO para 4999.99, GOLD para 5000 y PREMIUM para 50000; F2A termina en ROLLBACK.

**Fase 2B.** Scripts 07 y 08, bloques de `sql/bloques/` y la sección F2B. Salida: los 9 procedimientos del script 07 (10 con SP\_LOG\_ERROR) y la función pipelined en estado VALID; USER\_ERRORS vacío; las versiones de prueba de los dos bloques (B2.11) se ejecutan en la hoja de trabajo y muestran su resultado con DBMS\_OUTPUT.

**Fase 3.** Scripts 09, 10 y 99 y la sección F3. Yo vuelvo a ejecutar `00b_snapshot_ad.sql` y guardo docs/snapshot\_ad\_despues.txt. Salida: los 5 sinónimos existen y responden a un SELECT; los datos de prueba dan 6 clientes, 8 cuentas y los movimientos; una transferencia de prueba (seguida de ROLLBACK) genera 3 movimientos con saldos coherentes y deja auditoría; las 7 excepciones propias devuelven su código; un error queda registrado en TBL\_LOG\_ERRORES tras el ROLLBACK; `python tests/comparar_snapshots.py` confirma que los dos snapshots son idénticos.

**Fase 4.** Backend completo (config, pool, repositories, services, routes, utils, run.py) y las pruebas de B3.6. Salida: pytest pasa sin conexión a la base de datos, incluidas las pruebas de mapeo de errores (cada fila de B3.4), la de que ninguna escritura se reintenta, test\_sin\_tbl.py y test\_codigo\_indice.py; YO ejecuto `python run.py` y confirmo que /api/salud, /api/clientes/\<id>/resumen y POST /api/simulador responden con mi .env real (primera prueba real de los binds de los bloques).

**Fase 5.** Frontend completo (base.html, plantillas, módulos JS, panel de objetos, modal de código). Salida: las 10 pantallas cargan, cada una muestra su panel de objetos y su modal de código, y yo pruebo manualmente una operación completa por pantalla.

**Fase 6.** README (instalación paso a paso, orden de scripts, cómo obtener los datos de conexión de FreeSQL, guion de demostración punto por punto y sección «Respaldo» para recrear todo si pierdo el esquema o cambio de cuenta) y cierre de docs/MATRIZ\_OBJETOS.md. Salida: TODAS las filas de la matriz en «Verificado» (según A5); `git ls-files` no lista `.env`; el estado actual de USER\_TABLES AD\_ sigue coincidiendo con docs/snapshot\_ad\_antes.txt.

**Fase 7 (OPCIONAL, solo si la pido).** `ejecutar_sql.py`: lee el .env y ejecuta los .sql en orden numérico contra FreeSQL con python-oracledb. Separa las sentencias DDL terminadas en `;` y los bloques PL/SQL terminados por una línea `/`; pide confirmación antes de ejecutar y se niega a correr `99_limpiar.sql` salvo con el argumento `--limpiar`. Salida: ejecuta sql/01 a 03 sobre un esquema limpio sin errores.

## CRITERIOS DE ACEPTACIÓN (con su verificación)

| Criterio | Verificación |
| --- | --- |
| Flask se conecta a FreeSQL y el Dashboard muestra «Base de datos conectada» | Fase 0 (probar\_conexion.py) y Fase 4 (/api/salud) |
| Ningún código del backend o frontend usa nombres TBL\_ | test\_sin\_tbl.py (Fase 4) |
| Transferencia exitosa: 3 movimientos, saldos por trigger y auditoría | smoke F3 y prueba manual en Fase 5 |
| Cada excepción propia (-20001 a -20007) se provoca desde la interfaz con mensaje claro | smoke F3, Laboratorio (Fase 5) y test\_errores.py |
| Un error se registra en TBL\_LOG\_ERRORES aunque haya ROLLBACK | smoke F3 |
| Los puntos 3 a 16 se demuestran con una acción visible y su código | docs/MATRIZ\_OBJETOS.md todo «Verificado» (Fase 6) |
| El modal de código cubre las 42 entradas de B2.2 | test\_codigo\_indice.py (Fase 4) |
| Las tablas AD\_ quedan intactas (nombres y cantidad) | comparar\_snapshots.py (Fase 3) y revisión en Fase 6 |
| pytest pasa sin conexión a la base de datos | conftest.py y Fase 4 |
| Ninguna operación de escritura se reintenta | test\_reintentos.py (Fase 4) |
| Cero credenciales en el código; .env fuera de Git y sin permiso de lectura para el agente | `git ls-files`, `.claude/settings.json` y revisión en Fase 6 |

Empieza ahora con la Fase 0.


### Ampliación autorizada: límites de categorías editables (24/11/2026)

El usuario solicita editar los límites de saldo y retirar la revisión/recalcular incorporada en UI. Se conserva el botón original Actualizar categorías, que llama SP_ACTUALIZAR_CATEGORIAS. Guardar límites no actualiza clientes automáticamente.

- Tabla TBL_LIMITES_CATEGORIAS: una fila ID_CONFIG=1; LIMITE_GOLD y LIMITE_PREMIUM NUMBER(14,2) NOT NULL; VERSION NUMBER(10) DEFAULT 1 NOT NULL. PK_LIMITES_CATEGORIAS, CK_LIMITES_CONFIG, CK_LIMITES_ORDEN (0 < Gold < Premium), CK_LIMITES_VERSION y restricciones NOT NULL nombradas. Sinónimo LIMITES_CATEGORIAS.
- sql/11_limites_categorias.sql se ejecuta una vez antes de 05_funciones.sql, tanto al actualizar como al instalar de cero. Crea solo tabla y sinónimo y confirma los valores iniciales; no cambia clientes, cuentas ni movimientos. No repetir el script 11 sobre una instalación ya migrada.
- FN_CATEGORIA_CLIENTE y BLOQUE_RESUMEN_CLIENTE leen esta configuración; siguiente nivel y falta para alcanzarlo usan los mismos límites. La clasificación sigue en PL/SQL. La copia del bloque en smoke se mantiene sincronizada. Las pruebas históricas de umbrales fijos corresponden a valores iniciales.
- GET /api/categorias/limites devuelve limite_gold, limite_premium y version. PUT del mismo recurso valida importes/orden/version; bloquea la configuración con WAIT 5, rechaza versiones obsoletas (409), guarda mediante binds y confirma en el servicio sin reintentar la escritura.
- Pantalla: Editar límites abre los valores vigentes; Guardar límites muestra confirmación; Cancelar descarta el formulario. Básico cubre los saldos inferiores a Gold. Se retiran Revisar clientes, Recalcular y tabla comparativa.
- Matriz e índice pasan a 42 entradas. La nueva validación real permanece pendiente hasta confirmación del usuario; las pruebas locales usan mocks y nunca conectan a Oracle.
