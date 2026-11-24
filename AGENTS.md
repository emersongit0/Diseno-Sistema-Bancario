# Banco Oracle: instrucciones del proyecto

Fuente de verdad: leer docs/ESPECIFICACION.md completa; al iniciar cada fase releer las secciones B aplicables y la matriz. No modificar la especificación sin permiso.

## Stack y convenciones
Python 3.11+, Flask, python-oracledb THIN, python-dotenv, pytest; Oracle FreeSQL; Jinja2, Tailwind CDN y JavaScript ES. PowerShell en Windows; moneda S/.
Nombres en español, type hints y docstrings breves; logging sin credenciales. SQL solo en repositories y archivos SQL. Aplicación usa sinónimos para tablas. Binds obligatorios; transacciones en servicios; call_timeout=15000, ping_interval=60 en el futuro pool. Escrituras nunca se reintentan; lecturas una vez. Marcadores -- @OBJETO: NOMBRE y -- @FIN para cada entrada de B2.2. FOR UPDATE WAIT 5; procedimientos sin COMMIT salvo utilidad autónoma SP_LOG_ERROR.

## Seguridad
- Nunca leer, mostrar, copiar ni versionar .env, ni pedir contraseñas. El usuario lo crea desde .env.example.
- .claude/settings.json deniega Read(./.env) y Read(**/.env). Si el agente no es Claude Code, el usuario debe configurar la protección equivalente en su herramienta; este agente debe respetar igualmente la prohibición de lectura.
- Nunca ejecutar run.py, probar_conexion.py o SQL contra Oracle: los ejecuta el usuario. Fase 7 solo con solicitud explícita.
- pytest siempre sin BD: conftest.py bloquea conexiones y pools síncronos/asíncronos.
- Nunca leer, modificar ni borrar tablas AD_. Solo consultar sus nombres y cantidad en USER_TABLES mediante sql/00b_snapshot_ad.sql.
- No ejecutar limpieza amplia ni crear usuarios, conceder privilegios o usar prefijos de esquema. Ante falta de privilegios detenerse; contingencias solo aprobadas por el usuario.
- Nunca hacer push sin solicitud. Antes de cada commit revisar git status y comprobar que .env no aparece; commit por fase solo con permiso del usuario.

## Lista cerrada B2.2
- Tablas: TBL_CLIENTES, TBL_CUENTAS, TBL_MOVIMIENTOS, TBL_AUDITORIA, TBL_LOG_ERRORES.
- Secuencias: SQ_CLIENTE, SQ_CUENTA, SQ_MOVIMIENTO, SQ_AUDITORIA, SQ_LOG.
- Tipos: T_MOV_FILA, T_MOV_TABLA.
- Vistas: V_ESTADO_CUENTA, V_CUENTAS_RESUMEN.
- Funciones: FN_SALDO_DISPONIBLE, FN_CATEGORIA_CLIENTE, FN_COMISION, FN_ESTADO_CUENTA_MENSUAL.
- Procedimientos: SP_LOG_ERROR, SP_ABRIR_CUENTA, SP_DEPOSITAR, SP_RETIRAR, SP_TRANSFERIR, SP_CAMBIAR_ESTADO_CUENTA, SP_APLICAR_INTERESES, SP_ACTUALIZAR_CATEGORIAS, SP_REPORTE_CLIENTES, SP_LAB_ERRORES.
- Triggers: TRG_CLIENTES_BI, TRG_CUENTAS_BI, TRG_MOVIMIENTOS_BI, TRG_MOVIMIENTOS_AI, TRG_CUENTAS_AU.
- Sinónimos: CLIENTES, CUENTAS, MOVIMIENTOS, AUDITORIA, LOG_ERRORES.
- Bloques anónimos: BLOQUE_SIMULADOR_INTERES, BLOQUE_RESUMEN_CLIENTE.

Son 38 objetos de BD y 2 bloques. Los auxiliares F0P_* del script 00 son pruebas transitorias de privilegios y se eliminan en el propio script; no pertenecen al índice de producción. No añadir objetos de producción sin actualizar especificación con permiso, matriz y esta lista.

## Fases y palabras de paso
Detenerse al entregar cada fase. Solo «continúa» autoriza la siguiente y confirma las pruebas anteriores. Excepción Fase 0: esperar específicamente «privilegios OK». Si el usuario pega un error, corregirlo sin avanzar.
Matriz: Pendiente → Creado al escribir el SQL correspondiente → Verificado únicamente tras confirmación del usuario y para filas probadas. La prueba de Fase 0 no verifica objetos de producción; sus filas de preparación se verificaron con «privilegios OK».

- Fase 0: completada y confirmada por el usuario con «privilegios OK». Conexión manual, privilegios, ausencia de nombres B2.2 y snapshot inicial confirmados. pytest: 1 passed. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 1: completada y confirmada por el usuario con «continua». F1 ejecutada: 5 tablas, 5 secuencias y 2 tipos VALID, sin errores. Doce filas verificadas. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 2A: completada y confirmada por el usuario con «continua». Once objetos VALID y smoke F2A confirmado. Filas cubiertas verificadas; persistencia autónoma del log confirmada en F3. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 2B: completada. Usuario compartió salida F2B OK y confirmó con «continua». Corregida y validada la colisión de variables JSON/CLOB. Filas cubiertas verificadas; binds reales confirmados en Fase 4. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 3: completada y confirmada por el usuario con «continua», después de solicitar F3 OK y SNAPSHOTS OK. Carga 6/8/30 y tres categorías confirmadas. Filas correspondientes verificadas. Limpieza limitada revisada estáticamente, sin ejecutarla. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 4: completada y confirmada por el usuario con «continua»: salud, resumen de cliente y simulador con binds reales comprobados. Backend y 129 pruebas sin BD validados. Filas correspondientes verificadas. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 5: completada y confirmada por el usuario con «continua»: diez pantallas, una operación por pantalla y panel/modal de código reales. También consta QA en Chrome aislado con datos ficticios y 129 pruebas pytest correctas sin BD. Diez filas de frontend verificadas. Incluida en el commit local de cierre autorizado por el usuario.
- Fase 6: README creado con instalación, detalles de conexión, orden SQL, guion de puntos 1–16, respaldo y verificación final. Matriz completa en Verificado gracias a confirmaciones de fases 0 a 5. Comprobación local completada: 13 scripts y puntos 1–16 referenciados correctamente; 80 filas de matriz Verificado; snapshots guardados dan SNAPSHOTS OK; .env/.venv/work ignorados y git ls-files no lista .env. No se repitieron pruebas de código por cambios solo de documentación; última ejecución: 129 passed. Pendiente que el usuario vuelva a ejecutar 00b_snapshot_ad.sql, guarde la salida actual y obtenga SNAPSHOTS OK; Commit local de cierre autorizado por el usuario con «perfecto hagamos el commit local». No cerrada. No hacer push ni iniciar Fase 7.
- Fase 7: opcional, no solicitada.

## Decisiones de Fase 1
Longitudes no especificadas: nombres/apellidos 100 caracteres, email 254, descripción 500, mensaje de log 4000 bytes; identificadores NUMBER(10). NOT NULL explícitos con nombres CK_*_NN. Las FK y CHECK de dominio corresponden a B2.3: auditoría y log no tienen relaciones artificiales. Todas las secuencias auxiliares comienzan en 1, incrementan 1 y usan NOCACHE. No consumir NEXTVAL antes del smoke F1, que verifica los valores iniciales.

## Decisiones de Fase 2A
V_CUENTAS_RESUMEN suma todos los abonos en TOTAL_DEPOSITADO (depósito, transferencia recibida, interés) y todos los cargos en TOTAL_RETIRADO (retiro, transferencia enviada, comisión). FN_CATEGORIA_CLIENTE considera saldo nulo como cero; FN_COMISION usa BASICO para categoría nula o desconocida y rechaza monto nulo. El BEFORE de movimientos usa FOR UPDATE WAIT 5 también ante DML directo; los procedimientos futuros deben bloquear igualmente antes de insertar. La auditoría de estado registra solo cambios reales. F2A revierte sus datos y auditoría, pero consume valores de secuencias: ejecutar solo la sección F2A, sin repetir F1 ni 01 a 03.

## Decisiones de Fase 2B
Los nueve procedimientos terminan con p_estado, p_codigo y p_mensaje; los OUT propios usan p_id_cuenta/p_nro_cuenta, p_n_cuentas/p_n_omitidas, p_n_procesados/p_n_cambios, p_json o p_detalle. No hay COMMIT de negocio. Los savepoints tienen nombres distintos por procedimiento.
Interés redondeado a cero: la cuenta se omite sin marcar FECHA_ULT_INTERES; insertar cero violaría -20004 del trigger. El UPDATE masivo conserva el criterio de elegibilidad y limita IDs a quienes recibieron interés, mediante una lista JSON local y JSON_TABLE, sin tipos auxiliares ni prefijos de esquema. El reporte admite un límite entero de 0 a 1000 movimientos por cuenta. Estado mensual incluye saldo anterior al mes, ordena por fecha/ID y conserva monto positivo; el signo se refleja en saldo_acumulado.
Simulador: meses enteros 0..600, aporte al final del mes, redondeo mensual, JSON con mes cero, meta positiva; meses_meta puede ser cero o NULL si no se alcanza en 600 meses. Una cuenta opcional reemplaza saldo/tasa ingresados. Ambos bloques agregan p_codigo OUT para codificar errores de negocio.
Binds simulador: p_saldo_inicial, p_tasa_anual, p_meses, p_aporte_mensual, p_meta, p_id_cuenta; OUT p_saldo_final, p_meses_meta, p_proyeccion (CLOB), p_estado, p_codigo, p_mensaje. Binds resumen: p_id_cliente; OUT p_json (CLOB), p_estado, p_codigo, p_mensaje.
F2B incluye copias mecánicas de los cuerpos de ambos bloques, con sustitución de binds por variables/literales. Los binds reales se validan en Fase 4. Solo ejecutar sección F2B; el rollback conserva los registros autónomos generados por errores intencionales y el avance de secuencias.

## Corrección confirmada en F2B
El usuario reportó PLS-00382 en líneas 99 y 249 del bloque F2B: las copias mecánicas ocultaban los OUT CLOB con variables JSON locales homónimas. Se renombraron las variables internas a v_proyeccion_json y v_resumen_json en los bloques fuente y se regeneraron sus copias de smoke. No cambia la firma de binds ni los scripts 07/08. El usuario repitió F2B, compartió F2B OK y confirmó el avance: incidencia resuelta.

## Decisiones de Fase 3
La carga 10 se niega a duplicar datos si clientes/cuentas/movimientos no están vacíos. No depende de IDs iniciales; devuelve 6 clientes, 8 cuentas, exactamente 30 movimientos y dos clientes por categoría. Aperturas y operaciones únicamente mediante procedimientos; solo clientes se insertan directamente. COMMIT único al final; ante error ROLLBACK. Mantiene logs autónomos previos.
99_limpiar.sql es solo para recrear, no para la secuencia normal: 38 DROP literales en orden inverso de dependencias, sin descubrir objetos del usuario; ignora solo -942, -2289, -4043, -1432 y -4080. No se ejecuta por el agente ni se pide ejecutarlo para verificar F3.
F3 verifica los cinco sinónimos con SELECT, los saldos acumulados, tres movimientos y tres auditorías por transferencia, siete códigos propios y persistencia del log después del rollback. Los datos de demostración se conservan.
El comparador normaliza espacios/finales de línea sin leer BD, no inventa snapshots y rechaza archivos ausentes o vacíos. Salidas 0 idénticos, 1 diferentes, 2 ausentes/ilegibles/vacíos. El usuario guarda snapshot_ad_despues.txt con el mismo formato que snapshot_ad_antes.txt. Solo compara nombres y cantidad, nunca contenido de tablas AD_.

## Decisiones de Fase 4
El pool se inicializa de forma perezosa, por aplicación; crear/importar Flask no lee .env ni conecta. THIN por defecto, ping_interval=60, espera y call_timeout de 15000 ms, retry_count=0 del driver. Los servicios toman una conexión por operación/request con context manager; solo lecturas y simulador pueden adquirir una segunda conexión al reintentar una vez. Una escritura nunca se repite, ni siquiera si falla al adquirir conexión. Caída en ejecución/commit: mensaje de confirmación incierta; caída previa a ejecutar: mensaje de conexión.
Todos los endpoints devuelven {ok,mensaje,codigo,datos,objetos_oracle}. /api/codigo/<objeto> coloca {objeto,tipo,archivo,codigo} dentro de datos. OUT CLOB se consumen dentro del cursor. Los resultados del reporte y del resumen están en datos.json; simulador usa datos.saldo_final, datos.meses_meta y datos.proyeccion. Importes validados con Decimal, hasta dos decimales; JSON emite números y fechas ISO.
No se reproduce lógica financiera en Python. Validación solo de formatos, rangos y estructura. El laboratorio llama procedimientos reales con datos inválidos y siempre rollback; sus detalles técnicos ocultan el esquema, incluidos detalles Oracle extendidos. El listado de log muestra mensajes públicos mapeados; SQLERRM crudo solo se devuelve en laboratorio. Logs Python no imprimen credenciales, DSN ni excepciones completas.
La interfaz de Fase 4 es una página mínima de inicio. Las diez pantallas completas se implementan exclusivamente en Fase 5. pytest bloquea conexiones, pools síncronos/asíncronos y lectura dotenv; usa datos ficticios y mocks para errores, contratos API, transacciones, wallet/pool y binds. Los binds Oracle reales deben ser comprobados por el usuario antes de «continúa».

## Decisiones de Fase 5
Rutas HTML: /, /clientes, /cuentas, /operaciones, /estado-cuenta, /reporte, /intereses, /simulador, /auditoria y /laboratorio. Cada una tiene plantilla y módulo ES propios, base común, panel de objetos y modal PL/SQL. ui.js maneja tablas, diálogos, chips, toasts y formato de soles; api.js hace un fetch por llamada, sin reintentos de escrituras ni cálculos de negocio.
Los chips se acumulan desde objetos_oracle de las respuestas reales de la página; el modal también ofrece objetos declarados de la pantalla antes de ejecutar acciones. El código se muestra con textContent, nunca como HTML. Entradas de usuarios/Oracle se escapan al construir tablas. Selector de código y consultas de historial ignoran respuestas antiguas.
Operaciones muestra saldo actual y comisión de transferencia con debounce de 300 ms, cancelación y control de versión. Requiere cotización actual antes de enviar y bloquea doble envío mientras está pendiente. El procedimiento Oracle vuelve a calcular la comisión al confirmar; el navegador solo presenta valores. Ante pérdida de respuesta de una escritura se indica confirmación incierta.
Simulador grafica únicamente la proyección devuelta por Oracle; no replica fórmulas. Una cuenta opcional desactiva saldo/tasa manuales. Los reportes son árboles expandibles, el historial tiene dos pestañas, auditoría y log tienen vistas separadas y laboratorio catorce botones. Estado de conexión verde/rojo visible en Dashboard. Mes inicial según America/Lima.
Tailwind CDN y CSS local de respaldo con diseño responsive. Navegación móvil con inert cuando está cerrada, foco visible, etiquetas de formularios, diálogos nativos con Escape y mensajes accesibles. La página provisional fase4.html fue reemplazada. work/ contiene solo QA estático con datos ficticios y capturas, ignorado por Git. La prueba real de cada pantalla queda a cargo del usuario; no marcar F5 Verificado antes de su confirmación.

## Decisiones de Fase 6
README documenta el comportamiento existente, incluyendo scripts no repetibles, uso por secciones del smoke, diferencia entre recrear datos de demo y respaldar operaciones reales, límites de snapshots y uso manual del servidor. No se modificó la especificación, no se leyó .env y no se ejecutó SQL ni run.py.
Las filas F5 se verificaron únicamente por la última confirmación «continua». La nueva comprobación del estado actual de tablas AD_ todavía debe hacerla el usuario; un comparador local solo valida los archivos guardados. Mantener Fase 6 pendiente hasta su confirmación.
El usuario autorizó un único commit local de cierre con el estado actual, excluyendo .env, .venv y work. Las fases anteriores se incluyen en ese commit; no se inventa un historial de commits por fase. No hacer push. La comprobación actual AD_ sigue pendiente de confirmación explícita; los snapshots guardados sí dan SNAPSHOTS OK.
