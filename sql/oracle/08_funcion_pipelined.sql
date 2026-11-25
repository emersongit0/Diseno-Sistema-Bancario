-- Fase 2B. Ejecutar como SCRIPT después de 07_procedimientos.sql.

-- @OBJETO: FN_ESTADO_CUENTA_MENSUAL
CREATE OR REPLACE FUNCTION FN_ESTADO_CUENTA_MENSUAL (
    p_id_cuenta IN NUMBER,
    p_anio IN NUMBER,
    p_mes IN NUMBER
) RETURN T_MOV_TABLA PIPELINED AS
    v_inicio DATE;
    v_fin DATE;
    v_saldo TBL_CUENTAS.SALDO%TYPE;
    CURSOR c_movimientos IS
        SELECT FECHA,TIPO,DESCRIPCION,MONTO FROM TBL_MOVIMIENTOS
        WHERE ID_CUENTA = p_id_cuenta AND FECHA >= v_inicio AND FECHA < v_fin
        ORDER BY FECHA,ID_MOVIMIENTO;
    v_mov c_movimientos%ROWTYPE;
BEGIN
    IF p_anio IS NULL OR p_anio < 1 OR p_anio > 9998 OR p_anio <> TRUNC(p_anio)
       OR p_mes IS NULL OR p_mes < 1 OR p_mes > 12 OR p_mes <> TRUNC(p_mes) THEN
        RAISE_APPLICATION_ERROR(-20004, 'Año o mes inválido.');
    END IF;
    v_inicio := TO_DATE(TO_CHAR(p_anio,'FM0000') || TO_CHAR(p_mes,'FM00') || '01','FXYYYYMMDD');
    v_fin := ADD_MONTHS(v_inicio,1);
    -- Verifica existencia aunque el mes no tenga movimientos.
    v_saldo := FN_SALDO_DISPONIBLE(p_id_cuenta);
    -- Saldo de apertura: movimientos anteriores, no el saldo actual de la cuenta.
    SELECT NVL(SUM(CASE WHEN TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES')
                        THEN MONTO ELSE -MONTO END),0)
    INTO v_saldo FROM TBL_MOVIMIENTOS
    WHERE ID_CUENTA = p_id_cuenta AND FECHA < v_inicio;
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
    RETURN;
EXCEPTION
    WHEN NO_DATA_NEEDED THEN
        IF c_movimientos%ISOPEN THEN CLOSE c_movimientos; END IF;
        RETURN;
    WHEN OTHERS THEN
        IF c_movimientos%ISOPEN THEN CLOSE c_movimientos; END IF;
        RAISE;
END FN_ESTADO_CUENTA_MENSUAL;
/
-- @FIN
