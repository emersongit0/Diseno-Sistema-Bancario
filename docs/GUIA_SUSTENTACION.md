# Guía de sustentación — versión MySQL actual

Esta guía corresponde a migracion/MySQL. La guía Oracle anterior está en docs/oracle/GUIA_SUSTENTACION.md. No presentar como MySQL los conceptos de PL/SQL que este motor no soporta. Las diferencias son parte de la explicación honesta.

## Historia y datos

Ana Torres (DNI 71000001) revisa sus ahorros y transfiere a Luis Vargas (71000002). Identifica las cuentas por titular/tipo: los IDs y saldos pueden haber cambiado. La demo procede del antiguo script 10 y está en sql/mysql/datos/04_datos_prueba.sql: seis clientes, ocho cuentas, treinta movimientos al cargar. Ana tiene AHORROS y CORRIENTE; Luis, CORRIENTE. Tras la carga limpia: Ana ahorros 1048.50, corriente 3150; Luis corriente 2250. No repetir la carga durante la demo.

El panel muestra código local MySQL; no es una traza automática. JavaScript pide una acción, Flask valida/llama, MySQL ejecuta y la pantalla representa el resultado.

## Tabla de referencia

| Punto | Pantalla y acción | Objeto MySQL / adaptación | Archivo SQL |
| --- | --- | --- | --- |
| 1. Preparación de BD y usuario | Iniciar MySQL local; luego Resumen general → ↻ Actualizar resumen. No hay botón para crear usuarios.  | Base nueva / consulta salud | INSTALAR_MYSQL.sql |
| 2. CREATE TABLE, INSERT, SELECT y UPDATE | Clientes → buscar DNI 71000001 → Editar → Nombres Ana, conservar apellido/correo → Guardar cliente. El alta está en + Nuevo cliente; no dupliques el DNI de Ana.  | TBL_CLIENTES, CLIENTES, TRG_CLIENTES_BI/BU | sql/mysql/01_esquema.sql |
| 3. Vistas | Cuentas → ↻ Actualizar → ahorros de Ana → Movimientos → Historial completo.  | V_CUENTAS_RESUMEN, V_ESTADO_CUENTA | sql/mysql/01_esquema.sql |
| 4. Secuencias: adaptación MySQL | Cuentas → + Abrir cuenta → Ana → Corriente → depósito 0 → tasa vacía → Abrir cuenta. Conserva sus ahorros originales para la transferencia.  | AUTO_INCREMENT, TBL_SECUENCIAS, SQ_CUENTA, TRG_CUENTAS_BI | sql/mysql/02_funciones_triggers.sql |
| 5. Sinónimos: vistas de compatibilidad | Cuentas → Movimientos → Últimos movimientos de los ahorros de Ana.  | MOVIMIENTOS (VIEW) | sql/mysql/01_esquema.sql |
| 6. Cursores explícitos | Estado de cuenta → ahorros de Ana → mes/año real de movimientos → Consultar estado de cuenta ↗.  | SP_ESTADO_CUENTA_MENSUAL | sql/mysql/03_procedimientos.sql |
| 7. Cursores implícitos: ROW_COUNT | Intereses y categorías → Intereses mensuales → periodo → Revisar aplicación de intereses ↗ → Confirmar intereses.  | SP_APLICAR_INTERESES y ROW_COUNT() | sql/mysql/03_procedimientos.sql |
| 8. Cursores anidados y parámetros: adaptación | Reporte de clientes → Ana → últimos movimientos por cuenta 5 → Generar reporte ↗ → expandir cuentas.  | SP_REPORTE_CLIENTES | sql/mysql/03_procedimientos.sql |
| 9. Bloques anónimos: procedimientos almacenados | Simulador de ahorro → cuenta de Ana → 12 meses, aporte 100, meta 5000 → Simular mi ahorro ↗. Clientes → Ver resumen es el otro caso.  | SP_SIMULADOR_INTERES, SP_RESUMEN_CLIENTE | sql/mysql/03_procedimientos.sql |
| 10. Variables, constantes, %TYPE y %ROWTYPE: diferencias | Simulador → cuenta de Ana → Simular mi ahorro ↗ → Ver código SQL MySQL ↗ → SP_SIMULADOR_INTERES.  | Variables locales de SP_SIMULADOR_INTERES | sql/mysql/03_procedimientos.sql |
| 11. FOR, LOOP y WHILE: adaptación | Simulador → Simular mi ahorro ↗; Categorías de clientes → Actualizar categorías de clientes.  | SP_SIMULADOR_INTERES, SP_ACTUALIZAR_CATEGORIAS | sql/mysql/03_procedimientos.sql |
| 12. IF, ELSEIF y ELSE | Categorías de clientes → Saldo total → Consultar categoría. Mira antes los límites vigentes.  | FN_CATEGORIA_CLIENTE | sql/mysql/02_funciones_triggers.sql |
| 13. Procedimientos IN y OUT | Usa la misma apertura de Ana del punto 4; no abras otra cuenta solo para explicar este punto.  | SP_ABRIR_CUENTA | sql/mysql/03_procedimientos.sql |
| 14. Funciones | Operaciones → Transferencia → ahorros de Ana → corriente de Luis → monto 100 → esperar comisión → Revisar transferencia ↗ → Confirmar transferencia.  | FN_SALDO_DISPONIBLE, FN_COMISION | sql/mysql/02_funciones_triggers.sql |
| 15. Triggers BEFORE y AFTER | La misma transferencia de Ana a Luis → Cuentas → Movimientos; Auditoría y registro de errores → Auditoría → Actualizar registros.  | TRG_MOVIMIENTOS_BI, TRG_MOVIMIENTOS_AI | sql/mysql/02_funciones_triggers.sql |
| 16. Excepciones y errores MySQL | Laboratorio de errores → División por cero; luego Registro de errores → Actualizar registros.  | SP_LAB_ERRORES, SP_LOG_ERROR y servicio Flask | sql/mysql/03_procedimientos.sql |

## Punto 1. Preparación de BD y usuario

### 1. ¿Qué es?

Es preparar un espacio y un acceso para los datos. Como habilitar un local antes de atender.

### 2. ¿Dónde se ve?

Iniciar MySQL local; luego Resumen general → ↻ Actualizar resumen. No hay botón para crear usuarios.

### 3. ¿Qué pasa en MySQL?

El instalador crea una base nueva con el acceso MySQL autorizado. No crea usuarios ni concede privilegios. GET /api/salud consulta SELECT 1 y la pantalla muestra conexión. La definición de base está en el SQL completo; la conexión se prepara desde scripts/instalar_mysql.py.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Uso MySQL local para operar sin FreeSQL. El indicador confirma que la aplicación puede consultar el servidor.»

**Pregunta probable y respuesta:** ¿Creas usuarios desde la pantalla? No; usas un acceso MySQL existente.

Fragmento literal: [INSTALAR_MYSQL.sql](../INSTALAR_MYSQL.sql), líneas 2–4.
<!-- fuente-literal: INSTALAR_MYSQL.sql:2:4 -->
```sql
CREATE DATABASE sistema_banco_mysql CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sistema_banco_mysql;
SET SESSION time_zone='-05:00';
```

## Punto 2. CREATE TABLE, INSERT, SELECT y UPDATE

### 1. ¿Qué es?

Preparar una tabla, agregar filas, leerlas y cambiarlas. Como un archivador con fichas que puedes registrar y corregir.

### 2. ¿Dónde se ve?

Clientes → buscar DNI 71000001 → Editar → Nombres Ana, conservar apellido/correo → Guardar cliente. El alta está en + Nuevo cliente; no dupliques el DNI de Ana.

### 3. ¿Qué pasa en MySQL?

GET /api/clientes consulta CLIENTES. PUT /api/clientes/<id> ejecuta UPDATE con binds en cliente_repo.py. Los triggers normalizan nombres y Flask confirma. Las tablas se crearon antes: no repetir CREATE durante la demo. POST /api/clientes inserta por la vista actualizable y obtiene lastrowid.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La tabla define la ficha del cliente. Aquí leo y edito a Ana sin crear otra persona.»

**Pregunta probable y respuesta:** ¿Quién evita un DNI duplicado? La restricción UNIQUE de MySQL.

Fragmento literal: [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql), líneas 4–13.
<!-- fuente-literal: sql/mysql/01_esquema.sql:4:13 -->
```sql
CREATE TABLE TBL_CLIENTES (
 ID_CLIENTE BIGINT PRIMARY KEY AUTO_INCREMENT,
 DNI VARCHAR(8) NOT NULL,
 NOMBRES VARCHAR(100) NOT NULL,
 APELLIDOS VARCHAR(100) NOT NULL,
 EMAIL VARCHAR(254) NOT NULL,
 CATEGORIA VARCHAR(7) NOT NULL DEFAULT 'BASICO',
 FECHA_REGISTRO DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CONSTRAINT UQ_CLIENTES_DNI UNIQUE (DNI),
 CONSTRAINT UQ_CLIENTES_EMAIL UNIQUE (EMAIL),
```

## Punto 3. Vistas

### 1. ¿Qué es?

Una vista guarda una consulta para mostrar datos juntos. Como una ventana a varias carpetas sin copiar sus documentos.

### 2. ¿Dónde se ve?

Cuentas → ↻ Actualizar → ahorros de Ana → Movimientos → Historial completo.

### 3. ¿Qué pasa en MySQL?

GET /api/cuentas consulta V_CUENTAS_RESUMEN y CUENTAS. GET /api/cuentas/<id>/historial verifica existencia con FN_SALDO_DISPONIBLE y consulta V_ESTADO_CUENTA. MySQL devuelve filas; JavaScript dibuja tablas.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La vista reúne datos del titular, la cuenta y su actividad. No creo otra copia de sus saldos.»

**Pregunta probable y respuesta:** ¿Guarda los resultados? Estas vistas normales guardan la consulta, no una copia del resultado.

Fragmento literal: [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql), líneas 122–126.
<!-- fuente-literal: sql/mysql/01_esquema.sql:122:126 -->
```sql
CREATE OR REPLACE VIEW V_ESTADO_CUENTA AS
SELECT c.ID_CUENTA,c.NRO_CUENTA,CONCAT(cli.NOMBRES,' ',cli.APELLIDOS) CLIENTE_COMPLETO,
 m.ID_MOVIMIENTO,m.TIPO,m.MONTO,m.SALDO_POSTERIOR,m.FECHA,m.DESCRIPCION
FROM TBL_MOVIMIENTOS m JOIN TBL_CUENTAS c ON c.ID_CUENTA=m.ID_CUENTA
JOIN TBL_CLIENTES cli ON cli.ID_CLIENTE=c.ID_CLIENTE;
```

## Punto 4. Secuencias: adaptación MySQL

### 1. ¿Qué es?

Oracle tenía dispensadores de números llamados secuencias. Aquí hay AUTO_INCREMENT y un contador transaccional para cuentas: como turnos de una oficina con otro mecanismo.

### 2. ¿Dónde se ve?

Cuentas → + Abrir cuenta → Ana → Corriente → depósito 0 → tasa vacía → Abrir cuenta. Conserva sus ahorros originales para la transferencia.

### 3. ¿Qué pasa en MySQL?

POST /api/cuentas llama SP_ABRIR_CUENTA. TRG_CUENTAS_BI incrementa TBL_SECUENCIAS en diez y genera número 191-XXXXXXXX. Los demás IDs usan AUTO_INCREMENT. La vista SQ_CUENTA muestra el contador; no es una secuencia nativa. El contador puede revertirse con la transacción, a diferencia de Oracle NEXTVAL.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El número se genera en MySQL. Conservé los saltos de diez mediante un contador protegido por la transacción.»

**Pregunta probable y respuesta:** ¿MySQL tiene las secuencias Oracle? No; documenté la sustitución y su diferencia ante rollback.

Fragmento literal: [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql), líneas 53–64.
<!-- fuente-literal: sql/mysql/02_funciones_triggers.sql:53:64 -->
```sql
CREATE TRIGGER TRG_CUENTAS_BI BEFORE INSERT ON TBL_CUENTAS FOR EACH ROW
BEGIN
 DECLARE v_id BIGINT;
 IF NEW.ID_CUENTA IS NULL OR NEW.ID_CUENTA=0 THEN
  UPDATE TBL_SECUENCIAS SET VALOR=VALOR+10 WHERE NOMBRE='SQ_CUENTA';
  SELECT VALOR INTO v_id FROM TBL_SECUENCIAS WHERE NOMBRE='SQ_CUENTA';
  IF v_id>99999999 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Se agotó la numeración de cuentas.'; END IF;
  SET NEW.ID_CUENTA=v_id;
 END IF;
 IF NEW.NRO_CUENTA IS NULL OR NEW.NRO_CUENTA='' THEN SET NEW.NRO_CUENTA=CONCAT('191-',LPAD(NEW.ID_CUENTA,8,'0')); END IF;
END$$
-- @FIN
```

## Punto 5. Sinónimos: vistas de compatibilidad

### 1. ¿Qué es?

Un sinónimo era un nombre alternativo. MySQL no tiene ese objeto: usamos vistas simples, como una puerta con un nombre corto a la misma carpeta.

### 2. ¿Dónde se ve?

Cuentas → Movimientos → Últimos movimientos de los ahorros de Ana.

### 3. ¿Qué pasa en MySQL?

GET /api/cuentas/<id>/movimientos usa MOVIMIENTOS con límite veinte. Esa vista simple apunta a TBL_MOVIMIENTOS; no copia datos. CLIENTES, CUENTAS y las demás vistas simples permiten mantener nombres de acceso y DML cuando la vista es actualizable.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El nombre corto se conserva con una vista MySQL real. No lo presento como CREATE SYNONYM.»

**Pregunta probable y respuesta:** ¿Es exactamente un sinónimo? No; es una adaptación con una vista simple.

Fragmento literal: [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql), líneas 106–106.
<!-- fuente-literal: sql/mysql/01_esquema.sql:106:106 -->
```sql
CREATE OR REPLACE ALGORITHM=MERGE VIEW MOVIMIENTOS AS SELECT * FROM TBL_MOVIMIENTOS;
```

## Punto 6. Cursores explícitos

### 1. ¿Qué es?

Recorrer resultados controlando abrir, leer y cerrar. Como revisar boletas una por una.

### 2. ¿Dónde se ve?

Estado de cuenta → ahorros de Ana → mes/año real de movimientos → Consultar estado de cuenta ↗.

### 3. ¿Qué pasa en MySQL?

GET /api/estado-cuenta/<id>?anio=...&mes=... llama SP_ESTADO_CUENTA_MENSUAL. Calcula saldo anterior, abre cursor, hace FETCH/LOOP/LEAVE y cierra. Devuelve JSON OUT y el backend lo convierte en filas. No hay función PIPELINED ni PIPE ROW.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Sigo controlando el recorrido con un cursor explícito. En MySQL devuelvo sus filas como JSON desde un procedimiento.»

**Pregunta probable y respuesta:** ¿Por qué calculas saldo anterior? Porque el saldo actual puede incluir fechas posteriores al mes consultado.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 295–304.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:295:304 -->
```sql
 OPEN c_mov;
 movimientos: LOOP
  FETCH c_mov INTO v_fecha,v_tipo,v_desc,v_monto;
  IF v_fin THEN LEAVE movimientos; END IF;
  IF v_tipo IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN SET v_saldo=v_saldo+v_monto; ELSE SET v_saldo=v_saldo-v_monto; END IF;
  SET v_json=JSON_ARRAY_APPEND(v_json,'$',JSON_OBJECT('fecha',DATE_FORMAT(v_fecha,'%Y-%m-%dT%H:%i:%s.%f'),'tipo',v_tipo,'descripcion',v_desc,'monto',v_monto,'saldo_acumulado',v_saldo));
 END LOOP;
 CLOSE c_mov;
 SET p_json=CAST(v_json AS CHAR),p_mensaje='Estado mensual generado.';
END$$
```

## Punto 7. Cursores implícitos: ROW_COUNT

### 1. ¿Qué es?

MySQL informa cuántas filas afectó la última sentencia. Como un contador de entradas que consultas al terminar.

### 2. ¿Dónde se ve?

Intereses y categorías → Intereses mensuales → periodo → Revisar aplicación de intereses ↗ → Confirmar intereses.

### 3. ¿Qué pasa en MySQL?

La revisión no escribe. POST /api/intereses/aplicar llama SP_APLICAR_INTERESES. Recorre activas, registra solo intereses positivos y actualiza la fecha. ROW_COUNT() se lee inmediatamente tras el UPDATE y se acumula. No existen SQL%ROWCOUNT/SQL%FOUND de Oracle. El proceso alcanza todas las cuentas elegibles.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Leo el resultado del UPDATE sin abrir otro cursor para contarlo. El conteo real vuelve a la pantalla.»

**Pregunta probable y respuesta:** ¿Si repites el periodo? No se duplica el interés; el resultado puede ser cero actualizadas.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 167–170.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:167:170 -->
```sql
   UPDATE TBL_CUENTAS SET FECHA_ULT_INTERES=v_mes WHERE ID_CUENTA=v_id;
   SET p_n_cuentas=p_n_cuentas+ROW_COUNT();
  END IF;
 END IF;
```

## Punto 8. Cursores anidados y parámetros: adaptación

### 1. ¿Qué es?

Un recorrido dentro de otro sigue una jerarquía. Como carpetas de cliente, cuenta y boletas.

### 2. ¿Dónde se ve?

Reporte de clientes → Ana → últimos movimientos por cuenta 5 → Generar reporte ↗ → expandir cuentas.

### 3. ¿Qué pasa en MySQL?

GET /api/reporte/clientes llama SP_REPORTE_CLIENTES. Los cursores anidados leen v_id y v_cta del nivel externo y el límite del procedimiento. MySQL no tiene los parámetros formales del cursor PL/SQL. JSON conserva cliente/cuentas/movimientos. Cinco es por cuenta, no para todo el reporte.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El recorrido sigue cliente, cuenta y movimientos. Los cursores leen variables del nivel externo para elegir las filas correctas.»

**Pregunta probable y respuesta:** ¿Hay cursores parametrizados iguales a Oracle? No; los valores se pasan a través de variables y parámetros del procedimiento.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 333–338.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:333:338 -->
```sql
   DECLARE c_cta CURSOR FOR SELECT ID_CUENTA,NRO_CUENTA,SALDO,ESTADO FROM TBL_CUENTAS WHERE ID_CLIENTE=v_id ORDER BY ID_CUENTA;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_cta=TRUE;
   OPEN c_cta;
   cuentas: LOOP
    FETCH c_cta INTO v_cta,v_nro,v_saldo,v_estado;
    IF fin_cta THEN LEAVE cuentas; END IF;
```

## Punto 9. Bloques anónimos: procedimientos almacenados

### 1. ¿Qué es?

Los bloques temporales de Oracle fueron reemplazados por rutinas con nombre en MySQL. Como guardar una receta que antes usabas en una hoja suelta.

### 2. ¿Dónde se ve?

Simulador de ahorro → cuenta de Ana → 12 meses, aporte 100, meta 5000 → Simular mi ahorro ↗. Clientes → Ver resumen es el otro caso.

### 3. ¿Qué pasa en MySQL?

POST /api/simulador llama SP_SIMULADOR_INTERES. GET /api/clientes/<id>/resumen llama SP_RESUMEN_CLIENTE. Ambos se almacenan en MySQL y devuelven JSON/OUT. Simular no hace movimientos ni cambia saldo. No se ejecutan bloques PL/SQL ni texto libre.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Esta versión usa procedimientos almacenados MySQL. Conserva los resultados de la simulación y del resumen.»

**Pregunta probable y respuesta:** ¿Siguen siendo bloques anónimos? No; esa es una diferencia explícita de la migración.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 238–243.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:238:243 -->
```sql
CREATE PROCEDURE SP_SIMULADOR_INTERES(IN p_saldo_inicial DECIMAL(14,2),IN p_tasa_anual DECIMAL(5,2),IN p_meses INT,IN p_aporte_mensual DECIMAL(14,2),IN p_meta DECIMAL(14,2),IN p_id_cuenta BIGINT,OUT p_saldo_final DECIMAL(40,2),OUT p_meses_meta INT,OUT p_proyeccion LONGTEXT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_inicial DECIMAL(40,2); DECLARE v_tasa DECIMAL(5,2); DECLARE v_saldo DECIMAL(40,2); DECLARE v_meta DECIMAL(40,2); DECLARE v_i INT DEFAULT 0; DECLARE v_mes INT DEFAULT 0; DECLARE v_json JSON;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
```

## Punto 10. Variables, constantes, %TYPE y %ROWTYPE: diferencias

### 1. ¿Qué es?

Las variables son casilleros para valores. MySQL usa tipos explícitos; no ofrece las declaraciones %TYPE, %ROWTYPE y CONSTANT de PL/SQL utilizadas antes.

### 2. ¿Dónde se ve?

Simulador → cuenta de Ana → Simular mi ahorro ↗ → Ver código SQL MySQL ↗ → SP_SIMULADOR_INTERES.

### 3. ¿Qué pasa en MySQL?

El procedimiento declara DECIMAL/INT/JSON. Lee saldo y tasa de la cuenta en variables; usa el límite literal 600. No se afirma que una fila completa se copie con %ROWTYPE ni que exista una CONSTANT PL/SQL en MySQL.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Los valores siguen guardados en variables. Cambió la forma de declarar sus tipos y límites.»

**Pregunta probable y respuesta:** ¿Demuestras %TYPE aquí? No; puedo explicar la versión Oracle archivada y la adaptación actual, sin afirmar que sea MySQL.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 242–243.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:242:243 -->
```sql
 DECLARE v_inicial DECIMAL(40,2); DECLARE v_tasa DECIMAL(5,2); DECLARE v_saldo DECIMAL(40,2); DECLARE v_meta DECIMAL(40,2); DECLARE v_i INT DEFAULT 0; DECLARE v_mes INT DEFAULT 0; DECLARE v_json JSON;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
```

## Punto 11. FOR, LOOP y WHILE: adaptación

### 1. ¿Qué es?

Son formas de repetir pasos. Como contar cuotas, atender fichas y ahorrar mientras falte una meta.

### 2. ¿Dónde se ve?

Simulador → Simular mi ahorro ↗; Categorías de clientes → Actualizar categorías de clientes.

### 3. ¿Qué pasa en MySQL?

SP_SIMULADOR_INTERES usa WHILE para proyección y meta. SP_ACTUALIZAR_CATEGORIAS usa LOOP/FETCH/LEAVE, suma saldos y cambia solo categorías diferentes. No hay FOR PL/SQL. El plazo de proyección y los meses a la meta son recorridos separados.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Uso WHILE para los meses y LOOP para recorrer clientes. La salida evita que el recorrido continúe sin fin.»

**Pregunta probable y respuesta:** ¿Por qué la meta puede superar el plazo elegido? Se busca por separado hasta 600 meses.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 258–265.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:258:265 -->
```sql
 WHILE v_i<=p_meses DO
  SET v_saldo=ROUND(v_saldo*(1+v_tasa/100/12)+p_aporte_mensual,2);
  SET v_json=JSON_ARRAY_APPEND(v_json,'$',JSON_OBJECT('mes',v_i,'saldo',v_saldo)),v_i=v_i+1;
 END WHILE;
 SET v_meta=v_inicial;
 WHILE v_meta<p_meta AND v_mes<600 DO
  SET v_meta=ROUND(v_meta*(1+v_tasa/100/12)+p_aporte_mensual,2),v_mes=v_mes+1;
 END WHILE;
```

## Punto 12. IF, ELSEIF y ELSE

### 1. ¿Qué es?

Elegir un camino según una condición. Como un cruce con tres señales.

### 2. ¿Dónde se ve?

Categorías de clientes → Saldo total → Consultar categoría. Mira antes los límites vigentes.

### 3. ¿Qué pasa en MySQL?

GET /api/categoria llama FN_CATEGORIA_CLIENTE. Lee Gold/Premium y devuelve BASICO/GOLD/PREMIUM. Se escribe ELSEIF en MySQL, no ELSIF. Editar límites → Guardar límites → confirmar guarda condiciones; Actualizar categorías de clientes las aplica a saldos reales. Consultar no modifica clientes.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La función elige una sola categoría. Guardar límites y actualizar clientes son acciones distintas.»

**Pregunta probable y respuesta:** ¿Qué pasa exactamente en el límite Gold? Es GOLD; BASICO solo incluye saldos menores.

Fragmento literal: [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql), líneas 15–24.
<!-- fuente-literal: sql/mysql/02_funciones_triggers.sql:15:24 -->
```sql
CREATE FUNCTION FN_CATEGORIA_CLIENTE(p_saldo_total DECIMAL(24,2)) RETURNS VARCHAR(7) READS SQL DATA
BEGIN
 DECLARE v_gold DECIMAL(14,2);
 DECLARE v_premium DECIMAL(14,2);
 SELECT LIMITE_GOLD,LIMITE_PREMIUM INTO v_gold,v_premium FROM TBL_LIMITES_CATEGORIAS WHERE ID_CONFIG=1;
 IF COALESCE(p_saldo_total,0)<v_gold THEN RETURN 'BASICO';
 ELSEIF p_saldo_total<v_premium THEN RETURN 'GOLD';
 ELSE RETURN 'PREMIUM'; END IF;
END$$
-- @FIN
```

## Punto 13. Procedimientos IN y OUT

### 1. ¿Qué es?

IN entrega datos y OUT devuelve resultados de una tarea. Como una solicitud que entra a ventanilla y regresa con su número.

### 2. ¿Dónde se ve?

Usa la misma apertura de Ana del punto 4; no abras otra cuenta solo para explicar este punto.

### 3. ¿Qué pasa en MySQL?

SP_ABRIR_CUENTA recibe cliente/tipo/saldo/tasa. Valida, inserta cuenta y opcionalmente depósito inicial. Los triggers completan número y saldo. OUT devuelve ID/número/estado/código/mensaje; Connector/Python callproc los recupera. Flask confirma, no el procedimiento.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Entrego datos con IN y recibo resultados con OUT. La confirmación de la transacción la hace Flask.»

**Pregunta probable y respuesta:** ¿Si falla la apertura? El procedimiento informa error y la transacción se revierte.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 9–13.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:9:13 -->
```sql
CREATE PROCEDURE SP_ABRIR_CUENTA(IN p_id_cliente BIGINT,IN p_tipo VARCHAR(9),IN p_saldo_inicial DECIMAL(14,2),IN p_tasa DECIMAL(5,2),OUT p_id_cuenta BIGINT,OUT p_nro_cuenta VARCHAR(12),OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;

```

## Punto 14. Funciones

### 1. ¿Qué es?

Reciben valores y devuelven una respuesta con RETURN. Como una calculadora.

### 2. ¿Dónde se ve?

Operaciones → Transferencia → ahorros de Ana → corriente de Luis → monto 100 → esperar comisión → Revisar transferencia ↗ → Confirmar transferencia.

### 3. ¿Qué pasa en MySQL?

La cuenta consulta FN_SALDO_DISPONIBLE. El monto espera 300 ms y GET /api/comision llama FN_COMISION con la categoría registrada. Confirmar envía POST /api/transferir; SP_TRANSFERIR revalida. Si Ana sigue BASICO, comisión 1.50, débito 101.50 y abono 100. La revisión no reserva dinero.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La comisión se calcula en MySQL. La cotización se vuelve a validar al confirmar.»

**Pregunta probable y respuesta:** ¿Función frente a procedimiento? La función devuelve un valor; el procedimiento realiza una tarea y comunica OUT.

Fragmento literal: [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql), líneas 27–37.
<!-- fuente-literal: sql/mysql/02_funciones_triggers.sql:27:37 -->
```sql
CREATE FUNCTION FN_COMISION(p_monto DECIMAL(14,2),p_categoria VARCHAR(7)) RETURNS DECIMAL(14,2) DETERMINISTIC NO SQL
BEGIN
 DECLARE v_tasa DECIMAL(6,5) DEFAULT 0.015;
 IF p_monto IS NULL OR p_monto<=0 THEN
  SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Monto inválido: debe ser mayor que cero.';
 END IF;
 IF UPPER(TRIM(p_categoria))='PREMIUM' THEN SET v_tasa=0.003;
 ELSEIF UPPER(TRIM(p_categoria))='GOLD' THEN SET v_tasa=0.008; END IF;
 RETURN ROUND(GREATEST(p_monto*v_tasa,1.00),2);
END$$
-- @FIN
```

## Punto 15. Triggers BEFORE y AFTER

### 1. ¿Qué es?

Se activan automáticamente por un cambio. Como una puerta que valida antes y deja registro después.

### 2. ¿Dónde se ve?

La misma transferencia de Ana a Luis → Cuentas → Movimientos; Auditoría y registro de errores → Auditoría → Actualizar registros.

### 3. ¿Qué pasa en MySQL?

SP_TRANSFERIR inserta envío, comisión y recepción. TRG_MOVIMIENTOS_BI calcula saldo posterior y valida monto. TRG_MOVIMIENTOS_AI actualiza saldo y audita. La comisión se calcula antes de insertar; el saldo que ve su movimiento incluye el envío previo. Si falla la tercera inserción, se revierte todo. MySQL separa triggers INSERT/UPDATE de clientes.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El BEFORE prepara la fila y el AFTER mantiene saldo y auditoría. El procedimiento no descuenta el saldo otra vez.»

**Pregunta probable y respuesta:** ¿Por qué no se duplica el descuento? Solo el AFTER mantiene el saldo al insertar cada movimiento.

Fragmento literal: [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql), líneas 81–92.
<!-- fuente-literal: sql/mysql/02_funciones_triggers.sql:81:92 -->
```sql
CREATE TRIGGER TRG_MOVIMIENTOS_AI AFTER INSERT ON TBL_MOVIMIENTOS FOR EACH ROW
BEGIN
 IF COALESCE(@banco_importacion,0)=0 THEN
  IF NEW.TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN
   UPDATE TBL_CUENTAS SET SALDO=SALDO+NEW.MONTO WHERE ID_CUENTA=NEW.ID_CUENTA;
  ELSE UPDATE TBL_CUENTAS SET SALDO=SALDO-NEW.MONTO WHERE ID_CUENTA=NEW.ID_CUENTA; END IF;
  INSERT INTO TBL_AUDITORIA(TABLA,OPERACION,ID_REGISTRO,USUARIO_BD,DETALLE)
  VALUES('TBL_MOVIMIENTOS','INSERT',NEW.ID_MOVIMIENTO,CURRENT_USER(),CONCAT('Cuenta ',NEW.ID_CUENTA,'; tipo ',NEW.TIPO,'; monto ',NEW.MONTO,'; saldo posterior ',NEW.SALDO_POSTERIOR));
 END IF;
END$$
-- @FIN

```

## Punto 16. Excepciones y errores MySQL

### 1. ¿Qué es?

Atender una situación inválida de forma controlada. Como un simulacro que deja evidencia sin conservar sus daños.

### 2. ¿Dónde se ve?

Laboratorio de errores → División por cero; luego Registro de errores → Actualizar registros.

### 3. ¿Qué pasa en MySQL?

POST /api/laboratorio/zero_divide llama SP_LAB_ERRORES. Los handlers usan GET DIAGNOSTICS para MYSQL_ERRNO/MESSAGE_TEXT. MySQL devuelve -1365 para la división en esta prueba. Flask revierte la prueba y registra el log mediante otra conexión/transacción. No existe PRAGMA AUTONOMOUS_TRANSACTION. HTTP correspondiente no es necesariamente el HTTP de la petición de laboratorio, que puede ser 200 por prueba correcta.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El error se provoca y se captura. El registro independiente lo coordina Flask después del rollback.»

**Pregunta probable y respuesta:** ¿Un CALL manual tiene log autónomo? No; el registro independiente requiere la coordinación del servicio.

Fragmento literal: [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql), líneas 379–382.
<!-- fuente-literal: sql/mysql/03_procedimientos.sql:379:382 -->
```sql
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION,SQLWARNING,NOT FOUND
  BEGIN GET DIAGNOSTICS CONDITION 1 v_codigo=MYSQL_ERRNO,v_error=MESSAGE_TEXT; END;
  CASE UPPER(p_caso)
   WHEN 'NO_DATA_FOUND' THEN SELECT ID_CLIENTE INTO v_num FROM TBL_CLIENTES WHERE ID_CLIENTE=-1;
```

## Demo de 14 minutos

| Tiempo | Historia y acción | Puntos |
| --- | --- | --- |
| 0:00–1:00 | Resumen general y conexión local. Explica preparación previa; no instales otra vez. | 1 |
| 1:00–2:15 | Clientes: busca Ana, edita Nombres a Ana, guarda y abre Ver resumen. | 2, 9 |
| 2:15–3:30 | Abre una cuenta adicional de Ana con cero. Explica números e IN/OUT. Conserva los ahorros originales. | 4, 13 |
| 3:30–4:30 | Compara Historial completo y Últimos movimientos de sus ahorros. | 3, 5 |
| 4:30–6:30 | Transfiere 100 de ahorros de Ana a corriente de Luis; espera comisión, revisa y confirma una vez. | 14, 15 |
| 6:30–7:30 | Consulta el estado mensual del mes real de esa operación. | 6 |
| 7:30–8:30 | Genera reporte de Ana con cinco movimientos por cuenta y expande niveles. | 8 |
| 8:30–10:00 | Consulta categoría con límites vigentes y pulsa Actualizar categorías de clientes. Revisa/confirma intereses del periodo ensayado; proceso global. | 7, 11, 12 |
| 10:00–11:30 | Simula ahorro de Ana: doce meses, aporte cien, meta cinco mil. Señala variables y diferencias de lenguaje. | 9, 10, 11 |
| 11:30–12:30 | Auditoría: muestra los hechos de la transferencia. | 15 |
| 12:30–14:00 | División por cero y Registro de errores. Explica handlers y transacciones separadas. | 16 |

Ensaya antes: MySQL activo, cuentas activas y saldo suficiente. Intereses y categorías afectan todos los registros elegibles; repetir el periodo puede dar cero. Cada ensayo con confirmaciones modifica datos. Para acabar en doce minutos acorta las explicaciones repetidas; con quince muestra Editar límites y Cancelar.

## Adaptaciones y evidencia

Consulta [MIGRACION_MYSQL.md](MIGRACION_MYSQL.md) para el mapa completo. No hay sinónimos, secuencias Oracle, tipos pipelined, cursores PL/SQL con parámetros formales, bloques anónimos, %TYPE/%ROWTYPE/CONSTANT, FOR PL/SQL ni transacciones autónomas. Se conservaron los resultados con vistas, AUTO_INCREMENT/contador, SQL/PSM, procedimientos JSON, cursores y transacciones coordinadas desde Flask.

Las 112 pruebas unitarias no abren conexiones. La prueba real utiliza bases temporales MySQL; el navegador comprobó las diez pantallas. Los datos activos son demo: no se ha exportado el origen Oracle actual. Nunca confundir una prueba del importador con haber copiado registros remotos.

Los fragmentos son extractos literales, no programas completos. Los archivos Oracle archivados sirven de referencia y no deben ejecutarse sobre MySQL.
