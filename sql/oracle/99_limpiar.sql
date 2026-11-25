-- RECREACIÓN ÚNICAMENTE: elimina los 40 objetos de B2.2 y sus datos.
-- NO ejecutar durante la instalación normal de Fase 3.
-- Ejecutar solo para rehacer el proyecto desde 01; los bloques son archivos.
-- DDL confirma transacciones: esta limpieza no se puede deshacer con ROLLBACK.
-- No usa USER_OBJECTS para descubrir ni borrar objetos ajenos.
DECLARE
    PROCEDURE eliminar(p_sentencia VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sentencia;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE NOT IN (-942,-2289,-4043,-1432,-4080) THEN
                RAISE;
            END IF;
    END;
BEGIN
    -- SYNONYM
    eliminar('DROP SYNONYM CLIENTES');
    eliminar('DROP SYNONYM CUENTAS');
    eliminar('DROP SYNONYM MOVIMIENTOS');
    eliminar('DROP SYNONYM AUDITORIA');
    eliminar('DROP SYNONYM LIMITES_CATEGORIAS');
    eliminar('DROP SYNONYM LOG_ERRORES');
    -- TRIGGER
    eliminar('DROP TRIGGER TRG_CUENTAS_AU');
    eliminar('DROP TRIGGER TRG_MOVIMIENTOS_AI');
    eliminar('DROP TRIGGER TRG_MOVIMIENTOS_BI');
    eliminar('DROP TRIGGER TRG_CUENTAS_BI');
    eliminar('DROP TRIGGER TRG_CLIENTES_BI');
    -- PROCEDURE
    eliminar('DROP PROCEDURE SP_LAB_ERRORES');
    eliminar('DROP PROCEDURE SP_REPORTE_CLIENTES');
    eliminar('DROP PROCEDURE SP_ACTUALIZAR_CATEGORIAS');
    eliminar('DROP PROCEDURE SP_APLICAR_INTERESES');
    eliminar('DROP PROCEDURE SP_CAMBIAR_ESTADO_CUENTA');
    eliminar('DROP PROCEDURE SP_TRANSFERIR');
    eliminar('DROP PROCEDURE SP_RETIRAR');
    eliminar('DROP PROCEDURE SP_DEPOSITAR');
    eliminar('DROP PROCEDURE SP_ABRIR_CUENTA');
    eliminar('DROP PROCEDURE SP_LOG_ERROR');
    -- FUNCTION
    eliminar('DROP FUNCTION FN_ESTADO_CUENTA_MENSUAL');
    eliminar('DROP FUNCTION FN_COMISION');
    eliminar('DROP FUNCTION FN_CATEGORIA_CLIENTE');
    eliminar('DROP FUNCTION FN_SALDO_DISPONIBLE');
    -- VIEW
    eliminar('DROP VIEW V_CUENTAS_RESUMEN');
    eliminar('DROP VIEW V_ESTADO_CUENTA');
    -- TABLE
    eliminar('DROP TABLE TBL_MOVIMIENTOS PURGE');
    eliminar('DROP TABLE TBL_CUENTAS PURGE');
    eliminar('DROP TABLE TBL_CLIENTES PURGE');
    eliminar('DROP TABLE TBL_AUDITORIA PURGE');
    eliminar('DROP TABLE TBL_LIMITES_CATEGORIAS PURGE');
    eliminar('DROP TABLE TBL_LOG_ERRORES PURGE');
    -- TYPE
    eliminar('DROP TYPE T_MOV_TABLA');
    eliminar('DROP TYPE T_MOV_FILA');
    -- SEQUENCE
    eliminar('DROP SEQUENCE SQ_LOG');
    eliminar('DROP SEQUENCE SQ_AUDITORIA');
    eliminar('DROP SEQUENCE SQ_MOVIMIENTO');
    eliminar('DROP SEQUENCE SQ_CUENTA');
    eliminar('DROP SEQUENCE SQ_CLIENTE');
    DBMS_OUTPUT.PUT_LINE('Limpieza limitada a B2.2 completada.');
END;
/
