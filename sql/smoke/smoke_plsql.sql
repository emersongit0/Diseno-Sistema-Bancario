-- Pruebas manuales en FreeSQL, siempre como SCRIPT.
-- Ejecutar solo la sección de la fase solicitada. No ejecutar desde Python.
-- F1 no inserta datos ni consume secuencias y se puede repetir.

-- ===== INICIO F1: tablas, secuencias y tipos =====
-- Después de ejecutar 01_tablas.sql, 02_secuencias.sql y 03_tipos.sql.
-- Resultado esperado: 12 filas VALID: 5 TABLE, 5 SEQUENCE y 2 TYPE.
SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN ('TBL_CLIENTES', 'TBL_CUENTAS', 'TBL_MOVIMIENTOS', 'TBL_AUDITORIA', 'TBL_LOG_ERRORES', 'SQ_CLIENTE', 'SQ_CUENTA', 'SQ_MOVIMIENTO', 'SQ_AUDITORIA', 'SQ_LOG', 'T_MOV_FILA', 'T_MOV_TABLA')
ORDER BY object_type, object_name;

-- Resultado esperado: cero filas. Se limita a los objetos de esta fase.
SELECT name, type, line, position, text
FROM USER_ERRORS
WHERE name IN ('TBL_CLIENTES', 'TBL_CUENTAS', 'TBL_MOVIMIENTOS', 'TBL_AUDITORIA', 'TBL_LOG_ERRORES', 'SQ_CLIENTE', 'SQ_CUENTA', 'SQ_MOVIMIENTO', 'SQ_AUDITORIA', 'SQ_LOG', 'T_MOV_FILA', 'T_MOV_TABLA')
ORDER BY name, sequence;

DECLARE
    v_total PLS_INTEGER;
    v_fila T_MOV_FILA;
    v_movimientos T_MOV_TABLA;
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20981, 'F1: ' || p_mensaje);
        END IF;
    END;
BEGIN
    SELECT COUNT(*) INTO v_total FROM USER_OBJECTS
    WHERE object_name IN ('TBL_CLIENTES', 'TBL_CUENTAS', 'TBL_MOVIMIENTOS', 'TBL_AUDITORIA', 'TBL_LOG_ERRORES', 'SQ_CLIENTE', 'SQ_CUENTA', 'SQ_MOVIMIENTO', 'SQ_AUDITORIA', 'SQ_LOG', 'T_MOV_FILA', 'T_MOV_TABLA') AND status = 'VALID'
      AND ((object_name LIKE 'TBL!_%' ESCAPE '!' AND object_type = 'TABLE')
        OR (object_name LIKE 'SQ!_%' ESCAPE '!' AND object_type = 'SEQUENCE')
        OR (object_name IN ('T_MOV_FILA','T_MOV_TABLA') AND object_type = 'TYPE'));
    exigir(v_total = 12, 'Se requieren 5 tablas, 5 secuencias y 2 tipos VALID.');

    SELECT COUNT(*) INTO v_total FROM USER_ERRORS
    WHERE name IN ('TBL_CLIENTES', 'TBL_CUENTAS', 'TBL_MOVIMIENTOS', 'TBL_AUDITORIA', 'TBL_LOG_ERRORES', 'SQ_CLIENTE', 'SQ_CUENTA', 'SQ_MOVIMIENTO', 'SQ_AUDITORIA', 'SQ_LOG', 'T_MOV_FILA', 'T_MOV_TABLA');
    exigir(v_total = 0, 'USER_ERRORS contiene errores de los objetos de F1.');

    SELECT COUNT(*) INTO v_total FROM USER_CONSTRAINTS
    WHERE table_name IN ('TBL_CLIENTES','TBL_CUENTAS','TBL_MOVIMIENTOS','TBL_AUDITORIA','TBL_LOG_ERRORES')
      AND constraint_name IN (
        'PK_CLIENTES','UQ_CLIENTES_DNI','UQ_CLIENTES_EMAIL',
        'CK_CLIENTES_DNI','CK_CLIENTES_CATEGORIA',
        'PK_CUENTAS','UQ_CUENTAS_NRO','FK_CUENTAS_CLIENTE',
        'CK_CUENTAS_TIPO','CK_CUENTAS_ESTADO','CK_CUENTAS_SALDO',
        'PK_MOVIMIENTOS','FK_MOV_CUENTA','FK_MOV_CUENTA_REL','CK_MOV_TIPO',
        'PK_AUDITORIA','PK_LOG_ERRORES')
      AND status = 'ENABLED' AND validated = 'VALIDATED';
    exigir(v_total = 17, 'Faltan restricciones obligatorias habilitadas y validadas.');

    SELECT COUNT(*) INTO v_total FROM USER_CONSTRAINTS
    WHERE table_name IN ('TBL_CLIENTES','TBL_CUENTAS','TBL_MOVIMIENTOS','TBL_AUDITORIA','TBL_LOG_ERRORES')
      AND generated = 'GENERATED NAME';
    exigir(v_total = 0, 'Todas las restricciones deben tener nombre explícito.');

    SELECT COUNT(*) INTO v_total FROM USER_TAB_COMMENTS
    WHERE table_name IN ('TBL_CLIENTES','TBL_CUENTAS','TBL_MOVIMIENTOS','TBL_AUDITORIA','TBL_LOG_ERRORES')
      AND comments IS NOT NULL;
    exigir(v_total = 5, 'Las cinco tablas deben tener COMMENT ON.');

    SELECT COUNT(*) INTO v_total FROM USER_SEQUENCES
    WHERE sequence_name = 'SQ_CUENTA' AND increment_by = 10 AND cache_size = 0
      AND cycle_flag = 'N' AND last_number = 1000;
    exigir(v_total = 1, 'SQ_CUENTA debe iniciar en 1000, incrementar 10 y ser NOCACHE.');

    SELECT COUNT(*) INTO v_total FROM USER_SEQUENCES
    WHERE sequence_name IN ('SQ_CLIENTE','SQ_MOVIMIENTO','SQ_AUDITORIA','SQ_LOG')
      AND increment_by = 1 AND last_number = 1 AND cache_size = 0 AND cycle_flag = 'N';
    exigir(v_total = 4, 'Las cuatro secuencias auxiliares deben iniciar en 1 e incrementar 1.');

    v_fila := T_MOV_FILA(TIMESTAMP '2026-01-01 00:00:00', 'DEPOSITO', 'Prueba local de tipos', 10, 10);
    v_movimientos := T_MOV_TABLA(v_fila);
    exigir(v_movimientos.COUNT = 1 AND v_movimientos(1).SALDO_ACUMULADO = 10,
        'Los tipos deben permitir construir una colección de movimientos.');
    DBMS_OUTPUT.PUT_LINE('F1 OK: 5 tablas, 5 secuencias y 2 tipos VALID; sin errores.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
ROLLBACK;
-- ===== FIN F1 =====


-- ===== INICIO F2A: vistas, funciones y triggers =====
-- Ejecutar SOLO F2A después de 04, 05 y 06, con DBMS_OUTPUT habilitado.
-- Usar una hoja sin cambios pendientes: esta sección termina en ROLLBACK.
-- Consume secuencias (Oracle no revierte NEXTVAL). No volver a ejecutar F1
-- después de este punto: F1 comprueba los valores iniciales de las secuencias.
-- No llama a SP_LOG_ERROR: su persistencia autónoma se prueba en F3.

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN ('V_ESTADO_CUENTA','V_CUENTAS_RESUMEN',
    'SP_LOG_ERROR','FN_SALDO_DISPONIBLE','FN_CATEGORIA_CLIENTE','FN_COMISION',
    'TRG_CLIENTES_BI','TRG_CUENTAS_BI','TRG_MOVIMIENTOS_BI','TRG_MOVIMIENTOS_AI','TRG_CUENTAS_AU')
ORDER BY object_type, object_name;

-- Debe devolver cero filas; solo objetos de esta fase.
SELECT name, type, line, position, text
FROM USER_ERRORS
WHERE name IN ('V_ESTADO_CUENTA','V_CUENTAS_RESUMEN',
    'SP_LOG_ERROR','FN_SALDO_DISPONIBLE','FN_CATEGORIA_CLIENTE','FN_COMISION',
    'TRG_CLIENTES_BI','TRG_CUENTAS_BI','TRG_MOVIMIENTOS_BI','TRG_MOVIMIENTOS_AI','TRG_CUENTAS_AU')
ORDER BY name, sequence;

-- Referencias requeridas: 1.50, 1.00, 8.00, 3.00; BASICO, GOLD, PREMIUM.
SELECT FN_COMISION(100, 'BASICO') AS BASICO_100,
       FN_COMISION(10, 'BASICO') AS MINIMO_10,
       FN_COMISION(1000, 'GOLD') AS GOLD_1000,
       FN_COMISION(1000, 'PREMIUM') AS PREMIUM_1000,
       FN_CATEGORIA_CLIENTE(4999.99) AS CATEGORIA_4999,
       FN_CATEGORIA_CLIENTE(5000) AS CATEGORIA_5000,
       FN_CATEGORIA_CLIENTE(50000) AS CATEGORIA_50000
FROM dual;

DECLARE
    v_total PLS_INTEGER;
    v_cliente TBL_CLIENTES.ID_CLIENTE%TYPE;
    v_origen TBL_CUENTAS.ID_CUENTA%TYPE;
    v_destino TBL_CUENTAS.ID_CUENTA%TYPE;
    v_nro TBL_CUENTAS.NRO_CUENTA%TYPE;
    v_nombres TBL_CLIENTES.NOMBRES%TYPE;
    v_apellidos TBL_CLIENTES.APELLIDOS%TYPE;
    v_dni TBL_CLIENTES.DNI%TYPE;
    v_intento PLS_INTEGER := 0;
    v_mov TBL_MOVIMIENTOS.ID_MOVIMIENTO%TYPE;
    v_saldo TBL_CUENTAS.SALDO%TYPE;
    v_depositado NUMBER;
    v_retirado NUMBER;
    v_resultado NUMBER;
    e_monto EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_cuenta EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    PROCEDURE exigir(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20982, 'F2A: ' || p_mensaje);
        END IF;
    END;
    PROCEDURE movimiento(p_cuenta NUMBER, p_tipo VARCHAR2, p_monto NUMBER,
                         p_saldo_esperado NUMBER, p_relacionada NUMBER DEFAULT NULL) IS
    BEGIN
        INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA, TIPO, MONTO, DESCRIPCION, ID_CUENTA_RELACIONADA)
        VALUES (p_cuenta, p_tipo, p_monto, 'Smoke F2A', p_relacionada)
        RETURNING ID_MOVIMIENTO, SALDO_POSTERIOR INTO v_mov, v_saldo;
        exigir(v_mov IS NOT NULL AND v_saldo = p_saldo_esperado,
            'ID y saldo posterior del movimiento ' || p_tipo);
        exigir(FN_SALDO_DISPONIBLE(p_cuenta) = p_saldo_esperado,
            'Saldo vigente tras ' || p_tipo || ': posible doble actualización.');
    END;
BEGIN
    SELECT COUNT(*) INTO v_total FROM USER_OBJECTS
    WHERE status = 'VALID' AND (
        (object_type = 'VIEW' AND object_name IN ('V_ESTADO_CUENTA','V_CUENTAS_RESUMEN')) OR
        (object_type = 'PROCEDURE' AND object_name = 'SP_LOG_ERROR') OR
        (object_type = 'FUNCTION' AND object_name IN ('FN_SALDO_DISPONIBLE','FN_CATEGORIA_CLIENTE','FN_COMISION')) OR
        (object_type = 'TRIGGER' AND object_name IN ('TRG_CLIENTES_BI','TRG_CUENTAS_BI','TRG_MOVIMIENTOS_BI','TRG_MOVIMIENTOS_AI','TRG_CUENTAS_AU')));
    exigir(v_total = 11, 'Deben existir 11 objetos VALID de Fase 2A.');
    SELECT COUNT(*) INTO v_total FROM USER_ERRORS
    WHERE name IN ('V_ESTADO_CUENTA','V_CUENTAS_RESUMEN',
        'SP_LOG_ERROR','FN_SALDO_DISPONIBLE','FN_CATEGORIA_CLIENTE','FN_COMISION',
        'TRG_CLIENTES_BI','TRG_CUENTAS_BI','TRG_MOVIMIENTOS_BI','TRG_MOVIMIENTOS_AI','TRG_CUENTAS_AU');
    exigir(v_total = 0, 'USER_ERRORS debe estar vacío para Fase 2A.');
    exigir(FN_COMISION(100, 'BASICO') = 1.50, 'Comisión BASICO de 100.');
    exigir(FN_COMISION(10, 'BASICO') = 1, 'Mínimo BASICO.');
    exigir(FN_COMISION(1000, 'GOLD') = 8, 'Comisión GOLD de 1000.');
    exigir(FN_COMISION(1000, 'PREMIUM') = 3, 'Comisión PREMIUM de 1000.');
    exigir(FN_COMISION(10, 'GOLD') = 1 AND FN_COMISION(10, 'PREMIUM') = 1,
        'Mínimo de S/ 1 en todas las categorías.');
    exigir(FN_COMISION(123.45) = 1.85, 'Categoría por defecto y redondeo a dos decimales.');
    exigir(FN_CATEGORIA_CLIENTE(4999.99) = 'BASICO', 'Límite BASICO.');
    exigir(FN_CATEGORIA_CLIENTE(5000) = 'GOLD', 'Inicio GOLD.');
    exigir(FN_CATEGORIA_CLIENTE(49999.99) = 'GOLD', 'Límite GOLD.');
    exigir(FN_CATEGORIA_CLIENTE(50000) = 'PREMIUM', 'Inicio PREMIUM.');
    BEGIN
        v_resultado := FN_COMISION(0);
        exigir(FALSE, 'Comisión con monto cero debe lanzar -20004.');
    EXCEPTION WHEN e_monto THEN NULL;
    END;
    BEGIN
        v_resultado := FN_COMISION(-1);
        exigir(FALSE, 'Comisión con monto negativo debe lanzar -20004.');
    EXCEPTION WHEN e_monto THEN NULL;
    END;
    BEGIN
        v_resultado := FN_SALDO_DISPONIBLE(-1);
        exigir(FALSE, 'Cuenta inexistente debe lanzar -20002.');
    EXCEPTION WHEN e_cuenta THEN NULL;
    END;

    -- Busca un DNI libre, sin modificar clientes preexistentes.
    LOOP
        v_dni := TO_CHAR(99000000 + v_intento, 'FM00000000');
        SELECT COUNT(*) INTO v_total FROM TBL_CLIENTES WHERE DNI = v_dni;
        EXIT WHEN v_total = 0;
        v_intento := v_intento + 1;
        exigir(v_intento < 1000, 'No se encontró un DNI libre para la prueba.');
    END LOOP;
    INSERT INTO TBL_CLIENTES (DNI, NOMBRES, APELLIDOS, EMAIL)
    VALUES (v_dni, 'cliente', 'prueba', 'f2a-' || RAWTOHEX(SYS_GUID()) || '@example.invalid')
    RETURNING ID_CLIENTE, NOMBRES, APELLIDOS INTO v_cliente, v_nombres, v_apellidos;
    exigir(v_cliente IS NOT NULL AND v_nombres = 'CLIENTE' AND v_apellidos = 'PRUEBA',
        'BEFORE INSERT de cliente: ID y mayúsculas.');
    UPDATE TBL_CLIENTES SET NOMBRES = 'cliente editado', APELLIDOS = 'prueba editada'
    WHERE ID_CLIENTE = v_cliente;
    SELECT NOMBRES, APELLIDOS INTO v_nombres, v_apellidos FROM TBL_CLIENTES
    WHERE ID_CLIENTE = v_cliente;
    exigir(v_nombres = 'CLIENTE EDITADO' AND v_apellidos = 'PRUEBA EDITADA',
        'BEFORE UPDATE de nombres y apellidos.');

    INSERT INTO TBL_CUENTAS (ID_CLIENTE, TIPO, TASA_INTERES_ANUAL)
    VALUES (v_cliente, 'AHORROS', 3)
    RETURNING ID_CUENTA, NRO_CUENTA INTO v_origen, v_nro;
    exigir(v_nro = '191-' || LPAD(v_origen, 8, '0'), 'ID y número deben derivar del mismo NEXTVAL.');
    INSERT INTO TBL_CUENTAS (ID_CLIENTE, TIPO, TASA_INTERES_ANUAL)
    VALUES (v_cliente, 'CORRIENTE', 0.5)
    RETURNING ID_CUENTA INTO v_destino;
    exigir(v_destino = v_origen + 10, 'SQ_CUENTA debe avanzar exactamente diez.');
    SELECT CANTIDAD_MOVIMIENTOS, TOTAL_DEPOSITADO, TOTAL_RETIRADO
    INTO v_total, v_depositado, v_retirado FROM V_CUENTAS_RESUMEN WHERE ID_CUENTA = v_origen;
    exigir(v_total = 0 AND v_depositado = 0 AND v_retirado = 0,
        'La vista debe incluir cuentas sin movimientos con totales cero.');

    movimiento(v_origen, 'DEPOSITO', 100, 100);
    movimiento(v_origen, 'RETIRO', 10, 90);
    movimiento(v_origen, 'TRANSF_ENVIADA', 20, 70, v_destino);
    movimiento(v_origen, 'COMISION', 1, 69, v_destino);
    movimiento(v_destino, 'TRANSF_RECIBIDA', 20, 20, v_origen);
    movimiento(v_destino, 'INTERES', 2, 22);
    SELECT COUNT(*) INTO v_total FROM TBL_AUDITORIA
    WHERE TABLA = 'TBL_MOVIMIENTOS' AND OPERACION = 'INSERT'
      AND ID_REGISTRO IN (SELECT ID_MOVIMIENTO FROM TBL_MOVIMIENTOS WHERE ID_CUENTA IN (v_origen, v_destino));
    exigir(v_total = 6, 'Debe existir una auditoría por cada movimiento.');
    SELECT COUNT(*) INTO v_total FROM TBL_AUDITORIA
    WHERE TABLA = 'TBL_CUENTAS' AND ID_REGISTRO IN (v_origen,v_destino);
    exigir(v_total = 0, 'Cambiar el saldo no debe disparar auditoría de estado.');

    SELECT CANTIDAD_MOVIMIENTOS, TOTAL_DEPOSITADO, TOTAL_RETIRADO
    INTO v_total, v_depositado, v_retirado FROM V_CUENTAS_RESUMEN WHERE ID_CUENTA = v_origen;
    exigir(v_total = 4 AND v_depositado = 100 AND v_retirado = 31,
        'Resumen del origen: cuatro movimientos, 100 abonados, 31 cargados.');
    SELECT CANTIDAD_MOVIMIENTOS, TOTAL_DEPOSITADO, TOTAL_RETIRADO
    INTO v_total, v_depositado, v_retirado FROM V_CUENTAS_RESUMEN WHERE ID_CUENTA = v_destino;
    exigir(v_total = 2 AND v_depositado = 22 AND v_retirado = 0,
        'Resumen del destino: transferencia e interés incluidos en abonos.');
    SELECT COUNT(*) INTO v_total FROM V_ESTADO_CUENTA
    WHERE ID_CUENTA IN (v_origen,v_destino)
      AND CLIENTE_COMPLETO = 'CLIENTE EDITADO PRUEBA EDITADA';
    exigir(v_total = 6, 'La vista de historial debe unir cliente, cuenta y seis movimientos.');

    UPDATE TBL_CUENTAS SET ESTADO = 'BLOQUEADA' WHERE ID_CUENTA = v_origen;
    UPDATE TBL_CUENTAS SET ESTADO = 'ACTIVA' WHERE ID_CUENTA = v_origen;
    UPDATE TBL_CUENTAS SET ESTADO = 'ACTIVA' WHERE ID_CUENTA = v_origen;
    UPDATE TBL_CUENTAS SET FECHA_ULT_INTERES = DATE '2026-01-01' WHERE ID_CUENTA = v_origen;
    SELECT COUNT(*) INTO v_total FROM TBL_AUDITORIA
    WHERE TABLA = 'TBL_CUENTAS' AND ID_REGISTRO = v_origen AND OPERACION = 'UPDATE';
    exigir(v_total = 2, 'Solo bloqueo y desbloqueo reales deben auditarse.');

    BEGIN
        INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO)
        VALUES (v_origen,'DEPOSITO',0);
        exigir(FALSE, 'El BEFORE debe rechazar monto cero con -20004.');
    EXCEPTION WHEN e_monto THEN NULL;
    END;
    BEGIN
        INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO)
        VALUES (v_origen,'RETIRO',-1);
        exigir(FALSE, 'El BEFORE debe rechazar monto negativo con -20004.');
    EXCEPTION WHEN e_monto THEN NULL;
    END;
    exigir(FN_SALDO_DISPONIBLE(v_origen) = 69, 'Errores de monto no deben modificar saldo.');
    ROLLBACK;
    SELECT COUNT(*) INTO v_total FROM TBL_CLIENTES WHERE ID_CLIENTE = v_cliente;
    exigir(v_total = 0, 'El cliente temporal debe desaparecer tras ROLLBACK.');
    SELECT COUNT(*) INTO v_total FROM TBL_CUENTAS WHERE ID_CUENTA IN (v_origen,v_destino);
    exigir(v_total = 0, 'Las cuentas temporales deben desaparecer tras ROLLBACK.');
    SELECT COUNT(*) INTO v_total FROM TBL_MOVIMIENTOS WHERE ID_CUENTA IN (v_origen,v_destino);
    exigir(v_total = 0, 'Los movimientos temporales deben desaparecer tras ROLLBACK.');
    SELECT COUNT(*) INTO v_total FROM TBL_AUDITORIA
    WHERE (TABLA = 'TBL_CUENTAS' AND ID_REGISTRO IN (v_origen,v_destino))
       OR (TABLA = 'TBL_MOVIMIENTOS' AND ID_REGISTRO = v_mov);
    exigir(v_total = 0, 'La auditoría de prueba debe revertirse con ROLLBACK.');
    DBMS_OUTPUT.PUT_LINE('F2A OK: 11 objetos VALID, comisiones, categorías, vistas y triggers correctos; ROLLBACK completado.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
ROLLBACK;
-- ===== FIN F2A =====


-- ===== INICIO F2B: procedimientos, pipelined y bloques =====
-- Ejecutar SOLO F2B después de 07 y 08, con DBMS_OUTPUT habilitado.
-- Los archivos sql/bloques/ son consumidos con binds por Flask (Fase 4).
-- Aquí se incluyen copias derivadas mecánicamente, sin binds de la hoja.
-- ROLLBACK revierte datos, auditoría y cambios de intereses/categorías.
-- Los errores intencionales dejan LOG autónomo; las secuencias avanzan.
-- Usar una hoja sin cambios pendientes.

SELECT object_name,object_type,status FROM USER_OBJECTS
WHERE object_name IN ('SP_LOG_ERROR','SP_ABRIR_CUENTA','SP_DEPOSITAR','SP_RETIRAR',
    'SP_TRANSFERIR','SP_CAMBIAR_ESTADO_CUENTA','SP_APLICAR_INTERESES',
    'SP_ACTUALIZAR_CATEGORIAS','SP_REPORTE_CLIENTES','SP_LAB_ERRORES','FN_ESTADO_CUENTA_MENSUAL')
ORDER BY object_type,object_name;
SELECT name,type,line,position,text FROM USER_ERRORS
WHERE name IN ('SP_LOG_ERROR','SP_ABRIR_CUENTA','SP_DEPOSITAR','SP_RETIRAR',
    'SP_TRANSFERIR','SP_CAMBIAR_ESTADO_CUENTA','SP_APLICAR_INTERESES',
    'SP_ACTUALIZAR_CATEGORIAS','SP_REPORTE_CLIENTES','SP_LAB_ERRORES','FN_ESTADO_CUENTA_MENSUAL')
ORDER BY name,sequence;

DECLARE
    v_estado VARCHAR2(10);
    v_codigo NUMBER;
    v_mensaje VARCHAR2(4000);
    v_detalle VARCHAR2(4000);
    v_cli NUMBER;
    v_origen NUMBER;
    v_destino NUMBER;
    v_pequena NUMBER;
    v_nro VARCHAR2(12);
    v_total NUMBER;
    v_n NUMBER;
    v_omitidas NUMBER;
    v_cambios NUMBER;
    v_dni VARCHAR2(8);
    v_intento PLS_INTEGER := 0;
    v_json CLOB;
    v_array JSON_ARRAY_T;
    v_obj JSON_OBJECT_T;
    v_cuentas JSON_ARRAY_T;
    v_movs JSON_ARRAY_T;
    v_saldo NUMBER;
    v_categoria VARCHAR2(7);
    v_id_mov NUMBER;
    v_mes DATE := TRUNC(SYSDATE,'MM');
    v_saldo_final NUMBER;
    v_meses_meta NUMBER;
    v_proyeccion CLOB;
    PROCEDURE exigir(p_condicion BOOLEAN,p_texto VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20983,'F2B: ' || p_texto);
        END IF;
    END;
    PROCEDURE comprobar_ok(p_contexto VARCHAR2) IS
    BEGIN
        exigir(v_estado = 'OK' AND v_codigo = 0,p_contexto || ': ' || v_mensaje);
    END;
    PROCEDURE comprobar_error(p_esperado NUMBER) IS
    BEGIN
        exigir(v_estado = 'ERROR' AND v_codigo = p_esperado,
            'Código esperado ' || p_esperado || ', recibido ' || v_codigo || ': ' || v_mensaje);
    END;
    -- Versión derivada mecánicamente de simulador_interes.sql; sin binds.
    PROCEDURE simular(x_saldo NUMBER,x_tasa NUMBER,x_meses NUMBER,
                      x_aporte NUMBER,x_meta NUMBER,x_cuenta NUMBER) IS
    BEGIN
DECLARE
    c_max_meses CONSTANT PLS_INTEGER := 600;
    c_meses_anio CONSTANT NUMBER := 12;
    v_cuenta TBL_CUENTAS%ROWTYPE;
    v_inicial TBL_CUENTAS.SALDO%TYPE;
    v_tasa TBL_CUENTAS.TASA_INTERES_ANUAL%TYPE;
    v_saldo NUMBER;
    v_saldo_meta NUMBER;
    v_aporte NUMBER := x_aporte;
    v_meta NUMBER := x_meta;
    v_meses NUMBER := x_meses;
    v_mes PLS_INTEGER := 0;
    v_proyeccion_json JSON_ARRAY_T := JSON_ARRAY_T();
    v_fila JSON_OBJECT_T;
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto,-20004);
BEGIN
    v_saldo_final := NULL; v_meses_meta := NULL; v_proyeccion := NULL;
    v_estado := 'OK'; v_codigo := 0; v_mensaje := 'Simulación completada.';
    IF x_cuenta IS NOT NULL THEN
        SELECT * INTO v_cuenta FROM TBL_CUENTAS WHERE ID_CUENTA = x_cuenta;
        v_inicial := v_cuenta.SALDO; v_tasa := NVL(v_cuenta.TASA_INTERES_ANUAL,0);
    ELSE
        v_inicial := x_saldo; v_tasa := x_tasa;
    END IF;
    IF v_inicial IS NULL OR v_inicial < 0 OR v_tasa IS NULL OR v_tasa < 0
       OR v_aporte IS NULL OR v_aporte < 0 OR v_meta IS NULL OR v_meta <= 0
       OR v_meses IS NULL OR v_meses < 0 OR v_meses > c_max_meses
       OR v_meses <> TRUNC(v_meses) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Datos de simulación inválidos; meses entre 0 y 600.');
    END IF;
    v_saldo := v_inicial;
    v_fila := JSON_OBJECT_T(); v_fila.PUT('mes',0); v_fila.PUT('saldo',v_saldo);
    v_proyeccion_json.APPEND(v_fila);
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
    IF v_saldo_meta >= v_meta THEN
        v_meses_meta := v_mes;
    ELSE
        v_meses_meta := NULL;
        v_mensaje := 'La meta no se alcanza en el límite de 600 meses.';
    END IF;
    v_saldo_final := v_saldo;
    v_proyeccion := v_proyeccion_json.TO_CLOB();
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_estado := 'ERROR'; v_codigo := -20002; v_mensaje := 'Cuenta inexistente.';
    WHEN e_monto THEN
        v_estado := 'ERROR'; v_codigo := -20004; v_mensaje := 'Datos de simulación inválidos.';
    WHEN OTHERS THEN
        v_estado := 'ERROR'; v_codigo := SQLCODE; v_mensaje := 'No se pudo calcular la simulación.';
END;
    END simular;
BEGIN
    SELECT COUNT(*) INTO v_total FROM USER_OBJECTS
    WHERE status = 'VALID' AND (
        (object_type = 'PROCEDURE' AND object_name IN ('SP_LOG_ERROR','SP_ABRIR_CUENTA','SP_DEPOSITAR','SP_RETIRAR',
            'SP_TRANSFERIR','SP_CAMBIAR_ESTADO_CUENTA','SP_APLICAR_INTERESES','SP_ACTUALIZAR_CATEGORIAS','SP_REPORTE_CLIENTES','SP_LAB_ERRORES'))
        OR (object_type = 'FUNCTION' AND object_name = 'FN_ESTADO_CUENTA_MENSUAL'));
    exigir(v_total = 11,'Se requieren 10 procedimientos y la función pipelined VALID.');
    SELECT COUNT(*) INTO v_total FROM USER_ERRORS
    WHERE name IN ('SP_LOG_ERROR','SP_ABRIR_CUENTA','SP_DEPOSITAR','SP_RETIRAR','SP_TRANSFERIR',
        'SP_CAMBIAR_ESTADO_CUENTA','SP_APLICAR_INTERESES','SP_ACTUALIZAR_CATEGORIAS','SP_REPORTE_CLIENTES','SP_LAB_ERRORES','FN_ESTADO_CUENTA_MENSUAL');
    exigir(v_total = 0,'Los objetos de esta fase no deben tener errores.');
    LOOP
        v_dni := TO_CHAR(98000000 + v_intento,'FM00000000');
        SELECT COUNT(*) INTO v_total FROM TBL_CLIENTES WHERE DNI = v_dni;
        EXIT WHEN v_total = 0;
        v_intento := v_intento + 1;
        exigir(v_intento < 1000,'No se encontró DNI libre.');
    END LOOP;
    INSERT INTO TBL_CLIENTES (DNI,NOMBRES,APELLIDOS,EMAIL)
    VALUES (v_dni,'Smoke','Fase dos b','f2b-' || RAWTOHEX(SYS_GUID()) || '@example.invalid')
    RETURNING ID_CLIENTE INTO v_cli;
    SP_ABRIR_CUENTA(v_cli,'AHORROS',10000,12,v_origen,v_nro,v_estado,v_codigo,v_mensaje);
    comprobar_ok('Apertura origen');
    SP_ABRIR_CUENTA(v_cli,'CORRIENTE',0,NULL,v_destino,v_nro,v_estado,v_codigo,v_mensaje);
    comprobar_ok('Apertura destino');
    SELECT TASA_INTERES_ANUAL INTO v_total FROM TBL_CUENTAS WHERE ID_CUENTA = v_destino;
    exigir(v_total = 0.5,'Tasa por defecto CORRIENTE.');
    SP_ABRIR_CUENTA(v_cli,'AHORROS',0.01,0.01,v_pequena,v_nro,v_estado,v_codigo,v_mensaje);
    comprobar_ok('Apertura de cuenta con interés redondeado a cero');
    SP_DEPOSITAR(v_origen,50,v_estado,v_codigo,v_mensaje); comprobar_ok('Depósito');
    SP_RETIRAR(v_origen,10,v_estado,v_codigo,v_mensaje); comprobar_ok('Retiro');
    SP_TRANSFERIR(v_origen,v_destino,100,v_estado,v_codigo,v_mensaje); comprobar_ok('Transferencia');
    exigir(INSTR(v_mensaje,'1.50') > 0,'El mensaje debe informar la comisión.');
    exigir(FN_SALDO_DISPONIBLE(v_origen) = 9938.5 AND FN_SALDO_DISPONIBLE(v_destino) = 100,
        'Transferencia debe descontar monto y comisión una sola vez.');

    -- Errores de negocio: el savepoint del procedimiento conserva los datos del llamador.
    SP_RETIRAR(v_origen,99999999,v_estado,v_codigo,v_mensaje); comprobar_error(-20001);
    SP_DEPOSITAR(-1,1,v_estado,v_codigo,v_mensaje); comprobar_error(-20002);
    SP_DEPOSITAR(-1,0,v_estado,v_codigo,v_mensaje); comprobar_error(-20004);
    SP_CAMBIAR_ESTADO_CUENTA(v_origen,'BLOQUEADA',v_estado,v_codigo,v_mensaje); comprobar_ok('Bloqueo');
    SP_DEPOSITAR(v_origen,1,v_estado,v_codigo,v_mensaje); comprobar_error(-20003);
    SP_CAMBIAR_ESTADO_CUENTA(v_origen,'ACTIVA',v_estado,v_codigo,v_mensaje); comprobar_ok('Desbloqueo');
    SP_TRANSFERIR(v_origen,v_origen,1,v_estado,v_codigo,v_mensaje); comprobar_error(-20005);
    SP_ABRIR_CUENTA(-1,'AHORROS',0,NULL,v_id_mov,v_nro,v_estado,v_codigo,v_mensaje); comprobar_error(-20006);
    exigir(v_id_mov IS NULL AND v_nro IS NULL,'Apertura fallida no debe devolver IDs.');
    SP_CAMBIAR_ESTADO_CUENTA(v_origen,'CERRADA',v_estado,v_codigo,v_mensaje); comprobar_error(-20007);
    exigir(FN_SALDO_DISPONIBLE(v_origen) = 9938.5,'Los errores no deben modificar saldo.');

    SP_APLICAR_INTERESES(v_mes,v_n,v_omitidas,v_estado,v_codigo,v_mensaje); comprobar_ok('Intereses');
    exigir(v_n >= 2 AND v_omitidas >= 1,'Dos cuentas reciben interés y la diminuta se omite.');
    exigir(FN_SALDO_DISPONIBLE(v_origen) = 10037.89,'Interés del origen: 99.39.');
    exigir(FN_SALDO_DISPONIBLE(v_destino) = 100.04,'Interés del destino: 0.04.');
    SELECT FECHA_ULT_INTERES INTO v_mes FROM TBL_CUENTAS WHERE ID_CUENTA = v_origen;
    exigir(v_mes = TRUNC(SYSDATE,'MM'),'Fecha del interés debe quedar en primer día del mes.');
    SP_APLICAR_INTERESES(v_mes,v_n,v_omitidas,v_estado,v_codigo,v_mensaje); comprobar_ok('Intereses repetidos');
    exigir(v_n = 0 AND FN_SALDO_DISPONIBLE(v_origen) = 10037.89,'Interés mensual idempotente.');
    SP_ACTUALIZAR_CATEGORIAS(v_n,v_cambios,v_estado,v_codigo,v_mensaje); comprobar_ok('Categorías');
    SELECT CATEGORIA INTO v_categoria FROM TBL_CLIENTES WHERE ID_CLIENTE = v_cli;
    exigir(v_categoria = 'GOLD','Categoría por saldo total de sus cuentas.');
    SP_ACTUALIZAR_CATEGORIAS(v_n,v_cambios,v_estado,v_codigo,v_mensaje); comprobar_ok('Categorías repetidas');
    exigir(v_cambios = 0,'Solo debe actualizar categorías que cambian.');

    SP_REPORTE_CLIENTES(v_cli,2,v_json,v_estado,v_codigo,v_mensaje); comprobar_ok('Reporte jerárquico');
    v_array := JSON_ARRAY_T.PARSE(v_json);
    exigir(v_array.GET_SIZE() = 1,'Reporte filtrado por cliente.');
    v_obj := TREAT(v_array.GET(0) AS JSON_OBJECT_T);
    v_cuentas := v_obj.GET_ARRAY('cuentas');
    exigir(v_cuentas.GET_SIZE() = 3,'Reporte debe contener tres cuentas.');
    FOR i IN 0 .. v_cuentas.GET_SIZE() - 1 LOOP
        v_obj := TREAT(v_cuentas.GET(i) AS JSON_OBJECT_T);
        v_movs := v_obj.GET_ARRAY('movimientos');
        exigir(v_movs.GET_SIZE() <= 2,'Cursor con parámetro debe respetar límite.');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Reporte: ' || DBMS_LOB.SUBSTR(v_json,2000,1));

    -- Llevar solo el depósito inicial al mes anterior para probar saldo de apertura.
    SELECT MIN(ID_MOVIMIENTO) INTO v_id_mov FROM TBL_MOVIMIENTOS WHERE ID_CUENTA = v_origen;
    UPDATE TBL_MOVIMIENTOS SET FECHA = CAST(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AS TIMESTAMP)
    WHERE ID_MOVIMIENTO = v_id_mov;
    v_n := 0; v_saldo := NULL;
    FOR r IN (SELECT * FROM TABLE(FN_ESTADO_CUENTA_MENSUAL(v_origen,EXTRACT(YEAR FROM SYSDATE),EXTRACT(MONTH FROM SYSDATE)))) LOOP
        v_n := v_n + 1; v_saldo := r.SALDO_ACUMULADO;
        DBMS_OUTPUT.PUT_LINE('Estado mensual: ' || r.TIPO || ' / ' || r.MONTO || ' / saldo ' || r.SALDO_ACUMULADO);
    END LOOP;
    exigir(v_n = 5 AND v_saldo = 10037.89,'Cursor explícito con saldo anterior al mes.');

    FOR r IN (SELECT 'no_data_found' caso FROM dual UNION ALL SELECT 'too_many_rows' FROM dual
        UNION ALL SELECT 'dup_val_on_index' FROM dual UNION ALL SELECT 'zero_divide' FROM dual
        UNION ALL SELECT 'value_error' FROM dual UNION ALL SELECT 'when_others' FROM dual UNION ALL SELECT 'reraise' FROM dual) LOOP
        SP_LAB_ERRORES(r.caso,v_detalle,v_estado,v_codigo,v_mensaje); comprobar_ok('Laboratorio ' || r.caso);
        exigir(INSTR(v_detalle,'SQLCODE=') = 1 AND INSTR(v_detalle,'SQLERRM=') > 0,'Detalle técnico de excepción.');
        DBMS_OUTPUT.PUT_LINE('Laboratorio ' || r.caso || ': ' || v_detalle);
    END LOOP;

    -- Copia mecánica de sql/bloques/simulador_interes.sql; entradas sin cuenta.
    simular(1000,12,2,100,1221.10,NULL);
    comprobar_ok('Simulador sin cuenta');
    exigir(v_saldo_final = 1221.10 AND v_meses_meta = 2,'Proyección 1000 -> 1110 -> 1221.10.');
    v_array := JSON_ARRAY_T.PARSE(v_proyeccion);
    exigir(v_array.GET_SIZE() = 3,'Proyección incluye mes cero y dos meses calculados.');
    DBMS_OUTPUT.PUT_LINE('Simulador: ' || DBMS_LOB.SUBSTR(v_proyeccion,2000,1));
    simular(0,0,1,0,20000,v_origen); comprobar_ok('Simulador con cuenta opcional');
    exigir(v_saldo_final = 10138.27,'La cuenta debe reemplazar saldo y tasa de entrada.');
    simular(10,0,2,0,100,NULL); comprobar_ok('Meta inalcanzable');
    exigir(v_saldo_final = 10 AND v_meses_meta IS NULL AND INSTR(v_mensaje,'600') > 0,
        'WHILE debe detenerse en 600 meses y devolver meta nula.');
    simular(1000,12,601,100,2000,NULL); comprobar_error(-20004);
    exigir(v_saldo_final IS NULL AND v_proyeccion IS NULL,'No devolver salidas anteriores ante error.');
    simular(0,0,1,0,100,-1); comprobar_error(-20002);
    simular(100,0,0,0,100,NULL); comprobar_ok('Meta alcanzada inicialmente');
    exigir(v_saldo_final = 100 AND v_meses_meta = 0,'Cero meses si ya se alcanzó la meta.');


    -- Copia mecánica de sql/bloques/resumen_cliente.sql; cliente temporal.
DECLARE
    v_cliente TBL_CLIENTES%ROWTYPE;
    v_total TBL_CUENTAS.SALDO%TYPE;
    v_nivel TBL_CLIENTES.CATEGORIA%TYPE;
    v_falta NUMBER;
    v_siguiente VARCHAR2(7);
    v_gold NUMBER;
    v_premium NUMBER;
    v_resumen_json JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
    v_json := NULL; v_estado := 'OK'; v_codigo := 0;
    v_mensaje := 'Resumen generado.';
    SELECT * INTO v_cliente FROM TBL_CLIENTES WHERE ID_CLIENTE = v_cli;
    SELECT NVL(SUM(SALDO),0) INTO v_total FROM TBL_CUENTAS
    WHERE ID_CLIENTE = v_cliente.ID_CLIENTE;
    SELECT LIMITE_GOLD,LIMITE_PREMIUM INTO v_gold,v_premium
    FROM TBL_LIMITES_CATEGORIAS WHERE ID_CONFIG=1;
    IF v_total < v_gold THEN
        v_nivel := 'BASICO'; v_siguiente := 'GOLD'; v_falta := v_gold - v_total;
    ELSIF v_total < v_premium THEN
        v_nivel := 'GOLD'; v_siguiente := 'PREMIUM'; v_falta := v_premium - v_total;
    ELSE
        v_nivel := 'PREMIUM'; v_siguiente := NULL; v_falta := 0;
    END IF;
    v_resumen_json.PUT('id_cliente',v_cliente.ID_CLIENTE);
    v_resumen_json.PUT('nombre',v_cliente.NOMBRES || ' ' || v_cliente.APELLIDOS);
    v_resumen_json.PUT('categoria_registrada',v_cliente.CATEGORIA);
    v_resumen_json.PUT('nivel',v_nivel); v_resumen_json.PUT('saldo_total',v_total);
    v_resumen_json.PUT('siguiente_categoria',v_siguiente); v_resumen_json.PUT('falta_para_siguiente',v_falta);
    v_json := v_resumen_json.TO_CLOB();
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_estado := 'ERROR'; v_codigo := -20006; v_mensaje := 'Cliente inexistente.';
    WHEN OTHERS THEN
        v_estado := 'ERROR'; v_codigo := SQLCODE; v_mensaje := 'No se pudo generar el resumen.';
END;
    comprobar_ok('Resumen cliente');
    v_obj := JSON_OBJECT_T.PARSE(v_json);
    exigir(v_obj.GET_STRING('nivel') = 'GOLD' AND v_obj.GET_NUMBER('saldo_total') = 10137.94,
        'Resumen usa todas las cuentas y calcula nivel GOLD.');
    exigir(v_obj.GET_NUMBER('falta_para_siguiente') = 39862.06,'Falta para PREMIUM.');
    DBMS_OUTPUT.PUT_LINE('Resumen cliente: ' || DBMS_LOB.SUBSTR(v_json,2000,1));
    ROLLBACK;
    SELECT COUNT(*) INTO v_total FROM TBL_CLIENTES WHERE ID_CLIENTE = v_cli;
    exigir(v_total = 0,'Cliente temporal debe revertirse.');
    SELECT COUNT(*) INTO v_total FROM TBL_CUENTAS WHERE ID_CUENTA IN (v_origen,v_destino,v_pequena);
    exigir(v_total = 0,'Cuentas temporales deben revertirse.');
    DBMS_OUTPUT.PUT_LINE('F2B OK: procedimientos, cursor explícito, reporte y bloques correctos; ROLLBACK completado.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
ROLLBACK;
-- ===== FIN F2B =====


-- ===== INICIO F3: sinónimos, transferencia, errores y log =====
-- Ejecutar SOLO F3 después de 09 y 10, con DBMS_OUTPUT habilitado.
-- Usar una hoja sin cambios pendientes. Datos de prueba ya confirmados por 10.
-- Esta sección revierte sus operaciones; solo persiste el log autónomo esperado.
-- Después ejecutar 00b_snapshot_ad.sql, guardar snapshot_ad_despues.txt y comparar.
SELECT synonym_name,table_name FROM USER_SYNONYMS
WHERE synonym_name IN ('CLIENTES','CUENTAS','MOVIMIENTOS','AUDITORIA','LOG_ERRORES')
ORDER BY synonym_name;
SELECT COUNT(*) AS CLIENTES_DEMO FROM CLIENTES;
SELECT COUNT(*) AS CUENTAS_DEMO FROM CUENTAS;
SELECT COUNT(*) AS MOVIMIENTOS_DEMO FROM MOVIMIENTOS;
SELECT COUNT(*) AS FILAS_AUDITORIA FROM AUDITORIA;
SELECT COUNT(*) AS FILAS_LOG FROM LOG_ERRORES;

DECLARE
    v_estado VARCHAR2(10);
    v_codigo NUMBER;
    v_mensaje VARCHAR2(4000);
    v_id_dummy NUMBER;
    v_nro_dummy VARCHAR2(12);
    v_origen NUMBER;
    v_destino NUMBER;
    v_saldo_origen NUMBER;
    v_saldo_destino NUMBER;
    v_categoria VARCHAR2(7);
    v_comision NUMBER;
    v_mov_antes NUMBER;
    v_log_antes NUMBER;
    v_total NUMBER;
    v_inicial NUMBER;
    v_auditoria_antes NUMBER;
    PROCEDURE exigir(p_condicion BOOLEAN,p_texto VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20985,'F3: ' || p_texto);
        END IF;
    END;
    PROCEDURE comprobar_ok(p_texto VARCHAR2) IS
    BEGIN
        exigir(v_estado = 'OK' AND v_codigo = 0,p_texto || ': ' || v_mensaje);
    END;
    PROCEDURE comprobar_error(p_codigo_esperado NUMBER) IS
    BEGIN
        exigir(v_estado = 'ERROR' AND v_codigo = p_codigo_esperado,
            'Se esperaba ' || p_codigo_esperado || ', recibido ' || v_codigo || ': ' || v_mensaje);
        DBMS_OUTPUT.PUT_LINE('Excepción propia OK: ' || v_codigo);
    END;
BEGIN
    SELECT COUNT(*) INTO v_total FROM USER_SYNONYMS
    WHERE table_owner = USER AND db_link IS NULL AND (
        (synonym_name = 'CLIENTES' AND table_name = 'TBL_CLIENTES') OR
        (synonym_name = 'CUENTAS' AND table_name = 'TBL_CUENTAS') OR
        (synonym_name = 'MOVIMIENTOS' AND table_name = 'TBL_MOVIMIENTOS') OR
        (synonym_name = 'AUDITORIA' AND table_name = 'TBL_AUDITORIA') OR
        (synonym_name = 'LOG_ERRORES' AND table_name = 'TBL_LOG_ERRORES'));
    exigir(v_total = 5,'Deben existir cinco sinónimos privados sobre las tablas propias.');
    SELECT COUNT(*) INTO v_total FROM CLIENTES;
    exigir(v_total = 6,'Se requieren seis clientes cargados por el script 10.');
    SELECT COUNT(*) INTO v_total FROM CUENTAS;
    exigir(v_total = 8,'Se requieren ocho cuentas.');
    SELECT COUNT(*) INTO v_inicial FROM MOVIMIENTOS;
    exigir(v_inicial = 30,'Se requieren treinta movimientos.');
    SELECT COUNT(DISTINCT CATEGORIA) INTO v_total FROM CLIENTES;
    exigir(v_total = 3,'Deben estar representadas BASICO, GOLD y PREMIUM.');
    -- Saldos vigentes coherentes con la suma de TODOS sus movimientos.
    SELECT COUNT(*) INTO v_total FROM CUENTAS c
    WHERE c.SALDO <> (SELECT NVL(SUM(CASE
        WHEN m.TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN m.MONTO ELSE -m.MONTO END),0)
        FROM MOVIMIENTOS m WHERE m.ID_CUENTA = c.ID_CUENTA);
    exigir(v_total = 0,'Un saldo difiere del libro de movimientos.');
    -- Cada saldo posterior debe corresponder al acumulado en orden fecha/ID.
    SELECT COUNT(*) INTO v_total FROM (
        SELECT SALDO_POSTERIOR,
            SUM(CASE WHEN TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN MONTO ELSE -MONTO END)
            OVER (PARTITION BY ID_CUENTA ORDER BY FECHA,ID_MOVIMIENTO ROWS UNBOUNDED PRECEDING) AS CALCULADO
        FROM MOVIMIENTOS
    ) WHERE SALDO_POSTERIOR <> CALCULADO;
    exigir(v_total = 0,'Algún saldo posterior de la carga es incoherente.');

    SELECT MIN(c.ID_CUENTA) INTO v_origen FROM CUENTAS c JOIN CLIENTES cli ON cli.ID_CLIENTE = c.ID_CLIENTE
    WHERE cli.DNI = '71000001' AND c.ESTADO = 'ACTIVA';
    SELECT MIN(c.ID_CUENTA) INTO v_destino FROM CUENTAS c JOIN CLIENTES cli ON cli.ID_CLIENTE = c.ID_CLIENTE
    WHERE cli.DNI = '71000002' AND c.ESTADO = 'ACTIVA';
    exigir(v_origen IS NOT NULL AND v_destino IS NOT NULL,'Faltan cuentas de demostración activas.');
    SELECT SALDO INTO v_saldo_origen FROM CUENTAS WHERE ID_CUENTA = v_origen;
    SELECT SALDO INTO v_saldo_destino FROM CUENTAS WHERE ID_CUENTA = v_destino;
    SELECT cli.CATEGORIA INTO v_categoria FROM CLIENTES cli JOIN CUENTAS c ON c.ID_CLIENTE = cli.ID_CLIENTE
    WHERE c.ID_CUENTA = v_origen;
    v_comision := FN_COMISION(100,v_categoria);
    SELECT NVL(MAX(ID_MOVIMIENTO),0) INTO v_mov_antes FROM MOVIMIENTOS;
    SELECT NVL(MAX(ID_LOG),0) INTO v_log_antes FROM LOG_ERRORES;
    SELECT COUNT(*) INTO v_auditoria_antes FROM AUDITORIA;
    SP_TRANSFERIR(v_origen,v_destino,100,v_estado,v_codigo,v_mensaje);
    comprobar_ok('Transferencia de prueba');
    exigir(FN_SALDO_DISPONIBLE(v_origen) = v_saldo_origen - 100 - v_comision,
        'El origen debe descontar monto y comisión.');
    exigir(FN_SALDO_DISPONIBLE(v_destino) = v_saldo_destino + 100,'El destino debe recibir solo el monto.');
    SELECT COUNT(*) INTO v_total FROM MOVIMIENTOS WHERE ID_MOVIMIENTO > v_mov_antes;
    exigir(v_total = 3,'Una transferencia debe generar exactamente tres movimientos.');
    SELECT COUNT(*) INTO v_total FROM MOVIMIENTOS
    WHERE ID_MOVIMIENTO > v_mov_antes AND (
        (ID_CUENTA = v_origen AND TIPO = 'TRANSF_ENVIADA' AND MONTO = 100 AND SALDO_POSTERIOR = v_saldo_origen - 100 AND ID_CUENTA_RELACIONADA = v_destino) OR
        (ID_CUENTA = v_origen AND TIPO = 'COMISION' AND MONTO = v_comision AND SALDO_POSTERIOR = v_saldo_origen - 100 - v_comision AND ID_CUENTA_RELACIONADA = v_destino) OR
        (ID_CUENTA = v_destino AND TIPO = 'TRANSF_RECIBIDA' AND MONTO = 100 AND SALDO_POSTERIOR = v_saldo_destino + 100 AND ID_CUENTA_RELACIONADA = v_origen));
    exigir(v_total = 3,'Tipos, contrapartes e importes de transferencia incorrectos.');
    SELECT COUNT(*) INTO v_total FROM AUDITORIA a JOIN MOVIMIENTOS m ON m.ID_MOVIMIENTO = a.ID_REGISTRO
    WHERE a.TABLA = 'TBL_MOVIMIENTOS' AND a.OPERACION = 'INSERT' AND m.ID_MOVIMIENTO > v_mov_antes;
    exigir(v_total = 3,'La transferencia debe generar tres registros de auditoría.');
    DBMS_OUTPUT.PUT_LINE('Transferencia OK: tres movimientos y tres auditorías; comisión S/ ' || v_comision);

    SP_RETIRAR(v_origen,999999999999.99,v_estado,v_codigo,v_mensaje); comprobar_error(-20001);
    SP_DEPOSITAR(-1,1,v_estado,v_codigo,v_mensaje); comprobar_error(-20002);
    SP_CAMBIAR_ESTADO_CUENTA(v_origen,'BLOQUEADA',v_estado,v_codigo,v_mensaje); comprobar_ok('Bloqueo');
    SP_DEPOSITAR(v_origen,1,v_estado,v_codigo,v_mensaje); comprobar_error(-20003);
    SP_CAMBIAR_ESTADO_CUENTA(v_origen,'ACTIVA',v_estado,v_codigo,v_mensaje); comprobar_ok('Desbloqueo');
    SP_DEPOSITAR(v_origen,-1,v_estado,v_codigo,v_mensaje); comprobar_error(-20004);
    SP_TRANSFERIR(v_origen,v_origen,1,v_estado,v_codigo,v_mensaje); comprobar_error(-20005);
    SP_ABRIR_CUENTA(-1,'AHORROS',0,NULL,v_id_dummy,v_nro_dummy,v_estado,v_codigo,v_mensaje); comprobar_error(-20006);
    SP_CAMBIAR_ESTADO_CUENTA(v_origen,'CERRADA',v_estado,v_codigo,v_mensaje); comprobar_error(-20007);
    ROLLBACK;

    exigir(FN_SALDO_DISPONIBLE(v_origen) = v_saldo_origen AND FN_SALDO_DISPONIBLE(v_destino) = v_saldo_destino,
        'ROLLBACK debe restaurar los saldos iniciales.');
    SELECT COUNT(*) INTO v_total FROM MOVIMIENTOS;
    exigir(v_total = v_inicial,'La transferencia de prueba debe desaparecer tras ROLLBACK.');
    SELECT COUNT(*) INTO v_total FROM AUDITORIA;
    exigir(v_total = v_auditoria_antes,'La auditoría de la prueba debe revertirse.');
    SELECT COUNT(DISTINCT CODIGO) INTO v_total FROM LOG_ERRORES
    WHERE ID_LOG > v_log_antes AND CODIGO BETWEEN -20007 AND -20001;
    exigir(v_total = 7,'Los siete códigos de error deben persistir en el log tras ROLLBACK.');
    SELECT COUNT(*) INTO v_total FROM LOG_ERRORES
    WHERE ID_LOG > v_log_antes AND PROCEDIMIENTO = 'SP_DEPOSITAR' AND CODIGO = -20002;
    exigir(v_total >= 1,'El error de cuenta inexistente debe conservarse tras ROLLBACK.');
    DBMS_OUTPUT.PUT_LINE('Log autónomo OK: errores persistentes tras ROLLBACK.');
    DBMS_OUTPUT.PUT_LINE('F3 OK: cinco sinónimos, 6 clientes, 8 cuentas, 30 movimientos y siete excepciones; ROLLBACK completado.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
ROLLBACK;
-- ===== FIN F3 =====
