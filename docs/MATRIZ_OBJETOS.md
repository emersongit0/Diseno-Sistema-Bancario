# Matriz de objetos y trazabilidad

Fase 0 confirmada por el usuario con «privilegios OK». Las 40 entradas B2.2 se incluyen individualmente; las filas adicionales detallan el temario B5. Los 12 objetos de Fase 1 están Verificado por confirmación «continua» del usuario. La Fase 2A fue confirmada con «continua»: sus objetos y las pruebas F2A cubiertas están Verificado. La persistencia autónoma del log fue confirmada en F3. Fase 2B confirmada con salida F2B OK y «continua»; filas cubiertas verificadas. Fase 3 confirmada por «continua»: sinónimos, carga, transferencia, errores, log y comparación de snapshots verificados. Fase 4 confirmada por «continua»: backend, salud y binds reales verificados. Fase 5 confirmada por «continua»: diez pantallas, acciones reales y panel/modal de código verificados. Todas las filas cuentan con confirmaciones de fases 0 a 5. Cierre de Fase 6 pendiente únicamente de nueva comprobación actual AD_ y del commit con permiso. Las pruebas de privilegios no verifican objetos de producción.

| Punto | Objeto | Archivo SQL | Pantalla | Endpoint | Prueba | Estado |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | TBL_CLIENTES | sql/01_tablas.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/auditoria; /api/errores | F1; test_codigo_indice.py (F4) | Verificado |
| 2 | TBL_CUENTAS | sql/01_tablas.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/auditoria; /api/errores | F1; test_codigo_indice.py (F4) | Verificado |
| 2 | TBL_MOVIMIENTOS | sql/01_tablas.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/auditoria; /api/errores | F1; test_codigo_indice.py (F4) | Verificado |
| 2 | TBL_AUDITORIA | sql/01_tablas.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/auditoria; /api/errores | F1; test_codigo_indice.py (F4) | Verificado |
| 2 | TBL_LOG_ERRORES | sql/01_tablas.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/auditoria; /api/errores | F1; test_codigo_indice.py (F4) | Verificado |
| 4 | SQ_CLIENTE | sql/02_secuencias.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/depositar; /api/errores | F1; F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 4 | SQ_CUENTA | sql/02_secuencias.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/depositar; /api/errores | F1; F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 4 | SQ_MOVIMIENTO | sql/02_secuencias.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/depositar; /api/errores | F1; F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 4 | SQ_AUDITORIA | sql/02_secuencias.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/depositar; /api/errores | F1; F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 4 | SQ_LOG | sql/02_secuencias.sql | Clientes / Cuentas / Operaciones / Auditoría | /api/clientes; /api/cuentas; /api/depositar; /api/errores | F1; F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 6 | T_MOV_FILA | sql/03_tipos.sql | Estado de cuenta mensual | /api/estado-cuenta/<id> | F1; F2B; test_codigo_indice.py (F4) | Verificado |
| 6 | T_MOV_TABLA | sql/03_tipos.sql | Estado de cuenta mensual | /api/estado-cuenta/<id> | F1; F2B; test_codigo_indice.py (F4) | Verificado |
| 3 | V_ESTADO_CUENTA | sql/04_vistas.sql | Cuentas: modal Ver historial | /api/cuentas/<id>/historial | F2A; test_codigo_indice.py (F4) | Verificado |
| 3 | V_CUENTAS_RESUMEN | sql/04_vistas.sql | Dashboard / Cuentas | /api/cuentas | F2A; test_codigo_indice.py (F4) | Verificado |
| 14 | FN_SALDO_DISPONIBLE | sql/05_funciones.sql | Operaciones | GET /api/cuentas/<id>/saldo | F2A; test_codigo_indice.py (F4) | Verificado |
| 14 | FN_CATEGORIA_CLIENTE | sql/05_funciones.sql | Intereses y categorías | GET /api/categoria | F2A; test_codigo_indice.py (F4) | Verificado |
| 14 | FN_COMISION | sql/05_funciones.sql | Operaciones: comisión en vivo | GET /api/comision | F2A; test_codigo_indice.py (F4) | Verificado |
| 14 | FN_ESTADO_CUENTA_MENSUAL | sql/08_funcion_pipelined.sql | Estado de cuenta mensual | GET /api/estado-cuenta/<id> | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_LOG_ERROR | sql/05_funciones.sql | Log de errores / Laboratorio | GET /api/errores; POST /api/laboratorio/<caso> | F2A; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_ABRIR_CUENTA | sql/07_procedimientos.sql | Cuentas | POST /api/cuentas | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_DEPOSITAR | sql/07_procedimientos.sql | Operaciones | POST /api/depositar | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_RETIRAR | sql/07_procedimientos.sql | Operaciones | POST /api/retirar | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_TRANSFERIR | sql/07_procedimientos.sql | Operaciones | POST /api/transferir | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_CAMBIAR_ESTADO_CUENTA | sql/07_procedimientos.sql | Cuentas | POST /api/cuentas/<id>/estado | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_APLICAR_INTERESES | sql/07_procedimientos.sql | Intereses y categorías | POST /api/intereses/aplicar | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_ACTUALIZAR_CATEGORIAS | sql/07_procedimientos.sql | Intereses y categorías | POST /api/categorias/actualizar | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_REPORTE_CLIENTES | sql/07_procedimientos.sql | Reporte jerárquico | GET /api/reporte/clientes | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 13 | SP_LAB_ERRORES | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F2B; F3; test_codigo_indice.py (F4) | Verificado |
| 15 | TRG_CLIENTES_BI | sql/06_triggers.sql | Clientes / Cuentas / Operaciones | POST/PUT /api/clientes; POST /api/cuentas; POST /api/depositar; POST /api/cuentas/<id>/estado | F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 15 | TRG_CUENTAS_BI | sql/06_triggers.sql | Clientes / Cuentas / Operaciones | POST/PUT /api/clientes; POST /api/cuentas; POST /api/depositar; POST /api/cuentas/<id>/estado | F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 15 | TRG_MOVIMIENTOS_BI | sql/06_triggers.sql | Clientes / Cuentas / Operaciones | POST/PUT /api/clientes; POST /api/cuentas; POST /api/depositar; POST /api/cuentas/<id>/estado | F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 15 | TRG_MOVIMIENTOS_AI | sql/06_triggers.sql | Clientes / Cuentas / Operaciones | POST/PUT /api/clientes; POST /api/cuentas; POST /api/depositar; POST /api/cuentas/<id>/estado | F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 15 | TRG_CUENTAS_AU | sql/06_triggers.sql | Clientes / Cuentas / Operaciones | POST/PUT /api/clientes; POST /api/cuentas; POST /api/depositar; POST /api/cuentas/<id>/estado | F2A; F3; test_codigo_indice.py (F4) | Verificado |
| 5 | CLIENTES | sql/09_sinonimos.sql | Clientes | GET/POST /api/clientes; PUT /api/clientes/<id> | F3; test_codigo_indice.py (F4) | Verificado |
| 5 | CUENTAS | sql/09_sinonimos.sql | Cuentas / Operaciones / Simulador | GET /api/cuentas/opciones | F3; test_codigo_indice.py (F4) | Verificado |
| 5 | MOVIMIENTOS | sql/09_sinonimos.sql | Cuentas: últimos movimientos | GET /api/cuentas/<id>/movimientos | F3; test_codigo_indice.py (F4) | Verificado |
| 5 | AUDITORIA | sql/09_sinonimos.sql | Auditoría | GET /api/auditoria | F3; test_codigo_indice.py (F4) | Verificado |
| 5 | LOG_ERRORES | sql/09_sinonimos.sql | Log de errores | GET /api/errores | F3; test_codigo_indice.py (F4) | Verificado |
| 9 | BLOQUE_SIMULADOR_INTERES | sql/bloques/simulador_interes.sql | Simulador | POST /api/simulador | F2B; test_api.py (F4); test_codigo_indice.py (F4) | Verificado |
| 9 | BLOQUE_RESUMEN_CLIENTE | sql/bloques/resumen_cliente.sql | Clientes: Ver resumen | GET /api/clientes/<id>/resumen | F2B; test_api.py (F4); test_codigo_indice.py (F4) | Verificado |
| 6 | OPEN / FETCH / CLOSE: FN_ESTADO_CUENTA_MENSUAL | sql/08_funcion_pipelined.sql | Estado mensual | GET /api/estado-cuenta/<id> | F2B | Verificado |
| 7 | SQL%FOUND / SQL%ROWCOUNT: SP_APLICAR_INTERESES | sql/07_procedimientos.sql | Intereses | POST /api/intereses/aplicar | F2B; F3 | Verificado |
| 8 | Cursores anidados y con parámetros: SP_REPORTE_CLIENTES | sql/07_procedimientos.sql | Reporte jerárquico | GET /api/reporte/clientes | F2B | Verificado |
| 10 | Constantes, %TYPE y %ROWTYPE de cuenta: BLOQUE_SIMULADOR_INTERES | sql/bloques/simulador_interes.sql | Simulador | POST /api/simulador | F2B; test_api.py (F4) | Verificado |
| 10 | %ROWTYPE de cliente: BLOQUE_RESUMEN_CLIENTE | sql/bloques/resumen_cliente.sql | Clientes | GET /api/clientes/<id>/resumen | F2B; test_api.py (F4) | Verificado |
| 11 | FOR: SP_APLICAR_INTERESES | sql/07_procedimientos.sql | Intereses | POST /api/intereses/aplicar | F2B | Verificado |
| 11 | LOOP: SP_ACTUALIZAR_CATEGORIAS | sql/07_procedimientos.sql | Categorías | POST /api/categorias/actualizar | F2B | Verificado |
| 11 | FOR y WHILE: BLOQUE_SIMULADOR_INTERES | sql/bloques/simulador_interes.sql | Simulador | POST /api/simulador | F2B | Verificado |
| 12 | IF/ELSIF/ELSE: FN_CATEGORIA_CLIENTE y FN_COMISION | sql/05_funciones.sql | Categorías / Operaciones | GET /api/categoria; GET /api/comision | F2A | Verificado |
| 12 | IF/ELSIF/ELSE: BLOQUE_RESUMEN_CLIENTE | sql/bloques/resumen_cliente.sql | Clientes | GET /api/clientes/<id>/resumen | F2B | Verificado |
| 16 | Excepciones estándar y RERAISE: SP_LAB_ERRORES | sql/07_procedimientos.sql | Laboratorio | POST /api/laboratorio/<caso> | F2B; F3; test_errores.py (F4) | Verificado |
| 16 | Log autónomo: SP_LOG_ERROR | sql/05_funciones.sql | Laboratorio / Log | POST /api/laboratorio/<caso>; GET /api/errores | F3 | Verificado |
| 16 | -20001: SP_RETIRAR | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 16 | -20002: SP_DEPOSITAR | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 16 | -20003: SP_DEPOSITAR | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 16 | -20004: SP_DEPOSITAR | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 16 | -20005: SP_TRANSFERIR | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 16 | -20006: SP_ABRIR_CUENTA | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 16 | -20007: SP_CAMBIAR_ESTADO_CUENTA | sql/07_procedimientos.sql | Laboratorio de errores | POST /api/laboratorio/<caso> | F3; test_errores.py; test_api.py (F4) | Verificado |
| 1 | Conexión manual a FreeSQL | No aplica: probar_conexion.py | Terminal | No aplica | Usuario conectado confirmado con «privilegios OK» | Verificado |
| 1 | Privilegios y ausencia de nombres B2.2 | sql/00_prueba_privilegios.sql | FreeSQL | No aplica | Prueba 00 confirmada con «privilegios OK» | Verificado |
| 1 | Snapshot inicial de nombres y cantidad AD_ | sql/00b_snapshot_ad.sql | FreeSQL | No aplica | docs/snapshot_ad_antes.txt guardado; confirmado con «privilegios OK» | Verificado |
| 2 | Carga de 6 clientes, 8 cuentas y 30 movimientos | sql/10_datos_prueba.sql | Clientes / Cuentas / Operaciones | /api/clientes; /api/cuentas; /api/cuentas/<id>/movimientos | F3: carga y saldos coherentes | Verificado |
| 1 | Snapshot final AD_ y comparación de nombres/cantidad | sql/00b_snapshot_ad.sql | FreeSQL / Terminal | No aplica | tests/comparar_snapshots.py: archivos antes/después idénticos | Verificado |
| 1 | Conexión Flask y salud | No aplica: app/db/pool.py | Dashboard (F5) | GET /api/salud | test_pool_config.py; test_reintentos.py; prueba real del usuario | Verificado |
| 9 | Binds reales de los dos bloques | sql/bloques/simulador_interes.sql; sql/bloques/resumen_cliente.sql | Simulador / Clientes (F5) | POST /api/simulador; GET /api/clientes/<id>/resumen | test_repositories.py; test_api.py; prueba real del usuario | Verificado |
| 16 | Contrato de errores HTTP B3.4 | No aplica: app/utils/errores.py | Todas (F5) | Endpoints B3.5 | test_errores.py; test_api.py; test_laboratorio.py | Verificado |
| 1 | Transacciones y reintentos de lectura | No aplica: app/services/transacciones.py | Todas (F5) | Endpoints B3.5 | test_reintentos.py: GET/simulador una vez; POST/PUT cero | Verificado |
| 3–16 | Índice local de los 40 objetos | Scripts 01 a 09 y sql/bloques/ | Modal de código (F5) | GET /api/codigo/<objeto> | test_codigo_indice.py; test_sin_tbl.py | Verificado |
| 3–16 | Contrato JSON de todos los endpoints | No aplica: app/routes/api_banca.py | Diez pantallas (F5) | Endpoints B3.5 | test_api.py; test_repositories.py | Verificado |
| 3 | Pantalla F5: Dashboard | sql/04_vistas.sql | Dashboard | GET /api/cuentas; GET /api/salud | QA navegador con mocks OK; manual F5 confirmado por «continua»: Actualizar resumen y estado conectado; panel y modal de código | Verificado |
| 2, 9, 15 | Pantalla F5: Clientes | sql/06_triggers.sql; sql/bloques/resumen_cliente.sql | Clientes | GET/POST /api/clientes; PUT /api/clientes/<id>; GET /api/clientes/<id>/resumen | QA navegador con mocks OK; manual F5 confirmado por «continua»: Alta, edición y resumen; panel y modal de código | Verificado |
| 3, 4, 5, 13, 15 | Pantalla F5: Cuentas | sql/04_vistas.sql; sql/07_procedimientos.sql; sql/09_sinonimos.sql | Cuentas | GET/POST /api/cuentas; POST /api/cuentas/<id>/estado; GET /api/cuentas/<id>/historial; GET /api/cuentas/<id>/movimientos | QA navegador con mocks OK; manual F5 confirmado por «continua»: Apertura, estado e historial con dos pestañas; panel y modal de código | Verificado |
| 13, 14, 15 | Pantalla F5: Operaciones | sql/05_funciones.sql; sql/07_procedimientos.sql | Operaciones | POST /api/depositar; POST /api/retirar; POST /api/transferir; GET /api/comision | QA navegador con mocks OK; manual F5 confirmado por «continua»: Saldo, comisión y transferencia; panel y modal de código | Verificado |
| 6 | Pantalla F5: Estado de cuenta | sql/08_funcion_pipelined.sql | Estado de cuenta | GET /api/estado-cuenta/<id> | QA navegador con mocks OK; manual F5 confirmado por «continua»: Consulta mensual; panel y modal de código | Verificado |
| 8 | Pantalla F5: Reporte de clientes | sql/07_procedimientos.sql | Reporte de clientes | GET /api/reporte/clientes | QA navegador con mocks OK; manual F5 confirmado por «continua»: Generar y expandir árbol; panel y modal de código | Verificado |
| 7, 11, 12 | Pantalla F5: Intereses y categorías | sql/05_funciones.sql; sql/07_procedimientos.sql | Intereses y categorías | POST /api/intereses/aplicar; POST /api/categorias/actualizar; GET /api/categoria | QA navegador con mocks OK; manual F5 confirmado por «continua»: Aplicar, actualizar y consultar; panel y modal de código | Verificado |
| 9, 10, 11 | Pantalla F5: Simulador | sql/bloques/simulador_interes.sql | Simulador | POST /api/simulador | QA navegador con mocks OK; manual F5 confirmado por «continua»: Proyección manual y cuenta opcional; panel y modal de código | Verificado |
| 5, 15, 16 | Pantalla F5: Auditoría y errores | sql/06_triggers.sql; sql/09_sinonimos.sql | Auditoría y errores | GET /api/auditoria; GET /api/errores | QA navegador con mocks OK; manual F5 confirmado por «continua»: Dos listados; panel y modal de código | Verificado |
| 16 | Pantalla F5: Laboratorio | sql/07_procedimientos.sql | Laboratorio | POST /api/laboratorio/<caso> | QA navegador con mocks OK; manual F5 confirmado por «continua»: Códigos Oracle, SQLERRM y HTTP; panel y modal de código | Verificado |

Incidencia F2B resuelta: el usuario ejecutó la versión corregida y compartió F2B OK. Los binds reales de Flask fueron confirmados en Fase 4.
