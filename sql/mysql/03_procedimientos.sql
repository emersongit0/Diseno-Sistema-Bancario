DELIMITER $$
-- @OBJETO: SP_LOG_ERROR
CREATE PROCEDURE SP_LOG_ERROR(IN p_proc VARCHAR(128),IN p_codigo INT,IN p_mensaje TEXT)
BEGIN
 INSERT INTO TBL_LOG_ERRORES(PROCEDIMIENTO,CODIGO,MENSAJE) VALUES(LEFT(p_proc,128),p_codigo,LEFT(p_mensaje,4000));
END$$
-- @FIN
-- @OBJETO: SP_ABRIR_CUENTA
CREATE PROCEDURE SP_ABRIR_CUENTA(IN p_id_cliente BIGINT,IN p_tipo VARCHAR(9),IN p_saldo_inicial DECIMAL(14,2),IN p_tasa DECIMAL(5,2),OUT p_id_cuenta BIGINT,OUT p_nro_cuenta VARCHAR(12),OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;

 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_abrir_cuenta; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_abrir_cuenta;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET p_id_cuenta=NULL,p_nro_cuenta=NULL;
 IF p_saldo_inicial IS NULL OR p_saldo_inicial<0 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Saldo inicial inválido.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM TBL_CLIENTES WHERE ID_CLIENTE=p_id_cliente) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20006,MESSAGE_TEXT='Cliente inexistente.'; END IF;
 IF p_tipo IS NULL OR p_tipo NOT IN ('AHORROS','CORRIENTE') THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Tipo de cuenta inválido.'; END IF;
 INSERT INTO TBL_CUENTAS(ID_CUENTA,NRO_CUENTA,ID_CLIENTE,TIPO,TASA_INTERES_ANUAL)
 VALUES(0,'',p_id_cliente,p_tipo,COALESCE(p_tasa,IF(p_tipo='AHORROS',3.00,0.50)));
 SELECT VALOR INTO p_id_cuenta FROM TBL_SECUENCIAS WHERE NOMBRE='SQ_CUENTA';
 SELECT NRO_CUENTA INTO p_nro_cuenta FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta;
 IF p_saldo_inicial>0 THEN
 INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION) VALUES(p_id_cuenta,'DEPOSITO',p_saldo_inicial,0,'Depósito de apertura'); END IF;
 SET p_mensaje=CONCAT('Cuenta abierta: ',p_nro_cuenta);
END$$
-- @FIN

-- @OBJETO: SP_DEPOSITAR
CREATE PROCEDURE SP_DEPOSITAR(IN p_id_cuenta BIGINT,IN p_monto DECIMAL(14,2),OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_saldo DECIMAL(14,2); DECLARE v_estado VARCHAR(9);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_depositar; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_depositar;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 IF p_monto IS NULL OR p_monto<=0 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Monto inválido.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20002,MESSAGE_TEXT='Cuenta inexistente.'; END IF;
 SELECT SALDO,ESTADO INTO v_saldo,v_estado FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta FOR UPDATE;
 IF v_estado<>'ACTIVA' THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20003,MESSAGE_TEXT='Cuenta bloqueada.'; END IF;
 INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION) VALUES(p_id_cuenta,'DEPOSITO',p_monto,0,'Depósito por procedimiento');
END$$
-- @FIN

-- @OBJETO: SP_RETIRAR
CREATE PROCEDURE SP_RETIRAR(IN p_id_cuenta BIGINT,IN p_monto DECIMAL(14,2),OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_saldo DECIMAL(14,2); DECLARE v_estado VARCHAR(9);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_retirar; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_retirar;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 IF p_monto IS NULL OR p_monto<=0 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Monto inválido.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20002,MESSAGE_TEXT='Cuenta inexistente.'; END IF;
 SELECT SALDO,ESTADO INTO v_saldo,v_estado FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta FOR UPDATE;
 IF v_estado<>'ACTIVA' THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20003,MESSAGE_TEXT='Cuenta bloqueada.'; END IF;
 IF v_saldo<p_monto THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20001,MESSAGE_TEXT='Saldo insuficiente.'; END IF;
INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION) VALUES(p_id_cuenta,'RETIRO',p_monto,0,'Retiro por procedimiento');
END$$
-- @FIN

-- @OBJETO: SP_TRANSFERIR
CREATE PROCEDURE SP_TRANSFERIR(IN p_origen BIGINT,IN p_destino BIGINT,IN p_monto DECIMAL(14,2),OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_saldo DECIMAL(14,2); DECLARE v_estado VARCHAR(9); DECLARE v_destino VARCHAR(9);
 DECLARE v_categoria VARCHAR(7); DECLARE v_comision DECIMAL(14,2); DECLARE v_bloqueo BIGINT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_transferir; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_transferir;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 IF p_monto IS NULL OR p_monto<=0 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Monto inválido.'; END IF;
 IF p_origen=p_destino THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20005,MESSAGE_TEXT='No se puede transferir a la misma cuenta.'; END IF;
 IF (SELECT COUNT(*) FROM TBL_CUENTAS WHERE ID_CUENTA IN (p_origen,p_destino))<>2 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20002,MESSAGE_TEXT='Cuenta inexistente.'; END IF;
 SELECT ID_CUENTA INTO v_bloqueo FROM TBL_CUENTAS WHERE ID_CUENTA=LEAST(p_origen,p_destino) FOR UPDATE;
 SELECT ID_CUENTA INTO v_bloqueo FROM TBL_CUENTAS WHERE ID_CUENTA=GREATEST(p_origen,p_destino) FOR UPDATE;
 SELECT SALDO,ESTADO INTO v_saldo,v_estado FROM TBL_CUENTAS WHERE ID_CUENTA=p_origen FOR UPDATE;
 SELECT ESTADO INTO v_destino FROM TBL_CUENTAS WHERE ID_CUENTA=p_destino FOR UPDATE;
 IF v_estado<>'ACTIVA' OR v_destino<>'ACTIVA' THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20003,MESSAGE_TEXT='Cuenta bloqueada.'; END IF;
 SELECT cli.CATEGORIA INTO v_categoria FROM TBL_CLIENTES cli JOIN TBL_CUENTAS c ON c.ID_CLIENTE=cli.ID_CLIENTE WHERE c.ID_CUENTA=p_origen FOR UPDATE;
 SET v_comision=FN_COMISION(p_monto,v_categoria);
 IF v_saldo<p_monto+v_comision THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20001,MESSAGE_TEXT='Saldo insuficiente para monto más comisión.'; END IF;
 INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION,ID_CUENTA_RELACIONADA)
 VALUES(p_origen,'TRANSF_ENVIADA',p_monto,0,'Transferencia enviada',p_destino);
 INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION,ID_CUENTA_RELACIONADA)
 VALUES(p_origen,'COMISION',v_comision,0,'Comisión de transferencia',p_destino);
 INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION,ID_CUENTA_RELACIONADA)
 VALUES(p_destino,'TRANSF_RECIBIDA',p_monto,0,'Transferencia recibida',p_origen);
 SET p_mensaje=CONCAT('Transferencia completada. Comisión: S/ ',v_comision);
END$$
-- @FIN

-- @OBJETO: SP_CAMBIAR_ESTADO_CUENTA
CREATE PROCEDURE SP_CAMBIAR_ESTADO_CUENTA(IN p_id_cuenta BIGINT,IN p_nuevo_estado VARCHAR(9),OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_estado VARCHAR(9);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_cambiar_estado_cuenta; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_cambiar_estado_cuenta;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 IF NOT EXISTS(SELECT 1 FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20002,MESSAGE_TEXT='Cuenta inexistente.'; END IF;
 SELECT ESTADO INTO v_estado FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta FOR UPDATE;
 IF p_nuevo_estado IS NULL OR p_nuevo_estado NOT IN ('ACTIVA','BLOQUEADA') THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20007,MESSAGE_TEXT='Estado de cuenta inválido.'; END IF;
 UPDATE TBL_CUENTAS SET ESTADO=p_nuevo_estado WHERE ID_CUENTA=p_id_cuenta;
 SET p_mensaje=CONCAT('Estado de cuenta: ',p_nuevo_estado);
END$$
-- @FIN

-- @OBJETO: SP_APLICAR_INTERESES
CREATE PROCEDURE SP_APLICAR_INTERESES(IN p_mes_ref DATE,OUT p_n_cuentas INT,OUT p_n_omitidas INT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_fin BOOL DEFAULT FALSE; DECLARE v_id BIGINT; DECLARE v_saldo DECIMAL(14,2); DECLARE v_tasa DECIMAL(5,2);
 DECLARE v_ultimo DATE; DECLARE v_mes DATE; DECLARE v_interes DECIMAL(14,2); DECLARE v_activas INT DEFAULT 0;
 DECLARE c_cuentas CURSOR FOR SELECT ID_CUENTA,SALDO,TASA_INTERES_ANUAL,FECHA_ULT_INTERES FROM TBL_CUENTAS WHERE ESTADO='ACTIVA' ORDER BY ID_CUENTA FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=TRUE;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_aplicar_intereses; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_aplicar_intereses;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET v_mes=CAST(DATE_FORMAT(COALESCE(p_mes_ref,CURRENT_DATE),'%Y-%m-01') AS DATE),p_n_cuentas=0,p_n_omitidas=0;
 OPEN c_cuentas;
 cuentas: LOOP
 FETCH c_cuentas INTO v_id,v_saldo,v_tasa,v_ultimo;
 IF v_fin THEN LEAVE cuentas; END IF;
 SET v_activas=v_activas+1;
 IF v_saldo>0 AND v_tasa>0 AND (v_ultimo IS NULL OR v_ultimo<v_mes) THEN
  SET v_interes=ROUND(v_saldo*v_tasa/100/12,2);
  IF v_interes>0 THEN
   INSERT INTO TBL_MOVIMIENTOS(ID_CUENTA,TIPO,MONTO,SALDO_POSTERIOR,DESCRIPCION)
   VALUES(v_id,'INTERES',v_interes,0,CONCAT('Interés del mes ',DATE_FORMAT(v_mes,'%Y-%m')));
   UPDATE TBL_CUENTAS SET FECHA_ULT_INTERES=v_mes WHERE ID_CUENTA=v_id;
   SET p_n_cuentas=p_n_cuentas+ROW_COUNT();
  END IF;
 END IF;
 END LOOP;
 CLOSE c_cuentas;
 SET p_n_omitidas=v_activas-p_n_cuentas,p_mensaje=CONCAT('Se actualizaron ',p_n_cuentas,' cuentas (',p_n_omitidas,' omitidas)');
END$$
-- @FIN

-- @OBJETO: SP_ACTUALIZAR_CATEGORIAS
CREATE PROCEDURE SP_ACTUALIZAR_CATEGORIAS(OUT p_n_procesados INT,OUT p_n_cambios INT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_fin BOOL DEFAULT FALSE; DECLARE v_id BIGINT; DECLARE v_anterior VARCHAR(7); DECLARE v_nueva VARCHAR(7);
 DECLARE v_saldo DECIMAL(24,2); DECLARE v_version BIGINT;
 DECLARE c_clientes CURSOR FOR SELECT ID_CLIENTE,CATEGORIA FROM TBL_CLIENTES ORDER BY ID_CLIENTE FOR UPDATE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=TRUE;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_actualizar_categorias; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_actualizar_categorias;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SELECT VERSION INTO v_version FROM TBL_LIMITES_CATEGORIAS WHERE ID_CONFIG=1 FOR UPDATE;
 SET p_n_procesados=0,p_n_cambios=0;
 OPEN c_clientes;
 clientes: LOOP
 FETCH c_clientes INTO v_id,v_anterior;
 IF v_fin THEN LEAVE clientes; END IF;
 SET p_n_procesados=p_n_procesados+1;
 SELECT COALESCE(SUM(SALDO),0) INTO v_saldo FROM TBL_CUENTAS WHERE ID_CLIENTE=v_id;
 SET v_nueva=FN_CATEGORIA_CLIENTE(v_saldo);
 IF v_nueva<>v_anterior THEN UPDATE TBL_CLIENTES SET CATEGORIA=v_nueva WHERE ID_CLIENTE=v_id; SET p_n_cambios=p_n_cambios+1; END IF;
 END LOOP;
 CLOSE c_clientes;
 SET p_mensaje=CONCAT('Clientes procesados: ',p_n_procesados,'; cambios: ',p_n_cambios);
END$$
-- @FIN

-- @OBJETO: SP_RESUMEN_CLIENTE
CREATE PROCEDURE SP_RESUMEN_CLIENTE(IN p_id_cliente BIGINT,OUT p_json LONGTEXT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_nombre VARCHAR(201); DECLARE v_categoria VARCHAR(7); DECLARE v_nivel VARCHAR(7);
 DECLARE v_saldo DECIMAL(24,2); DECLARE v_gold DECIMAL(14,2); DECLARE v_premium DECIMAL(14,2); DECLARE v_falta DECIMAL(24,2); DECLARE v_siguiente VARCHAR(7);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_resumen_cliente; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_resumen_cliente;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET p_json=NULL;
 IF NOT EXISTS(SELECT 1 FROM TBL_CLIENTES WHERE ID_CLIENTE=p_id_cliente) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20006,MESSAGE_TEXT='Cliente inexistente.'; END IF;
 SELECT CONCAT(NOMBRES,' ',APELLIDOS),CATEGORIA INTO v_nombre,v_categoria FROM TBL_CLIENTES WHERE ID_CLIENTE=p_id_cliente;
 SELECT COALESCE(SUM(SALDO),0) INTO v_saldo FROM TBL_CUENTAS WHERE ID_CLIENTE=p_id_cliente;
 SELECT LIMITE_GOLD,LIMITE_PREMIUM INTO v_gold,v_premium FROM TBL_LIMITES_CATEGORIAS WHERE ID_CONFIG=1;
 IF v_saldo<v_gold THEN SET v_nivel='BASICO',v_siguiente='GOLD',v_falta=v_gold-v_saldo;
 ELSEIF v_saldo<v_premium THEN SET v_nivel='GOLD',v_siguiente='PREMIUM',v_falta=v_premium-v_saldo;
 ELSE SET v_nivel='PREMIUM',v_siguiente=NULL,v_falta=0; END IF;
 SET p_json=JSON_OBJECT('id_cliente',p_id_cliente,'nombre',v_nombre,'categoria_registrada',v_categoria,'nivel',v_nivel,'saldo_total',v_saldo,'siguiente_categoria',v_siguiente,'falta_para_siguiente',v_falta),p_mensaje='Resumen generado.';
END$$
-- @FIN

-- @OBJETO: SP_SIMULADOR_INTERES
CREATE PROCEDURE SP_SIMULADOR_INTERES(IN p_saldo_inicial DECIMAL(14,2),IN p_tasa_anual DECIMAL(5,2),IN p_meses INT,IN p_aporte_mensual DECIMAL(14,2),IN p_meta DECIMAL(14,2),IN p_id_cuenta BIGINT,OUT p_saldo_final DECIMAL(40,2),OUT p_meses_meta INT,OUT p_proyeccion LONGTEXT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_inicial DECIMAL(40,2); DECLARE v_tasa DECIMAL(5,2); DECLARE v_saldo DECIMAL(40,2); DECLARE v_meta DECIMAL(40,2); DECLARE v_i INT DEFAULT 0; DECLARE v_mes INT DEFAULT 0; DECLARE v_json JSON;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_simulador_interes; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_simulador_interes;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET p_saldo_final=NULL,p_meses_meta=NULL,p_proyeccion=NULL;
 IF p_id_cuenta IS NOT NULL THEN
  IF NOT EXISTS(SELECT 1 FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20002,MESSAGE_TEXT='Cuenta inexistente.'; END IF;
  SELECT SALDO,COALESCE(TASA_INTERES_ANUAL,0) INTO v_inicial,v_tasa FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta;
 ELSE SET v_inicial=p_saldo_inicial,v_tasa=p_tasa_anual; END IF;
 IF v_inicial IS NULL OR v_inicial<0 OR v_tasa IS NULL OR v_tasa<0 OR p_meses IS NULL OR p_meses<0 OR p_meses>600 OR p_aporte_mensual IS NULL OR p_aporte_mensual<0 OR p_meta IS NULL OR p_meta<=0 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Datos de simulación inválidos.'; END IF;
 SET v_saldo=v_inicial,v_json=JSON_ARRAY(JSON_OBJECT('mes',0,'saldo',v_saldo)),v_i=1;
 WHILE v_i<=p_meses DO
  SET v_saldo=ROUND(v_saldo*(1+v_tasa/100/12)+p_aporte_mensual,2);
  SET v_json=JSON_ARRAY_APPEND(v_json,'$',JSON_OBJECT('mes',v_i,'saldo',v_saldo)),v_i=v_i+1;
 END WHILE;
 SET v_meta=v_inicial;
 WHILE v_meta<p_meta AND v_mes<600 DO
  SET v_meta=ROUND(v_meta*(1+v_tasa/100/12)+p_aporte_mensual,2),v_mes=v_mes+1;
 END WHILE;
 IF v_meta>=p_meta THEN SET p_meses_meta=v_mes;
 ELSE SET p_mensaje='La meta no se alcanza en el límite de 600 meses.'; END IF;
 SET p_saldo_final=v_saldo,p_proyeccion=CAST(v_json AS CHAR);

END$$
-- @FIN

-- @OBJETO: SP_ESTADO_CUENTA_MENSUAL
CREATE PROCEDURE SP_ESTADO_CUENTA_MENSUAL(IN p_id_cuenta BIGINT,IN p_anio INT,IN p_mes INT,OUT p_json LONGTEXT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_fin BOOL DEFAULT FALSE; DECLARE v_inicio DATE; DECLARE v_hasta DATE;
 DECLARE v_fecha DATETIME(6); DECLARE v_tipo VARCHAR(15); DECLARE v_desc VARCHAR(500); DECLARE v_monto DECIMAL(14,2); DECLARE v_saldo DECIMAL(24,2); DECLARE v_json JSON;
 DECLARE c_mov CURSOR FOR SELECT FECHA,TIPO,DESCRIPCION,MONTO FROM TBL_MOVIMIENTOS WHERE ID_CUENTA=p_id_cuenta AND FECHA>=v_inicio AND FECHA<v_hasta ORDER BY FECHA,ID_MOVIMIENTO;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=TRUE;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_estado_cuenta_mensual; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_estado_cuenta_mensual;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET p_json=NULL;
 IF p_anio IS NULL OR p_anio<1000 OR p_anio>9998 OR p_mes IS NULL OR p_mes<1 OR p_mes>12 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Año o mes inválido; año entre 1000 y 9998.'; END IF;
 IF NOT EXISTS(SELECT 1 FROM TBL_CUENTAS WHERE ID_CUENTA=p_id_cuenta) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20002,MESSAGE_TEXT='Cuenta inexistente.'; END IF;
 SET v_inicio=STR_TO_DATE(CONCAT(p_anio,'-',LPAD(p_mes,2,'0'),'-01'),'%Y-%m-%d'),v_hasta=DATE_ADD(v_inicio,INTERVAL 1 MONTH),v_json=JSON_ARRAY();
 SELECT COALESCE(SUM(CASE WHEN TIPO IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN MONTO ELSE -MONTO END),0) INTO v_saldo FROM TBL_MOVIMIENTOS WHERE ID_CUENTA=p_id_cuenta AND FECHA<v_inicio;
 OPEN c_mov;
 movimientos: LOOP
  FETCH c_mov INTO v_fecha,v_tipo,v_desc,v_monto;
  IF v_fin THEN LEAVE movimientos; END IF;
  IF v_tipo IN ('DEPOSITO','TRANSF_RECIBIDA','INTERES') THEN SET v_saldo=v_saldo+v_monto; ELSE SET v_saldo=v_saldo-v_monto; END IF;
  SET v_json=JSON_ARRAY_APPEND(v_json,'$',JSON_OBJECT('fecha',DATE_FORMAT(v_fecha,'%Y-%m-%dT%H:%i:%s.%f'),'tipo',v_tipo,'descripcion',v_desc,'monto',v_monto,'saldo_acumulado',v_saldo));
 END LOOP;
 CLOSE c_mov;
 SET p_json=CAST(v_json AS CHAR),p_mensaje='Estado mensual generado.';
END$$
-- @FIN

-- @OBJETO: SP_REPORTE_CLIENTES
CREATE PROCEDURE SP_REPORTE_CLIENTES(IN p_id_cliente BIGINT,IN p_limite_movs INT,OUT p_json LONGTEXT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_fin BOOL DEFAULT FALSE; DECLARE v_id BIGINT; DECLARE v_nombre VARCHAR(201); DECLARE v_categoria VARCHAR(7); DECLARE v_clientes JSON; DECLARE v_cuentas JSON;
 DECLARE c_cli CURSOR FOR SELECT ID_CLIENTE,CONCAT(NOMBRES,' ',APELLIDOS),CATEGORIA FROM TBL_CLIENTES WHERE p_id_cliente IS NULL OR ID_CLIENTE=p_id_cliente ORDER BY ID_CLIENTE;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin=TRUE;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_reporte_clientes; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_reporte_clientes;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET p_json=NULL,v_clientes=JSON_ARRAY();
 IF p_limite_movs IS NULL OR p_limite_movs<0 OR p_limite_movs>1000 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Límite inválido.'; END IF;
 IF p_id_cliente IS NOT NULL AND NOT EXISTS(SELECT 1 FROM TBL_CLIENTES WHERE ID_CLIENTE=p_id_cliente) THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20006,MESSAGE_TEXT='Cliente inexistente.'; END IF;
 OPEN c_cli;
 clientes: LOOP
  FETCH c_cli INTO v_id,v_nombre,v_categoria;
  IF v_fin THEN LEAVE clientes; END IF;
  SET v_cuentas=JSON_ARRAY();
  BEGIN
   DECLARE fin_cta BOOL DEFAULT FALSE; DECLARE v_cta BIGINT; DECLARE v_nro VARCHAR(12); DECLARE v_saldo DECIMAL(14,2); DECLARE v_estado VARCHAR(9); DECLARE v_movs JSON;
   DECLARE c_cta CURSOR FOR SELECT ID_CUENTA,NRO_CUENTA,SALDO,ESTADO FROM TBL_CUENTAS WHERE ID_CLIENTE=v_id ORDER BY ID_CUENTA;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_cta=TRUE;
   OPEN c_cta;
   cuentas: LOOP
    FETCH c_cta INTO v_cta,v_nro,v_saldo,v_estado;
    IF fin_cta THEN LEAVE cuentas; END IF;
    SET v_movs=JSON_ARRAY();
    BEGIN
     DECLARE fin_mov BOOL DEFAULT FALSE; DECLARE v_mov BIGINT; DECLARE v_tipo VARCHAR(15); DECLARE v_monto DECIMAL(14,2); DECLARE v_fecha DATETIME(6); DECLARE v_desc VARCHAR(500);
     DECLARE c_mov CURSOR FOR SELECT ID_MOVIMIENTO,TIPO,MONTO,FECHA,DESCRIPCION FROM TBL_MOVIMIENTOS WHERE ID_CUENTA=v_cta ORDER BY FECHA DESC,ID_MOVIMIENTO DESC LIMIT p_limite_movs;
     DECLARE CONTINUE HANDLER FOR NOT FOUND SET fin_mov=TRUE;
     OPEN c_mov;
     movimientos: LOOP
      FETCH c_mov INTO v_mov,v_tipo,v_monto,v_fecha,v_desc;
      IF fin_mov THEN LEAVE movimientos; END IF;
      SET v_movs=JSON_ARRAY_APPEND(v_movs,'$',JSON_OBJECT('id_movimiento',v_mov,'tipo',v_tipo,'monto',v_monto,'fecha',DATE_FORMAT(v_fecha,'%Y-%m-%dT%H:%i:%s.%f'),'descripcion',v_desc));
     END LOOP;
     CLOSE c_mov;
    END;
    SET v_cuentas=JSON_ARRAY_APPEND(v_cuentas,'$',JSON_OBJECT('id_cuenta',v_cta,'nro_cuenta',v_nro,'saldo',v_saldo,'estado',v_estado,'movimientos',JSON_EXTRACT(v_movs,'$')));
   END LOOP;
   CLOSE c_cta;
  END;
  SET v_clientes=JSON_ARRAY_APPEND(v_clientes,'$',JSON_OBJECT('id_cliente',v_id,'nombre',v_nombre,'categoria',v_categoria,'cuentas',JSON_EXTRACT(v_cuentas,'$')));
 END LOOP;
 CLOSE c_cli;
 SET p_json=CAST(v_clientes AS CHAR),p_mensaje='Reporte generado.';
END$$
-- @FIN

-- @OBJETO: SP_LAB_ERRORES
CREATE PROCEDURE SP_LAB_ERRORES(IN p_caso VARCHAR(30),OUT p_detalle LONGTEXT,OUT p_estado VARCHAR(10),OUT p_codigo INT,OUT p_mensaje TEXT)
BEGIN
 DECLARE v_errno INT DEFAULT 0;
 DECLARE v_error TEXT;
 DECLARE v_codigo INT DEFAULT 0; DECLARE v_num INT; DECLARE v_corto VARCHAR(1); DECLARE v_dni VARCHAR(8);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  GET DIAGNOSTICS CONDITION 1 v_errno=MYSQL_ERRNO,v_error=MESSAGE_TEXT;
  IF v_errno<>1213 THEN ROLLBACK TO SAVEPOINT sv_lab_errores; END IF;
  SET p_estado='ERROR',p_codigo=CASE v_errno WHEN 1213 THEN -60 WHEN 1205 THEN -30006 ELSE -v_errno END,p_mensaje=v_error;
 END;
 SAVEPOINT sv_lab_errores;
 SET p_estado='OK',p_codigo=0,p_mensaje='Operación completada.';
 SET p_detalle=NULL;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION,SQLWARNING,NOT FOUND
  BEGIN GET DIAGNOSTICS CONDITION 1 v_codigo=MYSQL_ERRNO,v_error=MESSAGE_TEXT; END;
  CASE UPPER(p_caso)
   WHEN 'NO_DATA_FOUND' THEN SELECT ID_CLIENTE INTO v_num FROM TBL_CLIENTES WHERE ID_CLIENTE=-1;
   WHEN 'TOO_MANY_ROWS' THEN SELECT n INTO v_num FROM (SELECT 1 n UNION ALL SELECT 2 n) t;
   WHEN 'ZERO_DIVIDE' THEN SET v_num=1/0;
   WHEN 'VALUE_ERROR' THEN SET v_corto='texto demasiado largo';
   WHEN 'WHEN_OTHERS' THEN SET v_num=CAST('abc' AS SIGNED);
   WHEN 'DUP_VAL_ON_INDEX' THEN
    SELECT MIN(DNI) INTO v_dni FROM TBL_CLIENTES;
    IF v_dni IS NULL THEN INSERT INTO TBL_CLIENTES(DNI,NOMBRES,APELLIDOS,EMAIL) VALUES('99999999','LAB','TEMPORAL','lab@example.invalid'); SET v_dni='99999999'; END IF;
    INSERT INTO TBL_CLIENTES(DNI,NOMBRES,APELLIDOS,EMAIL) VALUES(v_dni,'LAB','DUPLICADO','lab-duplicado@example.invalid');
   WHEN 'RERAISE' THEN
    BEGIN
     DECLARE EXIT HANDLER FOR SQLEXCEPTION RESIGNAL;
     SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Excepción capturada y relanzada con RESIGNAL.';
    END;
   ELSE SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='Caso de laboratorio inválido.';
  END CASE;
 END;
 IF v_codigo=0 THEN SIGNAL SQLSTATE '45000' SET MYSQL_ERRNO=20004,MESSAGE_TEXT='No se produjo la excepción esperada.'; END IF;
 ROLLBACK TO SAVEPOINT sv_lab_errores;
 SET p_detalle=CONCAT('MYSQL_ERRNO=',-v_codigo,'; MESSAGE_TEXT=',v_error),p_mensaje='Excepción esperada capturada.';
END$$
-- @FIN

DELIMITER ;
