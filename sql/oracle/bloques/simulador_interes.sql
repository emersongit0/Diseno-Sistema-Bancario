-- @OBJETO: BLOQUE_SIMULADOR_INTERES
DECLARE
    c_max_meses CONSTANT PLS_INTEGER := 600;
    c_meses_anio CONSTANT NUMBER := 12;
    v_cuenta TBL_CUENTAS%ROWTYPE;
    v_inicial TBL_CUENTAS.SALDO%TYPE;
    v_tasa TBL_CUENTAS.TASA_INTERES_ANUAL%TYPE;
    v_saldo NUMBER;
    v_saldo_meta NUMBER;
    v_aporte NUMBER := :p_aporte_mensual;
    v_meta NUMBER := :p_meta;
    v_meses NUMBER := :p_meses;
    v_mes PLS_INTEGER := 0;
    v_proyeccion_json JSON_ARRAY_T := JSON_ARRAY_T();
    v_fila JSON_OBJECT_T;
    e_monto EXCEPTION; PRAGMA EXCEPTION_INIT(e_monto,-20004);
BEGIN
    :p_saldo_final := NULL; :p_meses_meta := NULL; :p_proyeccion := NULL;
    :p_estado := 'OK'; :p_codigo := 0; :p_mensaje := 'Simulación completada.';
    IF :p_id_cuenta IS NOT NULL THEN
        SELECT * INTO v_cuenta FROM TBL_CUENTAS WHERE ID_CUENTA = :p_id_cuenta;
        v_inicial := v_cuenta.SALDO; v_tasa := NVL(v_cuenta.TASA_INTERES_ANUAL,0);
    ELSE
        v_inicial := :p_saldo_inicial; v_tasa := :p_tasa_anual;
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
        :p_meses_meta := v_mes;
    ELSE
        :p_meses_meta := NULL;
        :p_mensaje := 'La meta no se alcanza en el límite de 600 meses.';
    END IF;
    :p_saldo_final := v_saldo;
    :p_proyeccion := v_proyeccion_json.TO_CLOB();
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :p_estado := 'ERROR'; :p_codigo := -20002; :p_mensaje := 'Cuenta inexistente.';
    WHEN e_monto THEN
        :p_estado := 'ERROR'; :p_codigo := -20004; :p_mensaje := 'Datos de simulación inválidos.';
    WHEN OTHERS THEN
        :p_estado := 'ERROR'; :p_codigo := SQLCODE; :p_mensaje := 'No se pudo calcular la simulación.';
END;
/
-- @FIN
