-- Fase 3. Ejecutar UNA SOLA VEZ después de 09_sinonimos.sql.
-- Requiere tablas de clientes, cuentas y movimientos vacías; no borra datos.
-- Usar una hoja sin transacciones pendientes (el script confirma o revierte la carga).
-- No presupone valores iniciales de las secuencias: usa los IDs devueltos.
-- Resultado confirmado al final: 6 clientes, 8 cuentas y 30 movimientos.
-- Los logs autónomos de las fases anteriores se conservan.
DECLARE
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_clientes t_ids;
    v_cuentas t_ids;
    v_estado VARCHAR2(10);
    v_codigo NUMBER;
    v_mensaje VARCHAR2(4000);
    v_nro VARCHAR2(12);
    v_total NUMBER;
    v_procesados NUMBER;
    v_cambios NUMBER;
    PROCEDURE exigir(p_condicion BOOLEAN,p_texto VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20984,'Datos de prueba: ' || p_texto);
        END IF;
    END;
    PROCEDURE comprobar(p_contexto VARCHAR2) IS
    BEGIN
        exigir(v_estado = 'OK' AND v_codigo = 0,p_contexto || ': ' || v_mensaje);
    END;
    PROCEDURE cliente(p_i PLS_INTEGER,p_dni VARCHAR2,p_nombres VARCHAR2,p_apellidos VARCHAR2) IS
    BEGIN
        INSERT INTO TBL_CLIENTES (DNI,NOMBRES,APELLIDOS,EMAIL)
        VALUES (p_dni,p_nombres,p_apellidos,'demo' || p_i || '@banco.example')
        RETURNING ID_CLIENTE INTO v_clientes(p_i);
    END;
    PROCEDURE cuenta(p_i PLS_INTEGER,p_cliente PLS_INTEGER,p_tipo VARCHAR2,p_saldo NUMBER) IS
    BEGIN
        SP_ABRIR_CUENTA(v_clientes(p_cliente),p_tipo,p_saldo,NULL,
            v_cuentas(p_i),v_nro,v_estado,v_codigo,v_mensaje);
        comprobar('Abrir cuenta ' || p_i);
    END;
BEGIN
    SELECT (SELECT COUNT(*) FROM TBL_CLIENTES) + (SELECT COUNT(*) FROM TBL_CUENTAS)
         + (SELECT COUNT(*) FROM TBL_MOVIMIENTOS) INTO v_total FROM dual;
    exigir(v_total = 0,'Las tablas no están vacías: no se ejecutó la carga. No repetir el script 10.');
    cliente(1,'71000001','Ana','Torres');
    cliente(2,'71000002','Luis','Vargas');
    cliente(3,'71000003','María','Quispe');
    cliente(4,'71000004','José','Rojas');
    cliente(5,'71000005','Lucía','Castillo');
    cliente(6,'71000006','Diego','Flores');
    -- Ocho depósitos iniciales generados por SP_ABRIR_CUENTA.
    cuenta(1,1,'AHORROS',1000);
    cuenta(2,2,'CORRIENTE',2000);
    cuenta(3,3,'AHORROS',10000);
    cuenta(4,4,'CORRIENTE',15000);
    cuenta(5,5,'AHORROS',60000);
    cuenta(6,6,'AHORROS',80000);
    cuenta(7,1,'CORRIENTE',3000);
    cuenta(8,3,'AHORROS',12000);
    -- Ocho depósitos y ocho retiros: 24 movimientos acumulados.
    FOR i IN 1 .. 8 LOOP
        SP_DEPOSITAR(v_cuentas(i),200,v_estado,v_codigo,v_mensaje);
        comprobar('Depósito ' || i);
        SP_RETIRAR(v_cuentas(i),50,v_estado,v_codigo,v_mensaje);
        comprobar('Retiro ' || i);
    END LOOP;
    SP_ACTUALIZAR_CATEGORIAS(v_procesados,v_cambios,v_estado,v_codigo,v_mensaje);
    comprobar('Categorías previas a transferencias');
    -- Cada transferencia genera tres movimientos. Total final: 30.
    SP_TRANSFERIR(v_cuentas(1),v_cuentas(2),100,v_estado,v_codigo,v_mensaje);
    comprobar('Transferencia BASICO');
    SP_TRANSFERIR(v_cuentas(5),v_cuentas(4),500,v_estado,v_codigo,v_mensaje);
    comprobar('Transferencia PREMIUM');
    SP_ACTUALIZAR_CATEGORIAS(v_procesados,v_cambios,v_estado,v_codigo,v_mensaje);
    comprobar('Categorías finales');
    SELECT COUNT(*) INTO v_total FROM TBL_CLIENTES;
    exigir(v_total = 6,'Se esperan 6 clientes.');
    SELECT COUNT(*) INTO v_total FROM TBL_CUENTAS;
    exigir(v_total = 8,'Se esperan 8 cuentas.');
    SELECT COUNT(*) INTO v_total FROM TBL_MOVIMIENTOS;
    exigir(v_total = 30,'Se esperan 30 movimientos.');
    FOR r IN (SELECT CATEGORIA,COUNT(*) cantidad FROM TBL_CLIENTES GROUP BY CATEGORIA) LOOP
        exigir(r.cantidad = 2,'Se esperan 2 clientes por categoría.');
        DBMS_OUTPUT.PUT_LINE(r.CATEGORIA || ': ' || r.cantidad || ' clientes');
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('DATOS OK: 6 clientes, 8 cuentas, 30 movimientos; COMMIT completado.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
