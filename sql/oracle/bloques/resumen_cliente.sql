-- @OBJETO: BLOQUE_RESUMEN_CLIENTE
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
    :p_json := NULL; :p_estado := 'OK'; :p_codigo := 0;
    :p_mensaje := 'Resumen generado.';
    SELECT * INTO v_cliente FROM TBL_CLIENTES WHERE ID_CLIENTE = :p_id_cliente;
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
    :p_json := v_resumen_json.TO_CLOB();
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :p_estado := 'ERROR'; :p_codigo := -20006; :p_mensaje := 'Cliente inexistente.';
    WHEN OTHERS THEN
        :p_estado := 'ERROR'; :p_codigo := SQLCODE; :p_mensaje := 'No se pudo generar el resumen.';
END;
/
-- @FIN
