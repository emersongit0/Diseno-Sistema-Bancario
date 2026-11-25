-- Fase 1. Ejecutar una sola vez después de 02_secuencias.sql.
-- Las longitudes y precisiones coinciden con el libro de movimientos.

-- @OBJETO: T_MOV_FILA
CREATE TYPE T_MOV_FILA AS OBJECT (
    FECHA TIMESTAMP,
    TIPO VARCHAR2(15),
    DESCRIPCION VARCHAR2(500 CHAR),
    MONTO NUMBER(14,2),
    SALDO_ACUMULADO NUMBER(14,2)
);
/
-- @FIN

-- @OBJETO: T_MOV_TABLA
CREATE TYPE T_MOV_TABLA AS TABLE OF T_MOV_FILA;
/
-- @FIN
