-- Ejecutar como SCRIPT en FreeSQL. No ejecutarlo desde el agente.
-- DDL confirma transacciones: usar una hoja sin transacciones pendientes.
-- La primera consulta debe devolver CERO filas (40 nombres de B2.2).
SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN (
        'TBL_CLIENTES',
        'TBL_CUENTAS',
        'TBL_MOVIMIENTOS',
        'TBL_AUDITORIA',
        'TBL_LOG_ERRORES',
        'TBL_LIMITES_CATEGORIAS',
        'SQ_CLIENTE',
        'SQ_CUENTA',
        'SQ_MOVIMIENTO',
        'SQ_AUDITORIA',
        'SQ_LOG',
        'T_MOV_FILA',
        'T_MOV_TABLA',
        'V_ESTADO_CUENTA',
        'V_CUENTAS_RESUMEN',
        'FN_SALDO_DISPONIBLE',
        'FN_CATEGORIA_CLIENTE',
        'FN_COMISION',
        'FN_ESTADO_CUENTA_MENSUAL',
        'SP_LOG_ERROR',
        'SP_ABRIR_CUENTA',
        'SP_DEPOSITAR',
        'SP_RETIRAR',
        'SP_TRANSFERIR',
        'SP_CAMBIAR_ESTADO_CUENTA',
        'SP_APLICAR_INTERESES',
        'SP_ACTUALIZAR_CATEGORIAS',
        'SP_REPORTE_CLIENTES',
        'SP_LAB_ERRORES',
        'TRG_CLIENTES_BI',
        'TRG_CUENTAS_BI',
        'TRG_MOVIMIENTOS_BI',
        'TRG_MOVIMIENTOS_AI',
        'TRG_CUENTAS_AU',
        'CLIENTES',
        'CUENTAS',
        'MOVIMIENTOS',
        'AUDITORIA',
        'LOG_ERRORES',
        'LIMITES_CATEGORIAS'
)
ORDER BY object_name, object_type;

-- Auxiliares transitorios F0P_*: nunca se borran objetos preexistentes.
-- Si hay colisiones o faltan privilegios, se aborta y se conserva el error original.
DECLARE
    v_total PLS_INTEGER;
    TYPE t_sentencias IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;
    v_drops t_sentencias;
    v_n PLS_INTEGER := 0;
    PROCEDURE crear(p_ddl VARCHAR2, p_drop VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
        v_n := v_n + 1;
        v_drops(v_n) := p_drop;
    END;
    PROCEDURE limpiar IS
    BEGIN
        FOR i IN REVERSE 1 .. v_n LOOP
            EXECUTE IMMEDIATE v_drops(i);
        END LOOP;
    END;
BEGIN
    SELECT COUNT(*) INTO v_total FROM USER_OBJECTS
    WHERE object_name IN (
        'TBL_CLIENTES',
        'TBL_CUENTAS',
        'TBL_MOVIMIENTOS',
        'TBL_AUDITORIA',
        'TBL_LOG_ERRORES',
        'TBL_LIMITES_CATEGORIAS',
        'SQ_CLIENTE',
        'SQ_CUENTA',
        'SQ_MOVIMIENTO',
        'SQ_AUDITORIA',
        'SQ_LOG',
        'T_MOV_FILA',
        'T_MOV_TABLA',
        'V_ESTADO_CUENTA',
        'V_CUENTAS_RESUMEN',
        'FN_SALDO_DISPONIBLE',
        'FN_CATEGORIA_CLIENTE',
        'FN_COMISION',
        'FN_ESTADO_CUENTA_MENSUAL',
        'SP_LOG_ERROR',
        'SP_ABRIR_CUENTA',
        'SP_DEPOSITAR',
        'SP_RETIRAR',
        'SP_TRANSFERIR',
        'SP_CAMBIAR_ESTADO_CUENTA',
        'SP_APLICAR_INTERESES',
        'SP_ACTUALIZAR_CATEGORIAS',
        'SP_REPORTE_CLIENTES',
        'SP_LAB_ERRORES',
        'TRG_CLIENTES_BI',
        'TRG_CUENTAS_BI',
        'TRG_MOVIMIENTOS_BI',
        'TRG_MOVIMIENTOS_AI',
        'TRG_CUENTAS_AU',
        'CLIENTES',
        'CUENTAS',
        'MOVIMIENTOS',
        'AUDITORIA',
        'LOG_ERRORES',
        'LIMITES_CATEGORIAS'
    );
    IF v_total > 0 THEN
        RAISE_APPLICATION_ERROR(-20990, 'Ya existen nombres de B2.2; detenerse y revisar la primera consulta.');
    END IF;
    SELECT COUNT(*) INTO v_total FROM USER_OBJECTS
    WHERE object_name IN ('F0P_TABLA','F0P_SECUENCIA','F0P_VISTA',
        'F0P_SINONIMO','F0P_TIPO','F0P_PROCEDIMIENTO','F0P_FUNCION','F0P_TRIGGER');
    IF v_total > 0 THEN
        RAISE_APPLICATION_ERROR(-20991, 'Ya existen auxiliares F0P_*; no se modificaron.');
    END IF;
    crear('CREATE TABLE F0P_TABLA (ID NUMBER CONSTRAINT PK_F0P_TABLA PRIMARY KEY)', 'DROP TABLE F0P_TABLA PURGE');
    crear('CREATE SEQUENCE F0P_SECUENCIA START WITH 1', 'DROP SEQUENCE F0P_SECUENCIA');
    crear('CREATE VIEW F0P_VISTA AS SELECT ID FROM F0P_TABLA', 'DROP VIEW F0P_VISTA');
    crear('CREATE SYNONYM F0P_SINONIMO FOR F0P_TABLA', 'DROP SYNONYM F0P_SINONIMO');
    crear('CREATE TYPE F0P_TIPO AS OBJECT (ID NUMBER)', 'DROP TYPE F0P_TIPO');
    crear('CREATE PROCEDURE F0P_PROCEDIMIENTO AS BEGIN NULL; END;', 'DROP PROCEDURE F0P_PROCEDIMIENTO');
    crear('CREATE FUNCTION F0P_FUNCION RETURN NUMBER AS BEGIN RETURN 1; END;', 'DROP FUNCTION F0P_FUNCION');
    crear('CREATE TRIGGER F0P_TRIGGER BEFORE INSERT ON F0P_TABLA FOR EACH ROW BEGIN IF :NEW.ID IS NULL THEN :NEW.ID := F0P_SECUENCIA.NEXTVAL; END IF; END;', 'DROP TRIGGER F0P_TRIGGER');
    FOR r IN (SELECT object_name, object_type, status FROM USER_OBJECTS
              WHERE object_name IN ('F0P_TABLA','F0P_SECUENCIA','F0P_VISTA',
                'F0P_SINONIMO','F0P_TIPO','F0P_PROCEDIMIENTO','F0P_FUNCION','F0P_TRIGGER')
              ORDER BY object_name) LOOP
        DBMS_OUTPUT.PUT_LINE(r.object_name || ' | ' || r.object_type || ' | ' || r.status);
        IF r.status <> 'VALID' THEN
            RAISE_APPLICATION_ERROR(-20992, 'Objeto auxiliar no valido: ' || r.object_name);
        END IF;
    END LOOP;
    limpiar;
    DBMS_OUTPUT.PUT_LINE('Privilegios correctos: 8 auxiliares VALID y eliminados.');
EXCEPTION
    WHEN OTHERS THEN
        -- Solo se limpian objetos creados por esta ejecución; se relanza el error exacto.
        FOR i IN REVERSE 1 .. v_n LOOP
            BEGIN
                EXECUTE IMMEDIATE v_drops(i);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Revisar limpieza auxiliar: ' || v_drops(i) || ' / ' || SQLERRM);
            END;
        END LOOP;
        RAISE;
END;
/

-- Debe devolver CERO filas tras una ejecución correcta.
SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN ('F0P_TABLA','F0P_SECUENCIA','F0P_VISTA',
    'F0P_SINONIMO','F0P_TIPO','F0P_PROCEDIMIENTO','F0P_FUNCION','F0P_TRIGGER')
ORDER BY object_name;
