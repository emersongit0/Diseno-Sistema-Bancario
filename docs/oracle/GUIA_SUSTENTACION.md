# Guía de sustentación — Banco Oracle

Guía de consulta para explicar el proyecto sin memorizar el código. Fecha: 24 de noviembre de 2026. Se contrastó con los archivos de esta rama, `vistas/flujo_normal`.

La Fase 6 base se cierra con la confirmación del usuario de que generó el snapshot actual y obtuvo **SNAPSHOTS OK**. Esto no convierte en verificadas las ampliaciones recientes. La edición de límites y la reorganización conservan sus validaciones reales pendientes en la matriz.

## Cómo usar esta guía

Lee las frases de «Para decir» durante el ensayo. En la presentación, muestra la acción y explica su efecto. Los fragmentos son extractos literales de los archivos; algunos no forman un programa completo. No están destinados a ejecutarse por separado.

En cualquier pantalla, **Cómo funciona en Oracle** despliega la explicación. **Ver código PL/SQL ↗** abre el código; el selector **Objeto** permite cambiar de rutina. El código mostrado viene de archivos locales, mediante `GET /api/codigo/<objeto>`. No se consulta `USER_SOURCE`. El panel declara objetos relacionados con la respuesta; no es una traza automática de ejecución de Oracle.

El recorrido común es: **clic → JavaScript → endpoint Flask → servicio → repositorio → Oracle → respuesta → pantalla**. Un endpoint es la dirección a la que la pantalla pide una acción. Un repositorio es el archivo Python que habla con Oracle. Flask confirma las escrituras correctas; revierte las fallidas. Los procedimientos de negocio no hacen `COMMIT`. La excepción es el registro autónomo de errores.

## La historia y los datos que vas a usar

«Ana Torres quiere revisar sus ahorros, abrir otra cuenta y transferir dinero a Luis Vargas. Después revisamos lo ocurrido y proyectamos su ahorro».

Estos datos salen de [10_datos_prueba.sql](../sql/10_datos_prueba.sql):

| Persona | DNI | Correo de prueba | Cuentas creadas e importes de apertura |
| --- | --- | --- | --- |
| Ana Torres | 71000001 | demo1@banco.example | AHORROS: S/ 1,000; CORRIENTE: S/ 3,000 |
| Luis Vargas | 71000002 | demo2@banco.example | CORRIENTE: S/ 2,000 |
| María Quispe | 71000003 | demo3@banco.example | Dos AHORROS: S/ 10,000 y S/ 12,000 |
| José Rojas | 71000004 | demo4@banco.example | CORRIENTE: S/ 15,000 |
| Lucía Castillo | 71000005 | demo5@banco.example | AHORROS: S/ 60,000 |
| Diego Flores | 71000006 | demo6@banco.example | AHORROS: S/ 80,000 |

El script también deposita S/ 200 y retira S/ 50 en cada cuenta. Transfiere S/ 100 de Ana a Luis y S/ 500 de Lucía a José. Actualiza categorías. Tras una carga limpia, con las condiciones iniciales, quedan **6 clientes, 8 cuentas y 30 movimientos**.

En ese momento, los ahorros de Ana quedan en S/ 1,048.50; su corriente, en S/ 3,150; la corriente de Luis, en S/ 2,250. Son referencias de la carga, no una promesa del saldo actual. Las pruebas y la demo cambian los datos.

Busca Ana y Luis por DNI. Identifica sus cuentas por titular y tipo; anota los números e IDs que realmente muestre tu instalación. No presupongas que un ID vale 1 o que una cuenta empieza en 1000: las pruebas consumen secuencias. No vuelvas a ejecutar el script 10 para preparar la exposición.

## Tabla resumen de los 16 puntos

| Punto | Pantalla y acción | Objeto Oracle | Archivo SQL |
| --- | --- | --- | --- |
| 1. Preparación de BD y usuario | Preparación previa en FreeSQL; Resumen general → ↻ Actualizar resumen como evidencia de conexión | Auxiliares F0P_*; consulta de salud a dual, sin procedimiento | [00_prueba_privilegios.sql](../sql/00_prueba_privilegios.sql); salud está en reporte_repo.py |
| 2. CREATE TABLE, INSERT, SELECT, UPDATE | Definición instalada; Clientes → Editar → Guardar cliente; alta disponible en + Nuevo cliente | TBL_CLIENTES, sinónimo CLIENTES, TRG_CLIENTES_BI | [01_tablas.sql](../sql/01_tablas.sql), [10_datos_prueba.sql](../sql/10_datos_prueba.sql), [06_triggers.sql](../sql/06_triggers.sql) |
| 3. Vistas | Cuentas → ↻ Actualizar; Movimientos → Historial completo | V_CUENTAS_RESUMEN, V_ESTADO_CUENTA | [04_vistas.sql](../sql/04_vistas.sql) |
| 4. Secuencias | Cuentas → + Abrir cuenta → Ana → Abrir cuenta | SQ_CUENTA, TRG_CUENTAS_BI, SP_ABRIR_CUENTA | [02_secuencias.sql](../sql/02_secuencias.sql), [06_triggers.sql](../sql/06_triggers.sql), [07_procedimientos.sql](../sql/07_procedimientos.sql) |
| 5. Sinónimos | Cuentas → Movimientos → Últimos movimientos | MOVIMIENTOS; verificación con FN_SALDO_DISPONIBLE | [09_sinonimos.sql](../sql/09_sinonimos.sql), [05_funciones.sql](../sql/05_funciones.sql) |
| 6. Cursor explícito | Estado de cuenta → cuenta y mes → Consultar estado de cuenta ↗ | FN_ESTADO_CUENTA_MENSUAL, T_MOV_FILA, T_MOV_TABLA | [08_funcion_pipelined.sql](../sql/08_funcion_pipelined.sql), [03_tipos.sql](../sql/03_tipos.sql) |
| 7. Cursor implícito | Intereses y categorías → Revisar aplicación de intereses ↗ → Confirmar intereses | SQL%ROWCOUNT y SQL%FOUND en SP_APLICAR_INTERESES | [07_procedimientos.sql](../sql/07_procedimientos.sql) |
| 8. Cursores con parámetros y anidados | Reporte de clientes → Ana → Generar reporte ↗ → expandir cuentas | SP_REPORTE_CLIENTES: c_clientes, c_cuentas, c_movs | [07_procedimientos.sql](../sql/07_procedimientos.sql) |
| 9. Bloques anónimos | Simulador de ahorro → cuenta de Ana → Simular mi ahorro ↗; Clientes → Ver resumen | BLOQUE_SIMULADOR_INTERES; BLOQUE_RESUMEN_CLIENTE | [simulador_interes.sql](../sql/bloques/simulador_interes.sql), [resumen_cliente.sql](../sql/bloques/resumen_cliente.sql) |
| 10. Variables, constantes, %TYPE, %ROWTYPE | Simulador → elegir la cuenta de Ana → Simular mi ahorro ↗ | Declaraciones del bloque del simulador | [simulador_interes.sql](../sql/bloques/simulador_interes.sql) |
| 11. FOR, LOOP, WHILE | Simulador → Simular mi ahorro ↗; Categorías de clientes → Actualizar categorías de clientes | Bloque del simulador; SP_ACTUALIZAR_CATEGORIAS | [simulador_interes.sql](../sql/bloques/simulador_interes.sql), [07_procedimientos.sql](../sql/07_procedimientos.sql) |
| 12. IF, ELSIF, ELSE | Categorías de clientes → Saldo total → Consultar categoría | FN_CATEGORIA_CLIENTE; configuración de límites | [05_funciones.sql](../sql/05_funciones.sql), [11_limites_categorias.sql](../sql/11_limites_categorias.sql) |
| 13. Procedimientos IN/OUT | Cuentas → + Abrir cuenta → completar → Abrir cuenta | SP_ABRIR_CUENTA | [07_procedimientos.sql](../sql/07_procedimientos.sql) |
| 14. Funciones | Operaciones → Transferencia → monto → esperar comisión | FN_SALDO_DISPONIBLE, FN_COMISION; SP_TRANSFERIR al confirmar | [05_funciones.sql](../sql/05_funciones.sql), [07_procedimientos.sql](../sql/07_procedimientos.sql) |
| 15. Triggers BEFORE/AFTER | Confirmar transferencia; Cuentas → Movimientos; Auditoría → ↻ Actualizar registros | TRG_MOVIMIENTOS_BI, TRG_MOVIMIENTOS_AI; otros triggers de clientes/cuentas | [06_triggers.sql](../sql/06_triggers.sql) |
| 16. Excepciones | Laboratorio de errores → División por cero; luego Registro de errores | SP_LAB_ERRORES, ZERO_DIVIDE, SP_LOG_ERROR | [07_procedimientos.sql](../sql/07_procedimientos.sql), [05_funciones.sql](../sql/05_funciones.sql) |

## Punto 1. Preparación de la base de datos y del usuario

### 1. ¿Qué es?

Es tener un espacio donde guardar los datos y permiso para crear los elementos del proyecto. **Analogía:** alquilar un local y comprobar que puedes usar sus instalaciones.

### 2. ¿Dónde se ve?

No existe una pantalla para crear usuarios o dar permisos. Esa preparación se hizo antes, en el esquema personal de FreeSQL. Como evidencia de conexión, entra en **Inicio → Resumen general → ↻ Actualizar resumen** y observa **Base de datos conectada**.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

El clic solicita `GET /api/salud`. `app/repositories/reporte_repo.py`, función `salud`, consulta `SELECT 1 AS ESTADO FROM dual`. Si funciona, la pantalla muestra el indicador verde. No crea un usuario, no otorga permisos y no demuestra por sí solo que todos los objetos estén válidos.

La preparación previa está en `sql/00_prueba_privilegios.sql`: crea objetos temporales F0P_*, comprueba su estado y los elimina. `probar_conexion.py` comprueba la conexión por separado; lo ejecuta el usuario. No repitas el script de privilegios sobre el banco instalado: se detiene si encuentra los nombres de producción.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Uso mi esquema personal de Oracle FreeSQL. Antes comprobé los permisos con objetos de prueba y los retiré. El indicador confirma que la aplicación puede consultar Oracle».

**Pregunta probable:** ¿Tu aplicación crea usuarios? **Respuesta:** No. FreeSQL proporciona el esquema; la aplicación usa ese acceso.

**Fragmento real.** [sql/00_prueba_privilegios.sql](../sql/00_prueba_privilegios.sql), líneas 122–129.

<!-- fuente-literal: sql/00_prueba_privilegios.sql:122:129 -->
```sql
    crear('CREATE TABLE F0P_TABLA (ID NUMBER CONSTRAINT PK_F0P_TABLA PRIMARY KEY)', 'DROP TABLE F0P_TABLA PURGE');
    crear('CREATE SEQUENCE F0P_SECUENCIA START WITH 1', 'DROP SEQUENCE F0P_SECUENCIA');
    crear('CREATE VIEW F0P_VISTA AS SELECT ID FROM F0P_TABLA', 'DROP VIEW F0P_VISTA');
    crear('CREATE SYNONYM F0P_SINONIMO FOR F0P_TABLA', 'DROP SYNONYM F0P_SINONIMO');
    crear('CREATE TYPE F0P_TIPO AS OBJECT (ID NUMBER)', 'DROP TYPE F0P_TIPO');
    crear('CREATE PROCEDURE F0P_PROCEDIMIENTO AS BEGIN NULL; END;', 'DROP PROCEDURE F0P_PROCEDIMIENTO');
    crear('CREATE FUNCTION F0P_FUNCION RETURN NUMBER AS BEGIN RETURN 1; END;', 'DROP FUNCTION F0P_FUNCION');
    crear('CREATE TRIGGER F0P_TRIGGER BEFORE INSERT ON F0P_TABLA FOR EACH ROW BEGIN IF :NEW.ID IS NULL THEN :NEW.ID := F0P_SECUENCIA.NEXTVAL; END IF; END;', 'DROP TRIGGER F0P_TRIGGER');
```

## Punto 2. CREATE TABLE, INSERT, SELECT y UPDATE

### 1. ¿Qué es?

`CREATE TABLE` prepara una tabla. `INSERT` agrega datos, `SELECT` los consulta y `UPDATE` los cambia. **Analogía:** preparar un archivador, agregar una ficha, leerla y corregirla.

### 2. ¿Dónde se ve?

En **Clientes**, busca `71000001`. Pulsa **Editar** en Ana Torres, escribe `Ana` en Nombres y conserva apellido y correo; pulsa **Guardar cliente**. Verás sus nombres en mayúsculas. La tabla de pantalla permite consultar los datos. **+ Nuevo cliente → Guardar cliente** permite dar de alta, pero no registres otra Ana con el mismo DNI.

La creación de tablas y el INSERT de Ana se muestran como código ya ejecutado: no se repiten durante la historia.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

El listado usa `GET /api/clientes` y un SELECT mediante el sinónimo `CLIENTES`. Guardar la edición llama `PUT /api/clientes/<id>`. `app/repositories/cliente_repo.py` hace UPDATE con parámetros separados del SQL. Se ejecuta `TRG_CLIENTES_BI`, de `sql/06_triggers.sql`, y normaliza los nombres. El servicio confirma la transacción y el navegador vuelve a consultar la lista.

`sql/01_tablas.sql` define `TBL_CLIENTES` y sus restricciones. `sql/10_datos_prueba.sql` inserta a Ana y las demás personas. El INSERT/UPDATE de la pantalla vive en el repositorio Python: no hay un procedimiento PL/SQL de alta o edición de clientes.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La tabla es la estructura y las filas son las fichas de los clientes. Aquí consulto y edito a Ana. Las restricciones impiden datos inválidos o repetidos».

**Pregunta probable:** ¿Por qué no puedes registrar dos veces su DNI? **Respuesta:** La restricción `UQ_CLIENTES_DNI` impide duplicarlo, aunque se intente fuera de la pantalla.

**Fragmento real.** [sql/01_tablas.sql](../sql/01_tablas.sql), líneas 8–19.

<!-- fuente-literal: sql/01_tablas.sql:8:19 -->
```sql
CREATE TABLE TBL_CLIENTES (
    ID_CLIENTE NUMBER(10),
    DNI VARCHAR2(8) CONSTRAINT CK_CLIENTES_DNI_NN NOT NULL,
    NOMBRES VARCHAR2(100 CHAR) CONSTRAINT CK_CLIENTES_NOMBRES_NN NOT NULL,
    APELLIDOS VARCHAR2(100 CHAR) CONSTRAINT CK_CLIENTES_APELLIDOS_NN NOT NULL,
    EMAIL VARCHAR2(254 CHAR) CONSTRAINT CK_CLIENTES_EMAIL_NN NOT NULL,
    CATEGORIA VARCHAR2(7) DEFAULT 'BASICO'
        CONSTRAINT CK_CLIENTES_CATEGORIA_NN NOT NULL,
    FECHA_REGISTRO DATE DEFAULT SYSDATE
        CONSTRAINT CK_CLIENTES_FECHA_NN NOT NULL,
    CONSTRAINT PK_CLIENTES PRIMARY KEY (ID_CLIENTE),
    CONSTRAINT UQ_CLIENTES_DNI UNIQUE (DNI),
```

## Punto 3. Vistas

### 1. ¿Qué es?

Una vista guarda una forma de consultar datos. Presenta juntos datos que pueden venir de varias tablas. **Analogía:** una ventana desde la que ves varias carpetas sin mover sus documentos.

### 2. ¿Dónde se ve?

En **Cuentas → ↻ Actualizar**, localiza los ahorros de Ana. Pulsa **Movimientos → Historial completo**. El listado general muestra resumen; el historial muestra sus movimientos.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`GET /api/cuentas` consulta `V_CUENTAS_RESUMEN` y la une al sinónimo `CUENTAS` para añadir el ID del titular y el tipo de cuenta. La vista reúne cuentas, clientes y totales de movimientos. Si llegaste desde un cliente, el endpoint recibe `id_cliente` y limita el listado.

Para el historial, `GET /api/cuentas/<id>/historial` verifica la cuenta con `FN_SALDO_DISPONIBLE` y consulta `V_ESTADO_CUENTA`. Ambas vistas están en `sql/04_vistas.sql`; la función está en `sql/05_funciones.sql`. Oracle devuelve filas y JavaScript dibuja la tabla. El historial completo no está limitado al mes ni a veinte movimientos.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La vista reúne información que necesito mostrar junta. Aquí veo el titular, el saldo y el resumen de actividad. No necesito copiar esa información a otra tabla».

**Pregunta probable:** ¿La vista guarda otra copia de los saldos? **Respuesta:** Estas vistas normales guardan la consulta; sus resultados se obtienen al consultarlas.

**Fragmento real.** [sql/04_vistas.sql](../sql/04_vistas.sql), líneas 21–32.

<!-- fuente-literal: sql/04_vistas.sql:21:32 -->
```sql
CREATE OR REPLACE VIEW V_CUENTAS_RESUMEN AS
SELECT c.ID_CUENTA,
       c.NRO_CUENTA,
       cli.NOMBRES || ' ' || cli.APELLIDOS AS TITULAR,
       cli.CATEGORIA,
       c.SALDO,
       c.ESTADO,
       COUNT(m.ID_MOVIMIENTO) AS CANTIDAD_MOVIMIENTOS,
       NVL(SUM(CASE WHEN m.TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES')
                    THEN m.MONTO ELSE 0 END), 0) AS TOTAL_DEPOSITADO,
       NVL(SUM(CASE WHEN m.TIPO IN ('RETIRO','TRANSF_ENVIADA','COMISION')
                    THEN m.MONTO ELSE 0 END), 0) AS TOTAL_RETIRADO
```

## Punto 4. Secuencias

### 1. ¿Qué es?

Una secuencia entrega números nuevos para identificar registros. **Analogía:** el dispensador de turnos de una oficina.

### 2. ¿Dónde se ve?

En **Cuentas → + Abrir cuenta**, elige a Ana en **Titular**. Selecciona **Corriente**, deja **Depósito inicial (S/)** en `0` y la tasa opcional vacía. Pulsa **Abrir cuenta** y observa el número recibido. Esta será una cuenta adicional; sigue usando los ahorros originales de Ana para transferir.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`POST /api/cuentas` llama `SP_ABRIR_CUENTA`, de `sql/07_procedimientos.sql`. Al insertar la cuenta, Oracle ejecuta `TRG_CUENTAS_BI`, de `sql/06_triggers.sql`. El trigger pide **una vez** `SQ_CUENTA.NEXTVAL`, asigna el ID y construye el número con prefijo `191-`.

`SQ_CUENTA`, de `sql/02_secuencias.sql`, empezó en 1000 y avanza de diez en diez. El procedimiento devuelve ID y número, Flask confirma y aparece el resultado. Con apertura cero no se inserta un depósito inicial. No prometas el próximo número: un rollback no devuelve los turnos consumidos.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El número lo asigna Oracle, no lo escribo yo. La secuencia entrega el identificador y el trigger forma el número de cuenta. Por eso dos aperturas no deben compartir el mismo turno».

**Pregunta probable:** ¿Por qué puede haber saltos? **Respuesta:** Las secuencias no recuperan números al revertir una transacción; no garantizan números sin huecos.

**Fragmento real.** [sql/06_triggers.sql](../sql/06_triggers.sql), líneas 22–31.

<!-- fuente-literal: sql/06_triggers.sql:22:31 -->
```sql
CREATE OR REPLACE TRIGGER TRG_CUENTAS_BI
BEFORE INSERT ON TBL_CUENTAS
FOR EACH ROW
DECLARE
    v_id TBL_CUENTAS.ID_CUENTA%TYPE;
BEGIN
    v_id := SQ_CUENTA.NEXTVAL;
    :NEW.ID_CUENTA := v_id;
    :NEW.NRO_CUENTA := '191-' || LPAD(v_id, 8, '0');
END TRG_CUENTAS_BI;
```

## Punto 5. Sinónimos

### 1. ¿Qué es?

Un sinónimo da otro nombre a un objeto. **Analogía:** el apodo corto que usas para encontrar una carpeta con nombre largo.

### 2. ¿Dónde se ve?

En **Cuentas**, pulsa **Movimientos** en los ahorros originales de Ana. Cambia de **Historial completo** a **Últimos movimientos**. Esta segunda pestaña muestra hasta veinte movimientos.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`GET /api/cuentas/<id>/movimientos` llega a `app/repositories/movimiento_repo.py`. Primero llama `FN_SALDO_DISPONIBLE` para comprobar la cuenta. Luego ejecuta un SELECT sobre `MOVIMIENTOS`, ordenado del más reciente al más antiguo, con límite por defecto de veinte.

Oracle resuelve `MOVIMIENTOS` como `TBL_MOVIMIENTOS`, según `sql/09_sinonimos.sql`. La función está en `sql/05_funciones.sql`. Se devuelven las filas y la pantalla cambia de tabla. El sinónimo no copia datos, no da permisos y no es un mecanismo de seguridad.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La aplicación consulta MOVIMIENTOS, que es el nombre corto de la tabla real. Los datos siguen siendo los mismos. Esta pestaña trae solo los veinte más recientes».

**Pregunta probable:** ¿Es igual que una vista? **Respuesta:** No. El sinónimo da un nombre alternativo; la vista define una consulta.

**Fragmento real.** [sql/09_sinonimos.sql](../sql/09_sinonimos.sql), líneas 11–12.

<!-- fuente-literal: sql/09_sinonimos.sql:11:12 -->
```sql
-- @OBJETO: MOVIMIENTOS
CREATE OR REPLACE SYNONYM MOVIMIENTOS FOR TBL_MOVIMIENTOS;
```

## Punto 6. Cursores explícitos

### 1. ¿Qué es?

Es recorrer resultados controlando cuándo abrir, leer y cerrar el recorrido. **Analogía:** revisar boletas una por una y cerrar la carpeta al terminar.

### 2. ¿Dónde se ve?

En **Cuentas → Estado mensual** de los ahorros de Ana, o en **Estado de cuenta**, selecciona esa cuenta. Elige el mes y año de los movimientos reales. Pulsa **Consultar estado de cuenta ↗**. Observa **Monto** y **Saldo acumulado**.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`GET /api/estado-cuenta/<id>?anio=<año>&mes=<mes>` ejecuta un SELECT sobre `TABLE(FN_ESTADO_CUENTA_MENSUAL(...))`. La función de `sql/08_funcion_pipelined.sql` valida el periodo y la cuenta. Calcula el saldo anterior al mes, abre `c_movimientos`, lee cada fila con FETCH y termina cuando `%NOTFOUND` indica que no hay otra.

Por cada movimiento suma o resta y entrega una fila con `PIPE ROW`. Usa los tipos `T_MOV_FILA` y `T_MOV_TABLA`, de `sql/03_tipos.sql`. Cierra el cursor y Flask devuelve las filas. Si no hay movimientos, la pantalla informa que no hay resultados; no inventa un saldo de cierre.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Aquí controlo el recorrido: abro, leo y cierro el cursor. El saldo parte de lo que había antes del mes. Después incorpora cada abono o cargo».

**Pregunta probable:** ¿Por qué no partes del saldo actual? **Respuesta:** Porque el saldo actual puede incluir movimientos posteriores al mes consultado.

**Fragmento real.** [sql/08_funcion_pipelined.sql](../sql/08_funcion_pipelined.sql), líneas 31–42.

<!-- fuente-literal: sql/08_funcion_pipelined.sql:31:42 -->
```sql
    OPEN c_movimientos;
    LOOP
        FETCH c_movimientos INTO v_mov;
        EXIT WHEN c_movimientos%NOTFOUND;
        IF v_mov.TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN
            v_saldo := v_saldo + v_mov.MONTO;
        ELSE
            v_saldo := v_saldo - v_mov.MONTO;
        END IF;
        PIPE ROW(T_MOV_FILA(v_mov.FECHA,v_mov.TIPO,v_mov.DESCRIPCION,v_mov.MONTO,v_saldo));
    END LOOP;
    CLOSE c_movimientos;
```

## Punto 7. Cursores implícitos

### 1. ¿Qué es?

Oracle controla automáticamente la ejecución de una sentencia y permite consultar su resultado. **Analogía:** un contador que informa cuántas entradas se registraron después de una actividad.

### 2. ¿Dónde se ve?

En **Intereses y categorías → Intereses mensuales**, elige **Mes** y **Año**. Pulsa **Revisar aplicación de intereses ↗** y luego **Confirmar intereses**. Lee las cantidades de cuentas actualizadas y omitidas.

Este proceso alcanza todas las cuentas activas elegibles, no solo a Ana. En el ensayo comprueba qué periodo usarás. Cero cuentas actualizadas también es un resultado válido.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

La revisión solo abre un diálogo. Confirmar envía `POST /api/intereses/aplicar` y llama `SP_APLICAR_INTERESES`, en `sql/07_procedimientos.sql`. Bloquea cuentas activas con `WAIT 5`. Evalúa saldo, tasa y último periodo; calcula el interés e inserta movimientos solo si el importe redondeado es positivo. Los triggers de `sql/06_triggers.sql` mantienen saldo y auditoría.

Un UPDATE marca el periodo solo en las cuentas que recibieron interés. Inmediatamente después, `SQL%ROWCOUNT` cuenta filas y `SQL%FOUND` indica si hubo alguna. Devuelve los conteos, Flask confirma y la pantalla los muestra. Repetir el mismo periodo no duplica intereses. La fecha del movimiento es la del momento de ejecución; elegir otro mes de referencia no cambia esa fecha.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «No abro un cursor para contar este UPDATE. Oracle me informa cuántas filas afectó con SQL%ROWCOUNT. Leo ese valor inmediatamente después de la sentencia».

**Pregunta probable:** ¿Qué pasa si ejecutas otra sentencia antes de leerlo? **Respuesta:** Los atributos SQL se referirán a esa nueva sentencia; por eso se guardan enseguida.

**Fragmento real.** [sql/07_procedimientos.sql](../sql/07_procedimientos.sql), líneas 358–367.

<!-- fuente-literal: sql/07_procedimientos.sql:358:367 -->
```sql
    UPDATE TBL_CUENTAS SET FECHA_ULT_INTERES = v_mes
    WHERE ESTADO = 'ACTIVA' AND TASA_INTERES_ANUAL > 0 AND SALDO > 0
      AND (FECHA_ULT_INTERES IS NULL OR FECHA_ULT_INTERES < v_mes)
      AND ID_CUENTA IN (SELECT ids.ID_CUENTA FROM
          JSON_TABLE(v_ids_json, '$[*]' COLUMNS (ID_CUENTA NUMBER PATH '$')) ids);
    p_n_cuentas := SQL%ROWCOUNT;
    v_encontradas := SQL%FOUND;
    IF NOT v_encontradas THEN p_n_cuentas := 0; END IF;
    p_n_omitidas := v_activas - p_n_cuentas;
    p_mensaje := 'Se actualizaron ' || p_n_cuentas || ' cuentas (' || p_n_omitidas || ' omitidas)';
```

## Punto 8. Cursores con parámetros y anidados

### 1. ¿Qué es?

Un cursor con parámetros recibe qué datos debe buscar. Anidar recorridos significa hacer uno dentro de otro. **Analogía:** abrir la carpeta de un cliente, después sus cuentas y después las boletas de cada cuenta.

### 2. ¿Dónde se ve?

En **Reporte de clientes**, selecciona Ana en **Cliente**. Deja **Últimos movimientos por cuenta** en `5`. Pulsa **Generar reporte ↗** y expande las cuentas del cliente.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`GET /api/reporte/clientes?id_cliente=<Ana>&limite_movs=5` llama `SP_REPORTE_CLIENTES`, de `sql/07_procedimientos.sql`. Recorre `c_clientes`. Para cada cliente abre el recorrido `c_cuentas` con su ID. Para cada cuenta usa `c_movs` con el ID de cuenta y el límite.

Oracle construye un JSON con los tres niveles y lo devuelve en un CLOB, un texto grande. El backend lo lee antes de devolver la conexión y lo convierte a datos JSON. JavaScript dibuja el árbol. El límite de cinco corresponde a **cada cuenta**, no a todo el reporte. Este árbol no equivale al historial completo ni al estado mensual.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «El reporte sigue la relación cliente, cuentas y movimientos. Cada recorrido recibe el identificador del nivel anterior. Así los movimientos quedan dentro de su cuenta correcta».

**Pregunta probable:** ¿Por qué pasas el ID y no el nombre? **Respuesta:** El ID identifica al registro; dos personas podrían tener el mismo nombre.

**Fragmento real.** [sql/07_procedimientos.sql](../sql/07_procedimientos.sql), líneas 445–453.

<!-- fuente-literal: sql/07_procedimientos.sql:445:453 -->
```sql
    CURSOR c_clientes IS SELECT ID_CLIENTE,NOMBRES,APELLIDOS,CATEGORIA FROM TBL_CLIENTES
        WHERE p_id_cliente IS NULL OR ID_CLIENTE = p_id_cliente ORDER BY ID_CLIENTE;
    CURSOR c_cuentas(p_cli NUMBER) IS SELECT ID_CUENTA,NRO_CUENTA,SALDO,ESTADO
        FROM TBL_CUENTAS WHERE ID_CLIENTE = p_cli ORDER BY ID_CUENTA;
    CURSOR c_movs(p_cta NUMBER,p_limite NUMBER) IS
        SELECT ID_MOVIMIENTO,TIPO,MONTO,FECHA,DESCRIPCION FROM (
            SELECT ID_MOVIMIENTO,TIPO,MONTO,FECHA,DESCRIPCION FROM TBL_MOVIMIENTOS
            WHERE ID_CUENTA = p_cta ORDER BY FECHA DESC,ID_MOVIMIENTO DESC
        ) WHERE ROWNUM <= p_limite;
```

## Punto 9. Bloques anónimos

### 1. ¿Qué es?

Es un grupo de instrucciones que se ejecuta sin guardarse como un procedimiento con nombre en Oracle. **Analogía:** una hoja de trabajo que completas para obtener un resultado puntual.

### 2. ¿Dónde se ve?

En **Simulador de ahorro**, elige los ahorros de Ana en **Usar una cuenta · opcional**. Coloca **Meses: 12**, **Aporte mensual (S/): 100** y **Tu meta (S/): 5000**. Pulsa **Simular mi ahorro ↗**. Otra muestra está en **Clientes → Ver resumen** de Ana.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`POST /api/simulador` pasa por `simulador_service.py` y `reporte_repo.py`. El adaptador de `app/repositories/base.py` carga el bloque autorizado `BLOQUE_SIMULADOR_INTERES`, desde `sql/bloques/simulador_interes.sql`, y lo ejecuta con parámetros de entrada y salida separados del texto SQL.

Oracle lee el saldo y la tasa de la cuenta elegida. Calcula la proyección y busca cuántos meses necesita para la meta. Devuelve saldo final, meses y un JSON con la proyección. Flask lee el CLOB y la pantalla muestra gráfico y tabla. El bloque no inserta movimientos ni cambia saldos; el servicio termina como lectura con rollback.

El resumen usa `GET /api/clientes/<id>/resumen` y `BLOQUE_RESUMEN_CLIENTE`, en `sql/bloques/resumen_cliente.sql`. Suma las cuentas de Ana y usa los límites vigentes para informar nivel y cuánto falta para el siguiente.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Este bloque calcula una proyección sin mover dinero. Si selecciono una cuenta, usa sus datos actuales. El navegador solo representa los resultados que devuelve Oracle».

**Pregunta probable:** ¿Por qué lo llamas anónimo si aparece BLOQUE_SIMULADOR_INTERES? **Respuesta:** Ese nombre identifica el archivo en el índice de la app; no es un procedimiento almacenado con ese nombre en Oracle.

**Fragmento real.** [sql/bloques/simulador_interes.sql](../sql/bloques/simulador_interes.sql), líneas 17–25.

<!-- fuente-literal: sql/bloques/simulador_interes.sql:17:25 -->
```sql
BEGIN
    :p_saldo_final := NULL; :p_meses_meta := NULL; :p_proyeccion := NULL;
    :p_estado := 'OK'; :p_codigo := 0; :p_mensaje := 'Simulación completada.';
    IF :p_id_cuenta IS NOT NULL THEN
        SELECT * INTO v_cuenta FROM TBL_CUENTAS WHERE ID_CUENTA = :p_id_cuenta;
        v_inicial := v_cuenta.SALDO; v_tasa := NVL(v_cuenta.TASA_INTERES_ANUAL,0);
    ELSE
        v_inicial := :p_saldo_inicial; v_tasa := :p_tasa_anual;
    END IF;
```

## Punto 10. Variables, constantes, %TYPE y %ROWTYPE

### 1. ¿Qué es?

Una variable conserva un valor que puede cambiar; una constante mantiene un valor fijo durante la ejecución. `%TYPE` toma el tipo de una columna y `%ROWTYPE` agrupa los campos de una fila. **Analogía:** casilleros para valores, una etiqueta fija y una carpeta con casilleros del mismo formato que la ficha original.

### 2. ¿Dónde se ve?

Reutiliza la simulación anterior: **Simulador de ahorro → cuenta de Ana → Simular mi ahorro ↗**. En **Ver código PL/SQL ↗**, selecciona `BLOQUE_SIMULADOR_INTERES` y muestra sus declaraciones.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

El mismo `POST /api/simulador` ejecuta `sql/bloques/simulador_interes.sql`. `v_cuenta` recibe una fila de la tabla de cuentas mediante `%ROWTYPE`. `v_inicial` y `v_tasa` usan los tipos de sus columnas mediante `%TYPE`.

Las constantes establecen doce meses por año y un máximo de seiscientos meses. Las variables guardan saldos, aporte y avance del cálculo. Después Oracle devuelve el resultado y la pantalla lo presenta. Elegir una cuenta desactiva los campos manuales de saldo y tasa; el bloque toma esos valores de Oracle.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Las variables guardan el avance del cálculo. Las constantes fijan sus límites. Con %TYPE y %ROWTYPE mantengo el formato de las columnas y de la fila original».

**Pregunta probable:** ¿Qué ventaja tiene %TYPE? **Respuesta:** Evita declarar por separado un tipo que podría quedar distinto del de la columna.

**Fragmento real.** [sql/bloques/simulador_interes.sql](../sql/bloques/simulador_interes.sql), líneas 3–10.

<!-- fuente-literal: sql/bloques/simulador_interes.sql:3:10 -->
```sql
    c_max_meses CONSTANT PLS_INTEGER := 600;
    c_meses_anio CONSTANT NUMBER := 12;
    v_cuenta TBL_CUENTAS%ROWTYPE;
    v_inicial TBL_CUENTAS.SALDO%TYPE;
    v_tasa TBL_CUENTAS.TASA_INTERES_ANUAL%TYPE;
    v_saldo NUMBER;
    v_saldo_meta NUMBER;
    v_aporte NUMBER := :p_aporte_mensual;
```

## Punto 11. FOR, LOOP y WHILE

### 1. ¿Qué es?

Son formas de repetir instrucciones. `FOR` recorre una cantidad o lista; `LOOP` repite hasta una salida explícita; `WHILE` continúa mientras se cumpla una condición. **Analogía:** contar doce cuotas, atender fichas hasta que se acaben o ahorrar mientras falte para una meta.

### 2. ¿Dónde se ve?

**FOR y WHILE:** en **Simulador de ahorro → Simular mi ahorro ↗**. Compara **Plazo de la proyección** con **Tiempo hasta tu meta**.

**LOOP:** en **Intereses y categorías → Categorías de clientes → Actualizar categorías de clientes**. El botón actual ejecuta el proceso directamente; no hay botón «Recalcular» ni tabla previa de revisión de clientes.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

El simulador ejecuta un FOR por los meses solicitados. Después usa un WHILE para buscar la meta, hasta un máximo de 600 meses. Ambos están en `sql/bloques/simulador_interes.sql`; el resultado vuelve a la tabla y al gráfico.

El segundo botón envía `POST /api/categorias/actualizar`. El repositorio bloquea la configuración con `WAIT 5` para mantener los mismos límites durante el proceso. `SP_ACTUALIZAR_CATEGORIAS`, en `sql/07_procedimientos.sql`, abre `c_clientes`, hace LOOP, FETCH y `EXIT WHEN ... %NOTFOUND`. Suma los saldos de cada cliente, llama `FN_CATEGORIA_CLIENTE` y actualiza solo las categorías diferentes. Cierra el cursor y devuelve procesados/cambios. Flask confirma y muestra esos conteos. Procesa todos los clientes, no solo a Ana.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Uso FOR para construir los meses de la proyección. Uso WHILE para seguir buscando la meta mientras falte y no llegue al límite. Uso LOOP para recorrer los clientes hasta que no haya otra fila».

**Pregunta probable:** ¿Por qué el tiempo hasta la meta puede superar los doce meses elegidos? **Respuesta:** El plazo de la proyección y la búsqueda de la meta son cálculos separados; la meta se busca hasta 600 meses.

**Fragmento real.** [sql/bloques/simulador_interes.sql](../sql/bloques/simulador_interes.sql), líneas 35–45.

<!-- fuente-literal: sql/bloques/simulador_interes.sql:35:45 -->
```sql
    FOR i IN 1 .. v_meses LOOP
        -- Capitalización mensual redondeada; aporte al final de cada mes.
        v_saldo := ROUND(v_saldo * (1 + v_tasa / 100 / c_meses_anio) + v_aporte,2);
        v_fila := JSON_OBJECT_T(); v_fila.PUT('mes',i); v_fila.PUT('saldo',v_saldo);
        v_proyeccion_json.APPEND(v_fila);
    END LOOP;
    v_saldo_meta := v_inicial;
    WHILE v_saldo_meta < v_meta AND v_mes < c_max_meses LOOP
        v_saldo_meta := ROUND(v_saldo_meta * (1 + v_tasa / 100 / c_meses_anio) + v_aporte,2);
        v_mes := v_mes + 1;
    END LOOP;
```

## Punto 12. IF, ELSIF y ELSE

### 1. ¿Qué es?

Son decisiones: comprobar una condición y elegir qué camino ejecutar. **Analogía:** un cruce con tres caminos y un cartel que indica cuál tomar.

### 2. ¿Dónde se ve?

En **Intereses y categorías → Categorías de clientes**, observa los límites visibles. En **Saldo total (S/)** escribe un importe y pulsa **Consultar categoría**. Para mantener la historia, puedes usar primero el saldo total actual de Ana, obtenido con **Clientes → Ver resumen**.

Con los límites iniciales, prueba también `4999.99`, `5000` y `50000`: devuelven BASICO, GOLD y PREMIUM. Si editaste los límites, usa los valores vigentes; esas respuestas fijas ya no están garantizadas.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`GET /api/categoria?saldo=<importe>` llama `FN_CATEGORIA_CLIENTE`, en `sql/05_funciones.sql`. La función lee Gold y Premium desde `TBL_LIMITES_CATEGORIAS`, creada por `sql/11_limites_categorias.sql`. Compara el saldo: por debajo de Gold devuelve BASICO; por debajo de Premium devuelve GOLD; en otro caso devuelve PREMIUM. La respuesta aparece como una etiqueta.

Consultar no actualiza ningún cliente. **Editar límites → Guardar límites → Guardar límites** permite revisar y confirmar nuevos umbrales. El primer Guardar abre el diálogo y el segundo confirma el PUT a `/api/categorias/limites`. Guardar cambia la configuración, no las categorías registradas. **Actualizar categorías de clientes** es la acción que las aplica a los saldos reales.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La función toma una sola rama según el saldo y los límites vigentes. Consultar muestra una respuesta, pero no cambia a Ana. Guardar límites y actualizar las categorías son acciones distintas».

**Pregunta probable:** ¿Qué categoría recibe alguien exactamente en el límite de Gold? **Respuesta:** GOLD, porque BASICO solo incluye los saldos menores que ese límite.

**Fragmento real.** [sql/05_funciones.sql](../sql/05_funciones.sql), líneas 48–56.

<!-- fuente-literal: sql/05_funciones.sql:48:56 -->
```sql
    SELECT LIMITE_GOLD,LIMITE_PREMIUM INTO v_gold,v_premium
    FROM TBL_LIMITES_CATEGORIAS WHERE ID_CONFIG=1;
    IF NVL(p_saldo_total, 0) < v_gold THEN
        RETURN 'BASICO';
    ELSIF p_saldo_total < v_premium THEN
        RETURN 'GOLD';
    ELSE
        RETURN 'PREMIUM';
    END IF;
```

## Punto 13. Procedimientos con parámetros IN y OUT

### 1. ¿Qué es?

Un procedimiento agrupa los pasos de una tarea. `IN` recibe datos y `OUT` devuelve resultados a quien lo llamó. **Analogía:** entregar una solicitud en ventanilla y recibir el número del trámite y su resultado.

### 2. ¿Dónde se ve?

Usa la apertura de la cuenta adicional de Ana del punto 4: **Cuentas → + Abrir cuenta → Titular Ana → Corriente → depósito 0 → Abrir cuenta**. No abras otra cuenta solo por volver a explicar este punto. Muestra el resultado de la misma apertura.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`POST /api/cuentas` llega a `banca_service.abrir_cuenta`, después a `cuenta_repo.abrir` y a `SP_ABRIR_CUENTA`, en `sql/07_procedimientos.sql`. Recibe ID del cliente, tipo, saldo inicial y tasa opcional. Valida al titular y el importe. Si no se envía tasa, usa 3.00% para AHORROS o 0.50% para CORRIENTE.

Inserta la cuenta; el trigger genera ID y número. Si el depósito inicial es positivo, inserta también un movimiento. Devuelve `p_id_cuenta`, `p_nro_cuenta`, estado, código y mensaje. El adaptador Python usa variables OUT del driver. El servicio hace commit si todo fue correcto o rollback si hubo error. La pantalla muestra el número recibido.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Entrego los datos con parámetros IN. Oracle valida y realiza la apertura. Recibo el identificador, el número y el resultado mediante parámetros OUT».

**Pregunta probable:** ¿El procedimiento confirma la transacción? **Respuesta:** No. Los procedimientos de negocio no hacen COMMIT; Flask confirma cuando el resultado es correcto.

**Fragmento real.** [sql/07_procedimientos.sql](../sql/07_procedimientos.sql), líneas 5–13.

<!-- fuente-literal: sql/07_procedimientos.sql:5:13 -->
```sql
    p_id_cliente IN NUMBER,
    p_tipo IN VARCHAR2,
    p_saldo_inicial IN NUMBER DEFAULT 0,
    p_tasa IN NUMBER DEFAULT NULL,
    p_id_cuenta OUT NUMBER,
    p_nro_cuenta OUT VARCHAR2,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
```

## Punto 14. Funciones

### 1. ¿Qué es?

Una función recibe datos y devuelve un resultado con `RETURN`. **Analogía:** una calculadora a la que das valores y de la que obtienes una respuesta.

### 2. ¿Dónde se ve?

En **Operaciones → Transferencia**, selecciona los ahorros originales de Ana como **Cuenta de origen**, y la corriente de Luis como **Cuenta de destino**. Escribe **Monto (S/): 100** y espera la comisión.

Muestra la cotización antes de confirmar. Luego pulsa **Revisar transferencia ↗ → Confirmar transferencia** una sola vez. Esta misma transferencia sirve para explicar los triggers del punto 15.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

Elegir el origen consulta `GET /api/cuentas/<id>/saldo` y `FN_SALDO_DISPONIBLE`. Al escribir el monto, JavaScript espera 300 milisegundos y consulta `GET /api/comision?monto=100&id_cuenta=<Ana>`. El repositorio lee la categoría registrada del titular mediante `CUENTAS` y `CLIENTES`, y llama `FN_COMISION`. Ambas funciones están en `sql/05_funciones.sql`.

Oracle elige la tasa por categoría y aplica comisión mínima de S/ 1.00 y redondeo a dos decimales. Python suma monto y comisión para presentar el total; no vuelve a calcular la regla de comisión. La revisión no escribe. Confirmar envía `POST /api/transferir` a `SP_TRANSFERIR`, de `sql/07_procedimientos.sql`, que vuelve a calcular y validar antes de insertar movimientos. Flask confirma y muestra el resultado real.

Si Ana sigue registrada como BASICO, S/ 100 tiene comisión de S/ 1.50: su débito es S/ 101.50 y Luis recibe S/ 100. La cotización no reserva saldo ni garantiza una categoría que pueda cambiar antes de confirmar.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «La función devuelve la comisión calculada en Oracle. Aquí la muestro antes de confirmar. El procedimiento vuelve a validarla cuando realiza la transferencia».

**Pregunta probable:** ¿Cuál es la diferencia frente a un procedimiento? **Respuesta:** La función devuelve un valor con RETURN; el procedimiento realiza un trámite y aquí comunica sus resultados mediante OUT.

**Fragmento real.** [sql/05_funciones.sql](../sql/05_funciones.sql), líneas 75–83.

<!-- fuente-literal: sql/05_funciones.sql:75:83 -->
```sql
    IF UPPER(TRIM(p_categoria)) = 'PREMIUM' THEN
        v_tasa := c_tasa_premium;
    ELSIF UPPER(TRIM(p_categoria)) = 'GOLD' THEN
        v_tasa := c_tasa_gold;
    ELSE
        -- Categoría nula o desconocida usa la tarifa BASICO.
        v_tasa := c_tasa_basico;
    END IF;
    RETURN ROUND(GREATEST(p_monto * v_tasa, c_minimo), 2);
```

## Punto 15. Triggers BEFORE y AFTER

### 1. ¿Qué es?

Un trigger se ejecuta automáticamente cuando ocurre un cambio en una tabla. BEFORE actúa antes y AFTER después del cambio indicado. **Analogía:** una puerta automática que verifica el pase al entrar y luego registra la entrada.

### 2. ¿Dónde se ve?

Observa la misma transferencia de Ana a Luis. Después entra en **Cuentas → Movimientos → Historial completo** de Ana y de Luis. En **Auditoría y registro de errores → Auditoría → ↻ Actualizar registros**, revisa los movimientos de esa operación.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`SP_TRANSFERIR` bloquea ambas cuentas por orden de ID con `WAIT 5`. Comprueba estado, saldo y comisión. Inserta tres movimientos: TRANSF_ENVIADA y COMISION en origen; TRANSF_RECIBIDA en destino.

Cada INSERT dispara `TRG_MOVIMIENTOS_BI`: valida el monto, asigna secuencia y fecha, y calcula el saldo posterior. Después, `TRG_MOVIMIENTOS_AI` actualiza el saldo de la cuenta e inserta auditoría. Ambos están en `sql/06_triggers.sql`. El AFTER del envío ya cambió el saldo cuando el BEFORE calcula el saldo posterior del movimiento COMISION. La comisión como importe se calculó antes de las inserciones. El procedimiento no descuenta otra vez el dinero.

Flask confirma las tres inserciones como una operación. Consultar historial y auditoría solo lee sus efectos. Si la transferencia falla y se revierte, no conserva una parte del envío ni su auditoría normal. El log autónomo de errores sí puede permanecer.

Otros triggers reales: `TRG_CLIENTES_BI` normaliza nombres y asigna ID; `TRG_CUENTAS_BI` genera ID/número; `TRG_CUENTAS_AU` audita cambios reales de estado. El último no se dispara al actualizar saldo o fecha de interés.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Los triggers se activan por cada movimiento, sin un botón separado. El BEFORE prepara y valida la fila. El AFTER mantiene el saldo y deja la auditoría».

**Pregunta probable:** ¿Por qué no hay error de tabla mutante? **Respuesta:** Los triggers de movimientos leen o modifican otra tabla, cuentas; el AFTER no consulta la tabla de movimientos que está cambiando.

**Fragmento real.** [sql/06_triggers.sql](../sql/06_triggers.sql), líneas 72–80.

<!-- fuente-literal: sql/06_triggers.sql:72:80 -->
```sql
BEGIN
    -- Único punto de actualización del saldo; sin consultar la tabla mutante.
    IF :NEW.TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN
        UPDATE TBL_CUENTAS SET SALDO = SALDO + :NEW.MONTO
        WHERE ID_CUENTA = :NEW.ID_CUENTA;
    ELSIF :NEW.TIPO IN ('RETIRO','TRANSF_ENVIADA','COMISION') THEN
        UPDATE TBL_CUENTAS SET SALDO = SALDO - :NEW.MONTO
        WHERE ID_CUENTA = :NEW.ID_CUENTA;
    END IF;
```

## Punto 16. Excepciones y manejo de errores

### 1. ¿Qué es?

Una excepción señala un problema para que el programa lo atienda y dé una respuesta controlada. **Analogía:** un simulacro de incendio que comprueba cómo responder sin dejar el edificio dañado.

### 2. ¿Dónde se ve?

En **Laboratorio de errores**, pulsa **División por cero**. Observa **Código Oracle**, el mensaje y **HTTP correspondiente**. Después entra en **Auditoría y registro de errores → Registro de errores → ↻ Actualizar registros**.

También existen **Sin resultados**, **Más de una fila**, **Valor duplicado**, **Conversión o tamaño**, **Error genérico** y **Capturar y relanzar**. Son siete casos estándar. Otros siete botones prueban rechazos de negocio, como **Saldo insuficiente** o **Cuenta bloqueada**.

### 3. ¿Qué pasa en Oracle cuando hago esa acción?

`POST /api/laboratorio/zero_divide` llama `SP_LAB_ERRORES`, en `sql/07_procedimientos.sql`. Provoca la división por cero y captura `ZERO_DIVIDE`. Recupera `SQLCODE` y `SQLERRM`, revierte al punto de prueba y llama `SP_LOG_ERROR`, de `sql/05_funciones.sql`.

El log usa `PRAGMA AUTONOMOUS_TRANSACTION`: guarda y confirma el error en una transacción independiente. El servicio del laboratorio siempre hace rollback de la prueba principal. La pantalla recibe el código `-1476` y el mensaje, ocultando el nombre del esquema.

La petición de una demostración correcta responde HTTP 200. El campo **HTTP correspondiente** indica cómo se clasificaría ese error fuera de la demostración; no es necesariamente el estado HTTP de esta petición. `NO_DATA_FOUND` puede mostrar SQLCODE positivo `100`.

Los casos de negocio llaman procedimientos reales con datos inválidos. Usan la primera cuenta activa por ID, no una cuenta que se elija en pantalla: no digas que siempre prueban con Ana. En la demo central usa División por cero, que no necesita elegir otra persona.

### 4. ¿Qué digo y qué me pueden preguntar?

**Para decir:** «Aquí el error es intencional y se captura. La prueba revierte sus cambios, pero el registro autónomo conserva la evidencia. La aplicación informa el resultado sin mostrar credenciales».

**Pregunta probable:** ¿El COMMIT del log confirma la transferencia fallida? **Respuesta:** No. Confirma solo la transacción independiente del registro del error.

**Fragmento real.** [sql/07_procedimientos.sql](../sql/07_procedimientos.sql), líneas 574–580.

<!-- fuente-literal: sql/07_procedimientos.sql:574:580 -->
```sql
    WHEN 'ZERO_DIVIDE' THEN
        BEGIN
            v_num := 1 / v_cero;
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN ZERO_DIVIDE THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
        END;
```

## Demo de 14 minutos: una historia, las mismas personas

No intentes leer los dieciséis apartados completos. La misma acción demuestra varios conceptos. Usa los fragmentos solo para señalar la línea clave.

### Antes de entrar al aula

- Abre la aplicación con tu procedimiento habitual. No muestres archivos privados ni el panel con credenciales.
- Comprueba Ana por DNI 71000001 y Luis por DNI 71000002. Anota cuenta AHORROS original de Ana y CORRIENTE de Luis. Ambas deben estar activas; confirma que Ana tenga saldo suficiente para monto y comisión. Si el ensayo cambió los saldos, usa lo que realmente muestra la app.
- Para ensayar este guion con la versión actual, debes tener instalada la configuración del script 11 y el 05 actualizado: también los necesitan Ver resumen y la consulta/actualización de categorías, aunque no edites límites en vivo. No se afirma que esa migración ya esté probada en tu base. Mostrar Editar límites durante la exposición es opcional; el guion principal no necesita cambiar los valores.
- Observa qué mes tiene movimientos. Para el estado mensual usa ese mes. Para intereses, recuerda que el proceso es global y que el periodo puede estar ya aplicado; explica los conteos reales, incluso si son cero. No selecciones meses futuros solo para forzar un resultado.
- Ten a mano esta guía y los SQL. No ejecutes CREATE TABLE, script 10 ni limpieza durante la demo. La nueva apertura y la transferencia sí quedan guardadas al confirmarlas; cada ensayo cambia los datos.

| Tiempo | Historia y pasos exactos | Puntos que explicas |
| --- | --- | --- |
| 0:00–1:00 | «Ana viene a revisar su relación con el banco». Resumen general → ↻ Actualizar resumen. Señala conexión y contexto de Oracle. Menciona preparación previa en FreeSQL, sin repetirla. | 1; introducción |
| 1:00–2:15 | Clientes → buscar 71000001 → Editar → Nombres `Ana`, conservar apellido/correo → Guardar cliente → Ver resumen. Explica consulta, actualización, mayúsculas y saldo total de sus cuentas. | 2; 9; adelanto de 15 |
| 2:15–3:30 | Cuentas → + Abrir cuenta → Ana → Corriente → depósito 0 → tasa vacía → Abrir cuenta. Anota el nuevo número. Señala IN/OUT y NEXTVAL. Esta es una cuenta adicional; no sustituye sus ahorros originales. | 4; 13 |
| 3:30–4:30 | Vuelve a los ahorros originales de Ana → Movimientos. Compara Historial completo con Últimos movimientos. Muestra vista y sinónimo en el selector de código. | 3; 5 |
| 4:30–6:30 | Operaciones → Transferencia → ahorros de Ana → corriente de Luis → monto 100. Espera comisión → Revisar transferencia ↗ → comprueba datos → Confirmar transferencia una sola vez. Explica las tres inserciones y los triggers. | 14; 15 |
| 6:30–7:30 | Estado de cuenta → ahorros de Ana → mes real de la transferencia → Consultar estado de cuenta ↗. Señala saldo previo, recorrido y saldo acumulado. | 6 |
| 7:30–8:30 | Reporte de clientes → Ana → límite 5 → Generar reporte ↗. Expande cuentas; la cuenta nueva de saldo cero puede no tener movimientos. | 8 |
| 8:30–10:00 | Intereses y categorías → Categorías de clientes. Consulta el saldo total de Ana y explica ramas según límites visibles. Pulsa Actualizar categorías de clientes y explica conteos. Pasa a Intereses mensuales → periodo ensayado → Revisar aplicación de intereses ↗ → Confirmar intereses. Reconoce que ambos procesos son globales. | 11 (LOOP); 12; 7 |
| 10:00–11:30 | Simulador de ahorro → ahorros de Ana → 12 meses, aporte 100, meta 5000 → Simular mi ahorro ↗. Muestra gráfico en soles, tabla, plazo y tiempo hasta meta. Abre el bloque y señala declaraciones, FOR y WHILE. | 9; 10; 11 |
| 11:30–12:30 | Auditoría y registro de errores → Auditoría → ↻ Actualizar registros. Ubica los movimientos de la transferencia por cuenta/tipo; muestra que hubo hechos registrados. El listado muestra los últimos 200, no un filtro exclusivo de Ana. | 15; trazabilidad |
| 12:30–14:00 | Laboratorio de errores → División por cero. Explica excepción capturada y HTTP correspondiente. Registro de errores → ↻ Actualizar registros. Cierra con el log independiente y con la separación pantalla/Flask/Oracle. | 16; cierre |

Total: **14 minutos**. Si necesitas acabar en 12, reduce la exposición de fragmentos y las consultas repetidas; conserva las confirmaciones y la comprobación de cuenta/monto. Si tienes 15, usa el minuto extra para **Editar límites** y **Cancelar**, sin guardar cambios adicionales.

**Frase de apertura:** «Este sistema representa operaciones bancarias para demostrar objetos y programación PL/SQL. La pantalla permite usarlos y observar sus resultados».

**Frase de cierre:** «La transferencia une procedimientos, funciones, secuencias y triggers. Los reportes muestran recorridos de datos y el laboratorio demuestra cómo se controlan los errores».

## Adaptaciones y límites que debes explicar con honestidad

Esta sección compara la versión actual con el planteamiento inicial. Una adaptación no equivale a una prueba real ya confirmada.

| Tema | Lo que existe ahora | Cómo explicarlo |
| --- | --- | --- |
| Categorías configurables | Se agregó TBL_LIMITES_CATEGORIAS y su sinónimo LIMITES_CATEGORIAS en `sql/11_limites_categorias.sql`. La función y el resumen leen límites de Oracle. Hay 40 objetos de BD y dos bloques: 42 entradas del índice. | «Inicialmente eran 5000/50000 fijos; ahora se pueden editar. La clasificación sigue en Oracle». Las tasas de comisión siguen siendo las constantes originales; editar umbrales no edita esas tasas. |
| Guardar límites frente a actualizar clientes | Editar límites, Guardar límites y Cancelar; guardado con confirmación, restricciones de orden e importes, bloqueo WAIT 5 y versión para rechazar una edición antigua. El DML usa el sinónimo desde `categoria_repo.py`. No se agregó un procedimiento o trigger de auditoría para ese guardado. | «Guardar cambia las condiciones; Actualizar categorías de clientes cambia la categoría registrada según los saldos». No afirmes que ese guardado crea una fila de auditoría. |
| Corrección del flujo de categorías | Se retiraron Revisar clientes, Recalcular y la tabla comparativa añadida temporalmente. Sigue el botón directo Actualizar categorías de clientes. | «Esta es la versión actual». No busques botones de las capturas anteriores. |
| Organización y continuidad | Siguen diez pantallas, agrupadas por tareas. Clientes enlaza cuentas y reportes mediante IDs. Cuentas admite filtro `id_cliente` y muestra titular/tipo con vista más sinónimo. | «Se reorganizó la navegación sin cambiar la relación entre clientes, cuentas y movimientos». |
| Nombres de controles | En Cuentas se entra por Movimientos, no por un botón llamado Ver historial. Dentro hay Historial completo y Últimos movimientos. Las operaciones, intereses y cambios de estado se revisan antes de confirmar. | Usa las etiquetas actuales de los pasos de esta guía. Abrir una revisión no ejecuta la escritura. La apertura de cuenta y el botón de actualizar categorías conservan su flujo directo. |
| Periodos | Mes y Año son controles propios, con Mes actual. Intereses envía YYYY-MM; el estado mensual envía año y mes separados. | «Se cambió la presentación del selector; no el criterio mensual de Oracle». |
| Simulador y reporte | El gráfico usa escala en soles desde cero y datos de la proyección de Oracle. El reporte separa cliente/cuenta/movimientos y presenta los últimos N por cuenta. | «Una curva puede parecerse a otra por sus datos; no inventamos crecimiento para que se vea diferente». El simulador no registra ahorro real. |
| Intereses de importe cero | Se omiten intereses que redondean a cero. El UPDATE de fecha se limita mediante JSON_TABLE a los IDs que recibieron movimiento. | «No registro un movimiento de monto cero, porque el trigger lo rechaza». Es un ajuste documentado de consistencia. |
| Preparación, CRUD y código visible | No se crea un usuario desde la app. CREATE se hizo al instalar. Clientes usa INSERT/UPDATE desde repositorios, no procedimientos nuevos. El modal indexa archivos locales, no la definición instalada en la nube. | «Puedo mostrar el código fuente; para afirmar que está instalado, necesito su prueba real». Los metadatos del panel no son una traza del motor. |
| Resumen general | Suma y presenta valores devueltos por Oracle; la distribución por categoría cuenta cuentas, no personas. Python suma monto y comisión para presentar el total; no replica la fórmula de comisión. | «La presentación hace sumas y formatos; las reglas de saldo, intereses, clasificación y comisión están en PL/SQL». |
| Cursores, tipos y conexión | Se mantuvieron los tipos SQL y el sinónimo previstos; no se aplicaron las contingencias sin CREATE TYPE/SYNONYM. No se implementó el ejecutor SQL automático opcional de Fase 7. | No presentes como implementados planes alternativos que solo aparecen descritos en la especificación. |
| Alcance de la evidencia | Fases originales confirmadas y Fase 6 base cerrada con la confirmación actual del usuario. Cambios recientes: pruebas locales con mocks; edición de límites y reorganización aún pendientes de confirmación real específica. Los snapshots solo comparan nombres/cantidad de tablas AD_, no contenido. | «Las pruebas automáticas no se conectan a Oracle. Distingo lo confirmado en FreeSQL de lo comprobado con datos simulados». No se leen ni alteran las tablas ajenas. |

## Si el docente cambia la pregunta

- **¿Dónde está la lógica de negocio?** En procedimientos, funciones, triggers y bloques PL/SQL. Flask valida entradas, llama a Oracle y controla la transacción.
- **¿Qué sucede si falla la tercera inserción de una transferencia?** El procedimiento revierte al savepoint y el servicio hace rollback; no se conserva un envío incompleto.
- **¿Por qué no reintentar automáticamente un POST?** Podría duplicar una operación que ya se confirmó y cuya respuesta se perdió. La app muestra resultado incierto y pide comprobar movimientos.
- **¿Es un banco listo para producción?** No. Es una aplicación académica para demostrar el temario. No implementa autenticación, roles de usuarios ni un despliegue bancario de producción.
- **¿Qué haces si no recuerdas una línea?** Abres Ver código PL/SQL, seleccionas el objeto y explicas entrada, validación, cambio y salida. No necesitas recitar el archivo completo.

## Fuentes revisadas para esta versión

Se contrastaron las rutas en `app/routes/paginas.py` y `api_banca.py`; las etiquetas en plantillas y módulos JavaScript; las llamadas en repositorios y servicios; el SQL de producción y la carga de prueba. Son referencias para mantener la guía cuando cambie la app:

- [Especificación actual](ESPECIFICACION.md), [matriz](MATRIZ_OBJETOS.md) y [reorganización](REORGANIZACION_UI_UX.md).
- [Rutas de pantallas](../app/routes/paginas.py) y [endpoints](../app/routes/api_banca.py).
- [Plantillas](../app/templates/) y [JavaScript actual](../app/static/js/).
- [Repositorios](../app/repositories/) y [transacciones](../app/services/transacciones.py).
- [Datos de prueba](../sql/10_datos_prueba.sql), [configuración de límites](../sql/11_limites_categorias.sql) y archivos SQL citados en cada punto.

La guía se preparó sin leer credenciales, ejecutar SQL contra la base, iniciar `run.py` ni consultar contenido de tablas AD_. Commits y push quedan a cargo del usuario.
