-- Fase 2A. Ejecutar como SCRIPT después de 04_vistas.sql.

-- @OBJETO: SP_LOG_ERROR
CREATE OR REPLACE PROCEDURE SP_LOG_ERROR (
    p_proc IN VARCHAR2,
    p_codigo IN NUMBER,
    p_mensaje IN VARCHAR2
) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO TBL_LOG_ERRORES (ID_LOG, PROCEDIMIENTO, CODIGO, MENSAJE, FECHA)
    VALUES (SQ_LOG.NEXTVAL, SUBSTRB(p_proc, 1, 128), p_codigo,
            SUBSTRB(p_mensaje, 1, 4000), SYSTIMESTAMP);
    -- Única utilidad autorizada para confirmar su propia transacción.
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_LOG_ERROR;
/
-- @FIN

-- @OBJETO: FN_SALDO_DISPONIBLE
CREATE OR REPLACE FUNCTION FN_SALDO_DISPONIBLE (
    p_id_cuenta IN NUMBER
) RETURN NUMBER AS
    v_saldo TBL_CUENTAS.SALDO%TYPE;
BEGIN
    SELECT SALDO INTO v_saldo
    FROM TBL_CUENTAS
    WHERE ID_CUENTA = p_id_cuenta;
    RETURN v_saldo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cuenta inexistente.');
END FN_SALDO_DISPONIBLE;
/
-- @FIN

-- @OBJETO: FN_CATEGORIA_CLIENTE
CREATE OR REPLACE FUNCTION FN_CATEGORIA_CLIENTE (
    p_saldo_total IN NUMBER
) RETURN VARCHAR2 AS
    v_gold TBL_LIMITES_CATEGORIAS.LIMITE_GOLD%TYPE;
    v_premium TBL_LIMITES_CATEGORIAS.LIMITE_PREMIUM%TYPE;
BEGIN
    SELECT LIMITE_GOLD,LIMITE_PREMIUM INTO v_gold,v_premium
    FROM TBL_LIMITES_CATEGORIAS WHERE ID_CONFIG=1;
    IF NVL(p_saldo_total, 0) < v_gold THEN
        RETURN 'BASICO';
    ELSIF p_saldo_total < v_premium THEN
        RETURN 'GOLD';
    ELSE
        RETURN 'PREMIUM';
    END IF;
END FN_CATEGORIA_CLIENTE;
/
-- @FIN

-- @OBJETO: FN_COMISION
CREATE OR REPLACE FUNCTION FN_COMISION (
    p_monto IN NUMBER,
    p_categoria IN VARCHAR2 DEFAULT 'BASICO'
) RETURN NUMBER AS
    c_tasa_basico CONSTANT NUMBER := 0.015;
    c_tasa_gold CONSTANT NUMBER := 0.008;
    c_tasa_premium CONSTANT NUMBER := 0.003;
    c_minimo CONSTANT NUMBER := 1.00;
    v_tasa NUMBER;
BEGIN
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Monto inválido: debe ser mayor que cero.');
    END IF;
    IF UPPER(TRIM(p_categoria)) = 'PREMIUM' THEN
        v_tasa := c_tasa_premium;
    ELSIF UPPER(TRIM(p_categoria)) = 'GOLD' THEN
        v_tasa := c_tasa_gold;
    ELSE
        -- Categoría nula o desconocida usa la tarifa BASICO.
        v_tasa := c_tasa_basico;
    END IF;
    RETURN ROUND(GREATEST(p_monto * v_tasa, c_minimo), 2);
END FN_COMISION;
/
-- @FIN
