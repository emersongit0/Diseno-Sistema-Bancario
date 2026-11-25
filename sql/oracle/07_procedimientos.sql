-- Fase 2B. Ejecutar como SCRIPT después de F2A. Sin COMMIT de negocio.

-- @OBJETO: SP_ABRIR_CUENTA
CREATE OR REPLACE PROCEDURE SP_ABRIR_CUENTA (
    p_id_cliente IN NUMBER,
    p_tipo IN VARCHAR2,
    p_saldo_inicial IN NUMBER DEFAULT 0,
    p_tasa IN NUMBER DEFAULT NULL,
    p_id_cuenta OUT NUMBER,
    p_nro_cuenta OUT VARCHAR2,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_cliente NUMBER;
    v_tasa TBL_CUENTAS.TASA_INTERES_ANUAL%TYPE;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_abrir_cuenta;
        p_id_cuenta := NULL; p_nro_cuenta := NULL;
        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_ABRIR_CUENTA', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_abrir_cuenta;
    p_estado := 'OK'; p_codigo := 0;
    p_id_cuenta := NULL; p_nro_cuenta := NULL;
    IF p_saldo_inicial IS NULL OR p_saldo_inicial < 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Saldo inicial inválido.');
    END IF;
    BEGIN
        SELECT ID_CLIENTE INTO v_cliente FROM TBL_CLIENTES WHERE ID_CLIENTE = p_id_cliente;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Cliente inexistente.');
    END;
    IF p_tasa IS NOT NULL THEN v_tasa := p_tasa;
    ELSIF p_tipo = 'AHORROS' THEN v_tasa := 3.00;
    ELSE v_tasa := 0.50;
    END IF;
    INSERT INTO TBL_CUENTAS (ID_CLIENTE,TIPO,TASA_INTERES_ANUAL)
    VALUES (p_id_cliente,p_tipo,v_tasa)
    RETURNING ID_CUENTA,NRO_CUENTA INTO p_id_cuenta,p_nro_cuenta;
    IF p_saldo_inicial > 0 THEN
        INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION)
        VALUES (p_id_cuenta,'DEPOSITO',p_saldo_inicial,'Depósito de apertura');
    END IF;
    p_mensaje := 'Cuenta abierta: ' || p_nro_cuenta;
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_ABRIR_CUENTA;
/
-- @FIN

-- @OBJETO: SP_DEPOSITAR
CREATE OR REPLACE PROCEDURE SP_DEPOSITAR (
    p_id_cuenta IN NUMBER,
    p_monto IN NUMBER,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_estado TBL_CUENTAS.ESTADO%TYPE;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_depositar;

        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_DEPOSITAR', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_depositar;
    p_estado := 'OK'; p_codigo := 0;
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Monto inválido: debe ser mayor que cero.');
    END IF;
    BEGIN
        SELECT ESTADO INTO v_estado FROM TBL_CUENTAS
        WHERE ID_CUENTA = p_id_cuenta FOR UPDATE WAIT 5;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cuenta inexistente.');
    END;
    IF v_estado <> 'ACTIVA' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Cuenta bloqueada.');
    END IF;
    INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION)
    VALUES (p_id_cuenta,'DEPOSITO',p_monto,'Deposito por procedimiento');
    p_mensaje := 'Deposito realizado correctamente.';
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_DEPOSITAR;
/
-- @FIN

-- @OBJETO: SP_RETIRAR
CREATE OR REPLACE PROCEDURE SP_RETIRAR (
    p_id_cuenta IN NUMBER,
    p_monto IN NUMBER,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_estado TBL_CUENTAS.ESTADO%TYPE;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_retirar;

        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_RETIRAR', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_retirar;
    p_estado := 'OK'; p_codigo := 0;
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Monto inválido: debe ser mayor que cero.');
    END IF;
    BEGIN
        SELECT ESTADO INTO v_estado FROM TBL_CUENTAS
        WHERE ID_CUENTA = p_id_cuenta FOR UPDATE WAIT 5;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cuenta inexistente.');
    END;
    IF v_estado <> 'ACTIVA' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Cuenta bloqueada.');
    END IF;
    IF FN_SALDO_DISPONIBLE(p_id_cuenta) < p_monto THEN
        RAISE_APPLICATION_ERROR(-20001, 'Saldo insuficiente para el retiro.');
    END IF;
    INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION)
    VALUES (p_id_cuenta,'RETIRO',p_monto,'Retiro por procedimiento');
    p_mensaje := 'Retiro realizado correctamente.';
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_RETIRAR;
/
-- @FIN

-- @OBJETO: SP_TRANSFERIR
CREATE OR REPLACE PROCEDURE SP_TRANSFERIR (
    p_origen IN NUMBER,
    p_destino IN NUMBER,
    p_monto IN NUMBER,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_encontradas PLS_INTEGER := 0;
    v_bloqueadas PLS_INTEGER := 0;
    v_cliente NUMBER;
    v_categoria TBL_CLIENTES.CATEGORIA%TYPE;
    v_comision NUMBER;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_transferir;

        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_TRANSFERIR', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_transferir;
    p_estado := 'OK'; p_codigo := 0;
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Monto inválido: debe ser mayor que cero.');
    END IF;
    IF p_origen = p_destino THEN
        RAISE_APPLICATION_ERROR(-20005, 'No se puede transferir a la misma cuenta.');
    END IF;
    -- Un solo cursor bloquea ambas cuentas en orden estable; no hacer dos SELECT separados.
    FOR r IN (SELECT ID_CUENTA,ID_CLIENTE,ESTADO FROM TBL_CUENTAS
              WHERE ID_CUENTA IN (p_origen,p_destino)
              ORDER BY ID_CUENTA FOR UPDATE WAIT 5) LOOP
        v_encontradas := v_encontradas + 1;
        IF r.ESTADO <> 'ACTIVA' THEN v_bloqueadas := v_bloqueadas + 1; END IF;
        IF r.ID_CUENTA = p_origen THEN v_cliente := r.ID_CLIENTE; END IF;
    END LOOP;
    IF v_encontradas <> 2 THEN RAISE_APPLICATION_ERROR(-20002, 'Cuenta inexistente.'); END IF;
    IF v_bloqueadas > 0 THEN RAISE_APPLICATION_ERROR(-20003, 'Una cuenta está bloqueada.'); END IF;
    SELECT CATEGORIA INTO v_categoria FROM TBL_CLIENTES WHERE ID_CLIENTE = v_cliente;
    v_comision := FN_COMISION(p_monto,v_categoria);
    IF FN_SALDO_DISPONIBLE(p_origen) < p_monto + v_comision THEN
        RAISE_APPLICATION_ERROR(-20001, 'Saldo insuficiente para monto más comisión.');
    END IF;
    INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION,ID_CUENTA_RELACIONADA)
    VALUES (p_origen,'TRANSF_ENVIADA',p_monto,'Transferencia enviada',p_destino);
    INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION,ID_CUENTA_RELACIONADA)
    VALUES (p_origen,'COMISION',v_comision,'Comisión de transferencia',p_destino);
    INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION,ID_CUENTA_RELACIONADA)
    VALUES (p_destino,'TRANSF_RECIBIDA',p_monto,'Transferencia recibida',p_origen);
    p_mensaje := 'Transferencia realizada. Comisión cobrada: S/ ' || TO_CHAR(v_comision,'FM999999999990D00','NLS_NUMERIC_CHARACTERS=''.,''');
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_TRANSFERIR;
/
-- @FIN

-- @OBJETO: SP_CAMBIAR_ESTADO_CUENTA
CREATE OR REPLACE PROCEDURE SP_CAMBIAR_ESTADO_CUENTA (
    p_id_cuenta IN NUMBER,
    p_nuevo_estado IN VARCHAR2,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_estado TBL_CUENTAS.ESTADO%TYPE;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_cambiar_estado_cuenta;

        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_CAMBIAR_ESTADO_CUENTA', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_cambiar_estado_cuenta;
    p_estado := 'OK'; p_codigo := 0;
    BEGIN
        SELECT ESTADO INTO v_estado FROM TBL_CUENTAS
        WHERE ID_CUENTA = p_id_cuenta FOR UPDATE WAIT 5;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cuenta inexistente.');
    END;
    IF p_nuevo_estado IS NULL OR p_nuevo_estado NOT IN ('ACTIVA','BLOQUEADA') THEN
        RAISE_APPLICATION_ERROR(-20007, 'Estado de cuenta inválido.');
    END IF;
    UPDATE TBL_CUENTAS SET ESTADO = p_nuevo_estado WHERE ID_CUENTA = p_id_cuenta;
    p_mensaje := 'Estado de cuenta: ' || p_nuevo_estado;
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_CAMBIAR_ESTADO_CUENTA;
/
-- @FIN

-- @OBJETO: SP_APLICAR_INTERESES
CREATE OR REPLACE PROCEDURE SP_APLICAR_INTERESES (
    p_mes_ref IN DATE DEFAULT SYSDATE,
    p_n_cuentas OUT NUMBER,
    p_n_omitidas OUT NUMBER,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_mes DATE;
    v_interes NUMBER(14,2);
    v_activas PLS_INTEGER := 0;
    v_ids JSON_ARRAY_T := JSON_ARRAY_T();
    v_ids_json CLOB;
    v_encontradas BOOLEAN;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_aplicar_intereses;
        p_n_cuentas := 0; p_n_omitidas := 0;
        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_APLICAR_INTERESES', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_aplicar_intereses;
    p_estado := 'OK'; p_codigo := 0;
    p_n_cuentas := 0; p_n_omitidas := 0;
    v_mes := TRUNC(NVL(p_mes_ref,SYSDATE),'MM');
    -- Bloquear antes de insertar; incluye activas no elegibles para contar omitidas.
    FOR r IN (SELECT ID_CUENTA,SALDO,TASA_INTERES_ANUAL,FECHA_ULT_INTERES
              FROM TBL_CUENTAS WHERE ESTADO = 'ACTIVA'
              ORDER BY ID_CUENTA FOR UPDATE WAIT 5) LOOP
        v_activas := v_activas + 1;
        IF r.TASA_INTERES_ANUAL > 0 AND r.SALDO > 0
           AND (r.FECHA_ULT_INTERES IS NULL OR r.FECHA_ULT_INTERES < v_mes) THEN
            v_interes := ROUND(r.SALDO * r.TASA_INTERES_ANUAL / 100 / 12,2);
            -- Un importe redondeado a cero no es movimiento válido: cuenta omitida.
            IF v_interes > 0 THEN
                INSERT INTO TBL_MOVIMIENTOS (ID_CUENTA,TIPO,MONTO,DESCRIPCION)
                VALUES (r.ID_CUENTA,'INTERES',v_interes,'Interés del mes ' || TO_CHAR(v_mes,'YYYY-MM'));
                v_ids.APPEND(r.ID_CUENTA);
            END IF;
        END IF;
    END LOOP;
    -- Mismo criterio, limitado a cuentas que efectivamente recibieron un movimiento.
    -- JSON_TABLE evita crear tipos auxiliares o usar prefijos de otro esquema.
    v_ids_json := v_ids.TO_CLOB();
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
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_APLICAR_INTERESES;
/
-- @FIN

-- @OBJETO: SP_ACTUALIZAR_CATEGORIAS
CREATE OR REPLACE PROCEDURE SP_ACTUALIZAR_CATEGORIAS (
    p_n_procesados OUT NUMBER,
    p_n_cambios OUT NUMBER,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    CURSOR c_clientes IS SELECT ID_CLIENTE,CATEGORIA FROM TBL_CLIENTES
        ORDER BY ID_CLIENTE FOR UPDATE WAIT 5;
    v_cliente c_clientes%ROWTYPE;
    v_saldo NUMBER;
    v_categoria TBL_CLIENTES.CATEGORIA%TYPE;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_actualizar_categorias;
        IF c_clientes%ISOPEN THEN CLOSE c_clientes; END IF;
        p_n_procesados := 0; p_n_cambios := 0;
        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_ACTUALIZAR_CATEGORIAS', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_actualizar_categorias;
    p_estado := 'OK'; p_codigo := 0;
    p_n_procesados := 0; p_n_cambios := 0;
    OPEN c_clientes;
    LOOP
        FETCH c_clientes INTO v_cliente;
        EXIT WHEN c_clientes%NOTFOUND;
        p_n_procesados := p_n_procesados + 1;
        SELECT NVL(SUM(SALDO),0) INTO v_saldo FROM TBL_CUENTAS WHERE ID_CLIENTE = v_cliente.ID_CLIENTE;
        v_categoria := FN_CATEGORIA_CLIENTE(v_saldo);
        IF v_categoria <> v_cliente.CATEGORIA THEN
            UPDATE TBL_CLIENTES SET CATEGORIA = v_categoria WHERE ID_CLIENTE = v_cliente.ID_CLIENTE;
            p_n_cambios := p_n_cambios + 1;
        END IF;
    END LOOP;
    CLOSE c_clientes;
    p_mensaje := 'Clientes procesados: ' || p_n_procesados || '; cambios: ' || p_n_cambios;
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_ACTUALIZAR_CATEGORIAS;
/
-- @FIN

-- @OBJETO: SP_REPORTE_CLIENTES
CREATE OR REPLACE PROCEDURE SP_REPORTE_CLIENTES (
    p_id_cliente IN NUMBER DEFAULT NULL,
    p_limite_movs IN NUMBER DEFAULT 5,
    p_json OUT CLOB,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    CURSOR c_clientes IS SELECT ID_CLIENTE,NOMBRES,APELLIDOS,CATEGORIA FROM TBL_CLIENTES
        WHERE p_id_cliente IS NULL OR ID_CLIENTE = p_id_cliente ORDER BY ID_CLIENTE;
    CURSOR c_cuentas(p_cli NUMBER) IS SELECT ID_CUENTA,NRO_CUENTA,SALDO,ESTADO
        FROM TBL_CUENTAS WHERE ID_CLIENTE = p_cli ORDER BY ID_CUENTA;
    CURSOR c_movs(p_cta NUMBER,p_limite NUMBER) IS
        SELECT ID_MOVIMIENTO,TIPO,MONTO,FECHA,DESCRIPCION FROM (
            SELECT ID_MOVIMIENTO,TIPO,MONTO,FECHA,DESCRIPCION FROM TBL_MOVIMIENTOS
            WHERE ID_CUENTA = p_cta ORDER BY FECHA DESC,ID_MOVIMIENTO DESC
        ) WHERE ROWNUM <= p_limite;
    v_clientes JSON_ARRAY_T := JSON_ARRAY_T();
    v_cuentas JSON_ARRAY_T;
    v_movimientos JSON_ARRAY_T;
    v_cli JSON_OBJECT_T;
    v_cta JSON_OBJECT_T;
    v_mov JSON_OBJECT_T;
    v_limite PLS_INTEGER;
    v_total PLS_INTEGER := 0;
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_reporte_clientes;
        p_json := NULL;
        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_REPORTE_CLIENTES', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_reporte_clientes;
    p_estado := 'OK'; p_codigo := 0;
    p_json := NULL;
    IF p_limite_movs IS NULL OR p_limite_movs < 0 OR p_limite_movs > 1000
       OR p_limite_movs <> TRUNC(p_limite_movs) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Límite de movimientos inválido: entero de 0 a 1000.');
    END IF;
    v_limite := p_limite_movs;
    FOR cli IN c_clientes LOOP
        v_total := v_total + 1;
        v_cli := JSON_OBJECT_T(); v_cuentas := JSON_ARRAY_T();
        v_cli.PUT('id_cliente',cli.ID_CLIENTE);
        v_cli.PUT('nombre',cli.NOMBRES || ' ' || cli.APELLIDOS);
        v_cli.PUT('categoria',cli.CATEGORIA);
        FOR cta IN c_cuentas(cli.ID_CLIENTE) LOOP
            v_cta := JSON_OBJECT_T(); v_movimientos := JSON_ARRAY_T();
            v_cta.PUT('id_cuenta',cta.ID_CUENTA); v_cta.PUT('nro_cuenta',cta.NRO_CUENTA);
            v_cta.PUT('saldo',cta.SALDO); v_cta.PUT('estado',cta.ESTADO);
            FOR mov IN c_movs(cta.ID_CUENTA,v_limite) LOOP
                v_mov := JSON_OBJECT_T();
                v_mov.PUT('id_movimiento',mov.ID_MOVIMIENTO); v_mov.PUT('tipo',mov.TIPO);
                v_mov.PUT('monto',mov.MONTO); v_mov.PUT('fecha',TO_CHAR(mov.FECHA,'YYYY-MM-DD"T"HH24:MI:SS.FF3'));
                v_mov.PUT('descripcion',mov.DESCRIPCION); v_movimientos.APPEND(v_mov);
            END LOOP;
            v_cta.PUT('movimientos',v_movimientos); v_cuentas.APPEND(v_cta);
        END LOOP;
        v_cli.PUT('cuentas',v_cuentas); v_clientes.APPEND(v_cli);
    END LOOP;
    IF p_id_cliente IS NOT NULL AND v_total = 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Cliente inexistente.');
    END IF;
    p_json := v_clientes.TO_CLOB();
    p_mensaje := 'Reporte generado: ' || v_total || ' clientes.';
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_REPORTE_CLIENTES;
/
-- @FIN

-- @OBJETO: SP_LAB_ERRORES
CREATE OR REPLACE PROCEDURE SP_LAB_ERRORES (
    p_caso IN VARCHAR2,
    p_detalle OUT VARCHAR2,
    p_estado OUT VARCHAR2,
    p_codigo OUT NUMBER,
    p_mensaje OUT VARCHAR2
) AS
    v_num NUMBER;
    v_cero NUMBER := 0;
    v_corto VARCHAR2(1);
    v_dni TBL_CLIENTES.DNI%TYPE;
    v_codigo NUMBER;
    v_error VARCHAR2(4000);
    e_saldo EXCEPTION; PRAGMA EXCEPTION_INIT(e_saldo, -20001);
    e_cuenta EXCEPTION; PRAGMA EXCEPTION_INIT(e_cuenta, -20002);
    e_bloqueada EXCEPTION; PRAGMA EXCEPTION_INIT(e_bloqueada, -20003);
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto, -20004);
    e_misma EXCEPTION; PRAGMA EXCEPTION_INIT(e_misma, -20005);
    e_cliente EXCEPTION; PRAGMA EXCEPTION_INIT(e_cliente, -20006);
    e_estado EXCEPTION; PRAGMA EXCEPTION_INIT(e_estado, -20007);
    e_ocupada EXCEPTION; PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

    PROCEDURE fallar(p_error NUMBER, p_texto VARCHAR2) IS
    BEGIN
        ROLLBACK TO sv_lab_errores;
        p_detalle := p_texto;
        p_estado := 'ERROR';
        p_codigo := p_error;
        p_mensaje := p_texto;
        SP_LOG_ERROR('SP_LAB_ERRORES', p_error, p_texto);
    END;
BEGIN
    SAVEPOINT sv_lab_errores;
    p_estado := 'OK'; p_codigo := 0;
    p_detalle := NULL;
    CASE UPPER(p_caso)
    WHEN 'NO_DATA_FOUND' THEN
        BEGIN
            SELECT 1 INTO v_num FROM dual WHERE 1 = 0;
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN NO_DATA_FOUND THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
        END;
    WHEN 'TOO_MANY_ROWS' THEN
        BEGIN
            SELECT n INTO v_num FROM (SELECT 1 n FROM dual UNION ALL SELECT 2 n FROM dual);
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN TOO_MANY_ROWS THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
        END;
    WHEN 'ZERO_DIVIDE' THEN
        BEGIN
            v_num := 1 / v_cero;
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN ZERO_DIVIDE THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
        END;
    WHEN 'VALUE_ERROR' THEN
        BEGIN
            v_corto := 'texto demasiado largo';
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN VALUE_ERROR THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
        END;
    WHEN 'WHEN_OTHERS' THEN
        BEGIN
            SELECT TO_NUMBER('abc') INTO v_num FROM dual;
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN OTHERS THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
            IF v_codigo <> -1722 THEN RAISE; END IF;
        END;
    WHEN 'DUP_VAL_ON_INDEX' THEN
        SELECT MIN(DNI) INTO v_dni FROM TBL_CLIENTES;
        IF v_dni IS NULL THEN
            INSERT INTO TBL_CLIENTES (DNI,NOMBRES,APELLIDOS,EMAIL)
            VALUES ('99999999','Laboratorio','Temporal','lab-' || RAWTOHEX(SYS_GUID()) || '@example.invalid');
            v_dni := '99999999';
        END IF;
        SAVEPOINT sv_lab_duplicado;
        BEGIN
            INSERT INTO TBL_CLIENTES (DNI,NOMBRES,APELLIDOS,EMAIL)
            VALUES (v_dni,'Duplicado','Temporal','dup-' || RAWTOHEX(SYS_GUID()) || '@example.invalid');
            RAISE_APPLICATION_ERROR(-20004, 'No se produjo la excepción esperada.');
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
            ROLLBACK TO sv_lab_duplicado;
        END;
    WHEN 'RERAISE' THEN
        BEGIN
            BEGIN
                v_num := 1 / v_cero;
            EXCEPTION WHEN ZERO_DIVIDE THEN
                SP_LOG_ERROR('SP_LAB_ERRORES.RERAISE',SQLCODE,SQLERRM);
                RAISE;
            END;
        EXCEPTION WHEN ZERO_DIVIDE THEN
            v_codigo := SQLCODE; v_error := SQLERRM;
        END;
    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Caso de laboratorio desconocido.');
    END CASE;
    ROLLBACK TO sv_lab_errores;
    p_detalle := 'SQLCODE=' || v_codigo || '; SQLERRM=' || v_error;
    SP_LOG_ERROR('SP_LAB_ERRORES',v_codigo,v_error);
    p_mensaje := 'Excepción esperada capturada.';
EXCEPTION
    WHEN e_saldo OR e_cuenta OR e_bloqueada OR e_monto OR e_misma OR e_cliente OR e_estado OR e_ocupada THEN
        fallar(SQLCODE, SQLERRM);
    WHEN OTHERS THEN
        fallar(SQLCODE, SQLERRM);
END SP_LAB_ERRORES;
/
-- @FIN
