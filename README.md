# Banco Oracle: Cuentas y Transferencias

Aplicación académica para demostrar objetos Oracle y programación PL/SQL con acciones reales. El dinero se expresa en soles (S/). La lógica financiera reside en Oracle; Flask valida formatos, llama los objetos y controla las transacciones.

**Estado:** fases 0 a 5 confirmadas por el usuario. La Fase 6 tiene la documentación preparada; su cierre requiere comprobar nuevamente el snapshot actual de tablas AD_ y confirmar el cierre. El usuario autorizó el commit local de cierre; no se autorizó push. La Fase 7 es opcional y no está implementada.

## 1. Requisitos

- Windows y PowerShell; Python 3.11 o superior; Git.
- Un esquema personal en Oracle FreeSQL con los privilegios comprobados en la Fase 0.
- Un navegador actual con JavaScript habilitado. Tailwind se carga por CDN; hay CSS local de respaldo.
- Acceso de red al host/puerto/servicio entregados por FreeSQL. El controlador usa modo THIN y no requiere Oracle Instant Client.

La instalación del proyecto no crea usuarios, no concede privilegios, no cambia contenedores y no usa cuentas administrativas. Oracle 21c XE no forma parte de este proyecto. Si la conexión externa no es viable, detenerse y revisar la conexión; el Plan B con Docker/WSL2 solo se prepara si el usuario lo pide.

## 2. Instalación local

Abre PowerShell en la carpeta del proyecto. En este equipo:

```powershell
Set-Location -LiteralPath 'C:\Users\emerson solano perez\Documents\AÑO 3 - 2026\CICLO 6\DISEÑO DE BASE DE DATOS\sistema_banco'
python --version
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

En una instalación ya preparada, no necesitas recrear `.venv`; basta con instalar dependencias si faltan. Usar el ejecutable completo evita cambiar la política de ejecución de PowerShell para activar el entorno.

Dependencias: Flask, python-oracledb, python-dotenv y pytest. El código probado en este entorno utiliza Python 3.13; el requisito del proyecto sigue siendo Python 3.11+.

### Configuración privada

**Solo el usuario crea y edita `.env`.** Si todavía no existe, copia el ejemplo una sola vez:

```powershell
Copy-Item -LiteralPath .env.example -Destination .env
```

No repitas la copia sobre una configuración ya completada. Abre `.env` tú mismo en el editor y completa estos campos; nunca pegues sus valores en el chat, en capturas o en Git:

| Variable | Contenido |
| --- | --- |
| DB_USER | Usuario del esquema personal |
| DB_PASSWORD | Contraseña de ese esquema |
| DB_DSN | Host, puerto y servicio, o cadena completa del panel |
| POOL_MIN | Mínimo de conexiones; por defecto 1 |
| POOL_MAX | Máximo de conexiones; por defecto 3 |
| DB_WALLET_DIR | Solo si FreeSQL requiere wallet; descomentar en el ejemplo local |
| DB_WALLET_PASSWORD | Solo si se requiere contraseña del wallet |

En tu cuenta de [Oracle FreeSQL](https://freesql.com), abre el panel de tu esquema y sus **Detalles de conexión**. Copia el usuario y la cadena de conexión que te entregue el panel. Si muestra los componentes separados, utiliza `host:puerto/servicio`; si entrega un DSN completo o `tcps://...`, conserva ese formato. No uses la dirección de la página web como DSN. Si exige wallet, guarda sus archivos en una carpeta privada fuera del repositorio e indica esa ubicación local.

`app/config.py` lee `.env` desde la raíz del proyecto. Si defines `BANCO_ENV_FILE`, utiliza ese archivo local alternativo. Las variables ya definidas en el entorno del proceso tienen prioridad; el cargador no las sobrescribe. Wallet y contraseña del wallet solo se pasan al controlador cuando están definidos.

`.gitignore` excluye `.env`, `.venv`, cachés y `work/`. Las reglas de `.claude/settings.json` deniegan leer `.env` en Claude Code. Si usas otro agente, configura la protección equivalente y respeta la prohibición de lectura de AGENTS.md. No guardes wallets, credenciales ni copias privadas dentro del código fuente.

### Prueba manual de conexión

Ejecuta tú:

```powershell
.\.venv\Scripts\python.exe probar_conexion.py
```

Esperado: `Usuario conectado: ...`, con tu usuario. El agente no ejecuta este archivo ni solicita tu contraseña. Ante un fallo, revisa el DSN exacto, TCPS, wallet y acceso de red. No compartas cadenas con credenciales.

## 3. Preparación de Oracle y orden de scripts

Los scripts los pega y ejecuta el usuario en la hoja de trabajo de FreeSQL, usando **ejecutar como SCRIPT**. Usa una hoja sin transacciones pendientes. No elimines las líneas `/` que cierran los bloques PL/SQL. Habilita DBMS_OUTPUT para ver los mensajes de las pruebas.

**Instalación inicial en un esquema sin los objetos del banco:**

| Orden | Archivo / sección | Resultado esperado |
| --- | --- | --- |
| 0 | sql/00_prueba_privilegios.sql | Ninguno de los 40 nombres de producción existe; auxiliares válidos y eliminados; sin errores |
| 0b | sql/00b_snapshot_ad.sql | Guardar total y lista de tablas AD_ en docs/snapshot_ad_antes.txt |
| 1 | sql/01_tablas.sql | Cinco tablas con restricciones y comentarios |
| 2 | sql/02_secuencias.sql | Cinco secuencias |
| 3 | sql/03_tipos.sql | Dos tipos SQL |
| F1 | Solo sección F1 de sql/smoke/smoke_plsql.sql | 5 tablas, 5 secuencias y 2 tipos VALID; F1 OK |
| 4 | sql/04_vistas.sql | Dos vistas |
| 4b | sql/11_limites_categorias.sql (una vez, antes de 05) | Configuración Gold/Premium y sinónimo; valores iniciales 5000/50000 |
| 5 | sql/05_funciones.sql | SP_LOG_ERROR y tres funciones |
| 6 | sql/06_triggers.sql | Cinco triggers BEFORE/AFTER |
| F2A | Solo sección F2A del smoke | Once objetos VALID; funciones, vistas y triggers correctos; F2A OK |
| 7 | sql/07_procedimientos.sql | Nueve procedimientos de negocio; diez incluyendo SP_LOG_ERROR |
| 8 | sql/08_funcion_pipelined.sql | Función mensual pipelined con cursor explícito |
| F2B | Solo sección F2B del smoke | Reporte JSON, estado mensual, errores y versiones sin binds de los dos bloques; F2B OK |
| 9 | sql/09_sinonimos.sql | Cinco sinónimos privados sobre tablas propias |
| 10 | sql/10_datos_prueba.sql | DATOS OK: 6 clientes, 8 cuentas, 30 movimientos; COMMIT completado |
| F3 | Solo sección F3 del smoke | Sinónimos, transferencia, siete errores y log persistente; F3 OK |
| Final | sql/00b_snapshot_ad.sql | Guardar salida en docs/snapshot_ad_despues.txt y comparar |

Este orden es para instalar o recrear; **no vuelvas a ejecutarlo sobre la instalación existente solo para abrir la aplicación**.

Los scripts 01, 02, 03 y 10 se ejecutan una sola vez sobre un esquema preparado. Los scripts 04 a 09 usan `CREATE OR REPLACE`. Si algún CREATE falla por falta de privilegios, detenerse y compartir el error sin credenciales; no aplicar cambios de diseño por cuenta propia.

Los archivos `sql/bloques/simulador_interes.sql` y `resumen_cliente.sql` no crean objetos persistentes. Flask los ejecuta con binds desde una whitelist cerrada; no los pegues con binds sin adaptar en la hoja. F2B ya contiene sus versiones de prueba derivadas del código fuente. Los binds reales se prueban desde la aplicación.

Ejecuta únicamente la sección smoke correspondiente a la fase. F1 comprueba los valores iniciales de secuencias: se ejecuta antes de F2A y no se repite una vez consumidos NEXTVAL. F2A, F2B y F3 revierten sus operaciones de prueba; las secuencias no retroceden. Los errores intencionales de F2B/F3 dejan registros en el log autónomo. Esos mensajes ORA son resultados esperados del laboratorio si el smoke termina con su mensaje OK.

El script 10 termina en COMMIT: crea datos de demostración persistentes. Solo después de una carga limpia hay exactamente 6/8/30 y dos clientes por categoría. Las operaciones posteriores de la interfaz cambian esos totales; no vuelvas a ejecutar F3 esperando los conteos iniciales después de una demostración con nuevas operaciones.

### Snapshot de tablas AD_

`00b_snapshot_ad.sql` solo consulta los nombres y su cantidad en USER_TABLES. No lee filas de las tablas ajenas. Guarda **ambos resultados** (total y lista completa) en cada archivo; no inventes un total ni sustituyas nombres.

Para guardar la salida: copia los resultados de FreeSQL, crea el archivo en VS Code, pega el texto y guarda. En la barra inferior comprueba UTF-8. Conserva el mismo orden, encabezado y separadores en ambos archivos. Por ejemplo, si el navegador traduce `TABLE_NAME` como `NOMBRE_DE_LA_TABLA`, vuelve a copiar sin traducción o unifica únicamente ese encabezado; no cambies los nombres de las tablas ni las cifras.

```powershell
.\.venv\Scripts\python.exe tests/comparar_snapshots.py
```

Esperado: `SNAPSHOTS OK`. El comparador normaliza espacios, líneas vacías y finales de línea. Código de salida 0: iguales; 1: diferentes; 2: ausentes, ilegibles o vacíos. Compara archivos guardados, no consulta Oracle: para verificar el estado **actual**, primero hay que volver a ejecutar el SQL y guardar la nueva salida. Solo comprueba nombres/cantidad, no el contenido de tablas AD_.

## 4. Ejecutar y usar la aplicación

En PowerShell, desde el proyecto:

```powershell
.\.venv\Scripts\python.exe run.py
```

Abre [Banco Oracle local](http://127.0.0.1:5000). El servidor de desarrollo escucha solo en el equipo local, con debug desactivado. Detén con Ctrl+C. Después de cambios en Python, reinícialo; si el navegador conserva recursos antiguos, recarga con Ctrl+F5.

El Dashboard muestra conexión verde o roja. Las pantallas incluyen **Objetos Oracle usados** y **Ver código PL/SQL**. La franja **Cómo funciona en Oracle** es plegable. Muestra la última acción relevante y los objetos declarados por su respuesta; las recargas auxiliares no reemplazan ese contexto. No representa una traza automática del motor. El modal diferencia objetos reportados de otras implementaciones disponibles; el catálogo descriptivo no sustituye el código SQL. El modal funciona leyendo los archivos SQL locales, incluso si Oracle no está disponible.

| Pantalla | Ruta | Acción principal |
| --- | --- | --- |
| Dashboard | / | Actualizar resumen y comprobar conexión |
| Clientes | /clientes | Alta, edición y resumen del cliente |
| Cuentas | /cuentas | Apertura, estado, historial y últimos movimientos |
| Operaciones | /operaciones | Depósito, retiro y transferencia con comisión en vivo |
| Estado de cuenta | /estado-cuenta | Movimientos y saldo acumulado del mes |
| Reporte | /reporte | Árbol de cliente, cuentas y últimos movimientos |
| Intereses y categorías | /intereses | Aplicar por mes, actualizar categorías y consultar nivel |
| Simulador | /simulador | Proyección con valores manuales o cuenta opcional |
| Auditoría y errores | /auditoria | Consultar auditoría y log de errores |
| Laboratorio | /laboratorio | Demostrar siete excepciones estándar y siete propias |

Las transferencias muestran una cotización con espera de 300 ms al escribir el monto. El botón Revisar no envía una escritura: abre una revisión con cuenta, destino, monto, comisión y total cotizados. Solo Confirmar envía el POST, con protección de doble envío. Cambiar cuenta, destino o monto invalida revisión y cotización. La revisión no reserva saldo ni comisión. El procedimiento vuelve a validar saldo, estado y comisión al confirmar. No hay reintento automático de escrituras. Tras el resultado puedes consultar movimientos y continuar con otra operación. Si aparece «No se pudo confirmar la operación», revisa el estado de cuenta antes de repetirla. Una cuenta bloqueada no permite mover dinero.

Administración separa las pestañas Intereses mensuales y Categorías de clientes. Aplicar intereses exige revisar el periodo antes de confirmar y no anticipa un número de afectados; los conteos se muestran desde la respuesta real. La consulta de categoría para un saldo no actualiza clientes. Intereses se aplican una sola vez por mes de referencia a cada cuenta elegible; un interés redondeado a cero se omite. Las categorías no cambian automáticamente al operar: utiliza **Revisar clientes** y después **Recalcular categorías**. El simulador no registra movimientos, admite hasta 600 meses y devuelve meta no alcanzada si supera ese límite. Sus aportes se consideran al final de cada mes.

### Comprobar la API manualmente

Con el servidor en una terminal, abre otra y ejecuta:

```powershell
Invoke-RestMethod http://127.0.0.1:5000/api/salud
$clientes = Invoke-RestMethod http://127.0.0.1:5000/api/clientes
$idCliente = $clientes.datos[0].id_cliente
Invoke-RestMethod "http://127.0.0.1:5000/api/clientes/$idCliente/resumen"
Invoke-RestMethod http://127.0.0.1:5000/api/simulador -Method Post -ContentType 'application/json' -Body '{"saldo_inicial":1000,"tasa_anual":12,"meses":2,"aporte_mensual":100,"meta":2000}'
```

Esperado: `ok: True`; resumen del cliente existente; saldo final 1221.10 en la simulación. Usa IDs obtenidos del listado: las pruebas anteriores consumen secuencias y el primer cliente no tiene por qué ser 1.

Todas las respuestas API usan `{ok, mensaje, codigo, datos, objetos_oracle}`. Los reportes JSON y el resumen están en `datos.json`; la proyección está en `datos.proyeccion`. `/api/codigo/<objeto>` coloca `{objeto, tipo, archivo, codigo}` dentro de `datos`; nombres desconocidos responden 404. Detalle de endpoints y errores: docs/ESPECIFICACION.md, secciones B3.4 y B3.5.

### Organización y continuidad del panel interno

Las diez rutas se conservan y se agrupan en Inicio; Atención y operaciones; Administración; Consultas y supervisión; Pruebas y demostración. Estos grupos organizan tareas, no implementan permisos, usuarios ni login.

El recorrido normal es **registrar cliente → abrir su cuenta → operar → consultar movimientos/estado mensual → supervisar actividad**. Desde el resultado del alta puedes abrir una cuenta con el cliente ya seleccionado. Cuentas permite filtro por titular, vuelta al listado general, historial completo, últimos 20 movimientos, estado mensual y acceso a Operaciones. El bloqueo se revisa antes de confirmar: impide mover dinero, pero no elimina ni cierra la cuenta.

| Destino | Parámetros opcionales | Efecto sin escritura al abrir |
| --- | --- | --- |
| /clientes | nuevo=1 | Abre el formulario de alta |
| /cuentas | id_cliente | Filtra por ID del titular, con filtro visible y Ver todas |
| /cuentas | id_cliente y abrir=1 | Abre el formulario con titular preseleccionado |
| /cuentas | id_cuenta | Resalta y consulta movimientos de la cuenta |
| /operaciones | id_cuenta y tipo | Preselecciona cuenta activa y depositar/retirar/transferir |
| /estado-cuenta | id_cuenta | Preselecciona cuenta para la consulta mensual |
| /reporte | id_cliente | Preselecciona titular para generar el árbol |

Los IDs se validan y contrastan con las opciones disponibles. Ante un parámetro inválido se informa y se permite elegir manualmente. Nombres repetidos no se usan para enlazar titulares. GET /api/cuentas admite id_cliente opcional, validado y pasado por binds; sin filtro conserva el listado general. Cada cuenta agrega id_cliente y tipo conservando los campos existentes. Se relacionan V_CUENTAS_RESUMEN y CUENTAS sin modificar la vista SQL.

El resumen del cliente distingue categoría registrada y nivel calculado; si difieren, orienta hacia Actualizar categorías. El reporte aclara que muestra los últimos N movimientos de cada cuenta, no todo el historial. El simulador diferencia plazo de proyección y tiempo hasta la meta, y su resultado advierte que no registra movimientos ni modifica saldo. Auditoría y Registro de errores tienen propósitos distintos y un alcance de últimos 200 registros. Laboratorio explica los catorce casos y ofrece ir a Cuentas si no hay una activa.

El catálogo de 42 objetos está en app/static/datos/objetos_oracle.json y su coordinación en oracle.js. El código continúa viniendo exclusivamente del índice de archivos SQL. La documentación y evidencia de validación de esta reorganización están en docs/REORGANIZACION_UI_UX.md; la nueva prueba real del usuario sigue pendiente.

## 5. Pruebas locales sin base de datos

```powershell
.\.venv\Scripts\python.exe -m pytest -q
.\.venv\Scripts\python.exe -m pip check
```

Referencia tras reorganización UI/UX: **160 pruebas correctas** (129 en la versión previa). pytest no inicia el servidor ni se conecta a Oracle. `tests/conftest.py` bloquea connect, create_pool, connect_async, create_pool_async y la lectura de dotenv; los datos y conexiones de pruebas son ficticios.

| Prueba | Qué valida |
| --- | --- |
| test_humo.py | Infraestructura mínima |
| test_api.py | Contrato y validación de cada endpoint |
| test_errores.py | Cada fila de B3.4, restricciones y ocultación de esquema |
| test_reintentos.py | Una repetición de lectura; ninguna de POST/PUT; commit incierto y rollback |
| test_sin_tbl.py | Solo sinónimos en Python, JavaScript y HTML de la aplicación |
| test_codigo_indice.py | Las 42 entradas actuales de B2.2 y 404 de nombres desconocidos |
| test_repositories.py | Orden de IN/OUT, binds, lectura CLOB y Decimal |
| test_pool_config.py | Wallet opcional, pool perezoso y timeouts |
| test_paginas.py | Diez rutas, grupos, opción activa, componentes y contexto sin escritura |
| test_laboratorio.py | Códigos esperados, rollback y esquema oculto |

Las pruebas SQL del smoke son manuales y están separadas en `sql/smoke/`. Las pruebas de navegador de desarrollo se realizaron sobre HTML estático con respuestas ficticias; no sustituyen la comprobación real de una operación por pantalla. La confirmación del usuario registra esas comprobaciones en la matriz.

## 6. Guion de demostración punto por punto

Antes de empezar: inicia el servidor, comprueba conexión verde, asegúrate de tener dos cuentas activas y abre el panel de objetos después de cada acción. La demo hace cambios reales en los datos del banco; el laboratorio los revierte, salvo el log.

| Punto | Acción visible | Código que mostrar y resultado |
| --- | --- | --- |
| 1. Preparación | Explicar prueba de conexión y privilegios de Fase 0 | probar_conexion.py y 00_prueba_privilegios.sql; usuario y esquema personal |
| 2. Tablas y DML | Crear un cliente y editar su nombre/correo | Script 01 y sinónimo CLIENTES; INSERT/UPDATE y restricciones nombradas |
| 3. Vistas | Actualizar Dashboard; abrir historial de una cuenta | V_CUENTAS_RESUMEN y V_ESTADO_CUENTA; joins y resumen de movimientos |
| 4. Secuencias | Abrir una cuenta y realizar un depósito | SQ_CUENTA avanza de diez en diez; ID y número derivan del mismo NEXTVAL; SQ_MOVIMIENTO identifica la operación |
| 5. Sinónimos | Consultar clientes, selectores, movimientos, auditoría y log | CLIENTES, CUENTAS, MOVIMIENTOS, AUDITORIA, LOG_ERRORES; aplicación desacoplada de nombres físicos |
| 6. Cursor explícito | Consultar un mes con movimientos | FN_ESTADO_CUENTA_MENSUAL: OPEN, FETCH, EXIT WHEN y CLOSE; saldo anterior al mes y PIPE ROW |
| 7. Cursor implícito | Aplicar intereses a un mes y repetirlo | SP_APLICAR_INTERESES: SQL%ROWCOUNT/SQL%FOUND; segunda ejecución sin duplicación |
| 8. Cursores anidados/con parámetros | Generar reporte y expandir cliente/cuentas; cambiar límite | SP_REPORTE_CLIENTES: c_cuentas(p_cli), c_movs(p_cta,p_limite) y JSON jerárquico |
| 9. Bloques anónimos | Simular ahorro y consultar resumen del cliente | BLOQUE_SIMULADOR_INTERES y BLOQUE_RESUMEN_CLIENTE; DECLARE/BEGIN/EXCEPTION/END con binds |
| 10. Variables/constantes/%TYPE/%ROWTYPE | Seleccionar cuenta opcional en simulador y ver resumen | Constantes, saldo/tasa tipados y registros completos de cuenta/cliente |
| 11. FOR/LOOP/WHILE | Aplicar intereses, actualizar categorías y simular meta | FOR de cuentas/meses, LOOP/EXIT WHEN de clientes y WHILE limitado a 600 meses |
| 12. IF/ELSIF/ELSE | Consultar categorías con 4999.99, 5000 y 50000 | FN_CATEGORIA_CLIENTE devuelve BASICO/GOLD/PREMIUM; FN_COMISION decide tasas; resumen decide siguiente nivel |
| 13. Procedimientos IN/OUT | Depositar, retirar y transferir entre cuentas | SP_DEPOSITAR, SP_RETIRAR, SP_TRANSFERIR y SP_ABRIR_CUENTA; estado, código y mensaje OUT; COMMIT en servicio |
| 14. Funciones | Elegir cuenta y escribir monto de transferencia | FN_SALDO_DISPONIBLE y FN_COMISION; saldo y comisión en vivo, mínimo S/ 1.00 |
| 15. Triggers BEFORE/AFTER | Alta de cliente, apertura, operación y bloqueo/desbloqueo | Cinco triggers: mayúsculas, IDs, saldo posterior, actualización única de saldo y auditoría |
| 16. Excepciones | Ejecutar un caso estándar y uno propio en Laboratorio; consultar log | SP_LAB_ERRORES, SP_LOG_ERROR, SQLCODE/SQLERRM y HTTP; RERAISE y transacción autónoma |

Ejemplo de transferencia: anota ambos saldos, transfiere S/ 100, revisa comisión, abre últimos movimientos del origen y destino y luego auditoría. Deben aparecer TRANSF_ENVIADA, COMISION y TRANSF_RECIBIDA; el origen disminuye monto más comisión y el destino aumenta solo el monto. No descuentes de nuevo desde Python/JavaScript.

Referencias de funciones: FN_COMISION(100,BASICO)=1.50; (10,BASICO)=1.00; (1000,GOLD)=8.00; (1000,PREMIUM)=3.00. Las tres categorías tienen comisión mínima de S/ 1.00.

En Laboratorio, NO_DATA_FOUND presenta SQLCODE 100; es el valor esperado de esa excepción PL/SQL. Los demás casos muestran sus códigos negativos. El laboratorio responde `ok: True` cuando capturó la excepción esperada y muestra en sus datos el HTTP que correspondería al error de negocio. Fuera del laboratorio no se expone SQLERRM crudo.

La evidencia de requisito → objeto → pantalla → endpoint → prueba se mantiene en docs/MATRIZ_OBJETOS.md. La lista cerrada contiene **40 objetos de BD + 2 bloques = 42 entradas**; no se indexan pruebas, datos ni limpieza.

## 7. Respaldo

### Qué conservar

Conserva el código fuente, README, requirements.txt, `sql/`, `app/`, `tests/`, `docs/ESPECIFICACION.md`, matriz e instrucciones del agente. Conserva ambos snapshots como evidencia de nombres/cantidad de tablas ajenas. `.venv`, cachés y `work/` se pueden recrear y no forman parte del respaldo del proyecto.

Mantén `.env` y cualquier wallet únicamente en un almacenamiento privado separado. El agente no los lee ni los incorpora a Git. Un respaldo del código **no es un respaldo de los movimientos reales**: recrear con el script 10 solo restituye la demostración original, no operaciones posteriores. Este proyecto no implementa exportación de datos ni backup del esquema completo; no exportes ni leas las tablas AD_.

### Si se pierde el esquema o cambias de cuenta

1. Crea/selecciona tu nuevo esquema desde FreeSQL y obtén sus detalles de conexión. Actualiza tú `.env` o tu archivo privado alternativo; nunca codifiques el nombre del esquema en SQL/Python.
2. Ejecuta la prueba manual de conexión y `00_prueba_privilegios.sql`. Si hay nombres de B2.2 ya existentes o faltan privilegios, detente y revisa antes de continuar.
3. Genera un nuevo snapshot inicial para ese esquema. Conserva la evidencia del esquema anterior aparte; no compares tablas de dos cuentas distintas como si fueran el mismo entorno.
4. Sigue toda la tabla de instalación: 01 → 02 → 03 → F1 → 04 → 05 → 06 → F2A → 07 → 08 → F2B → 09 → 10 → F3.
5. Genera el snapshot posterior del nuevo esquema, compáralo, ejecuta pytest e inicia Flask. Comprueba salud, resumen y simulador real, además de las diez pantallas.

### Si quieres recrear los objetos en el mismo esquema

`sql/99_limpiar.sql` elimina **únicamente los 40 objetos actuales de B2.2**, uno por uno y en orden inverso de dependencias. Elimina también los datos del banco, la auditoría y el log. DDL no se revierte con ROLLBACK. No lo ejecutes para iniciar Flask, corregir un formulario o comprobar Fase 6.

Solo si tú decides expresamente rehacer el banco, detén Flask, conserva el respaldo que necesites de tus datos propios y ejecuta manualmente 99 como SCRIPT. Tolera objetos ausentes por los códigos especificados y relanza cualquier otro error. No descubre ni elimina «todos los objetos del usuario», ni referencia tablas AD_. Después sigue de nuevo la secuencia de instalación completa, incluida la prueba de privilegios sobre nombres ya ausentes.

No existe ejecutor automático SQL: `ejecutar_sql.py` pertenece a la Fase 7 opcional, solo si se solicita.

## 8. Problemas frecuentes

| Síntoma | Comprobación |
| --- | --- |
| Módulos Python no encontrados | Usa el ejecutable .venv indicado e instala requirements.txt |
| No conecta o indicador rojo | Prueba manual de conexión; revisa host/puerto/servicio, TCPS y wallet sin compartir valores |
| Cuenta ocupada | Resuelve tu transacción pendiente en FreeSQL con COMMIT o ROLLBACK según corresponda; bloqueo máximo WAIT 5 |
| Error de confirmación incierta | Consulta movimientos y saldo antes de repetir la operación |
| Cuenta no aparece habilitada en Operaciones | Revisa si está bloqueada en Cuentas |
| Misma categoría después de operar | Revisa clientes y confirma Recalcular categorías; se calcula con saldo total del cliente |
| Cero intereses aplicados | Verifica estado, tasa, saldo, mes ya procesado y redondeo a cero |
| No hay movimientos en un mes | Escoge el mes en que registraste operaciones; revisa fecha en historial |
| Snapshots diferentes solo por encabezado | Copia en el mismo idioma/formato; conserva nombres, cantidad y orden originales |
| PLS-00382 en una copia antigua de F2B | Usa la versión actual de smoke y bloques: variables JSON locales distintas de los OUT CLOB |
| Cambios de interfaz no visibles | Reinicia Flask tras cambios Python y recarga navegador con Ctrl+F5 |

## 9. Comprobación final de Fase 6 y Git

Después de confirmar las diez pantallas, vuelve a ejecutar **solo** `sql/00b_snapshot_ad.sql` en FreeSQL. Guarda la salida actual en `docs/snapshot_ad_despues.txt` sin sobrescribir el snapshot inicial; conserva encabezados y formato comparables. En terminal:

```powershell
.\.venv\Scripts\python.exe tests/comparar_snapshots.py
.\.venv\Scripts\python.exe -m pytest -q
git check-ignore .env
git ls-files -- .env
```

Esperado: SNAPSHOTS OK; pruebas correctas; `.env` ignorado; ninguna salida del último comando. La matriz marca Verificado solo después de las confirmaciones del usuario que cubren cada fila. El estado actual de AD_ requiere la nueva salida de FreeSQL; comparar dos archivos viejos no basta.

Para la reorganización actual en vistas/flujo_normal, el usuario realiza personalmente commits y push: el agente no los ejecuta ni prepara staging. El permiso anterior de cierre correspondió únicamente a ea530c0. La regla general de A7 exige permiso explícito para otros commits. Antes de cada commit se revisa `git status` y se confirma que `.env` no aparezca. No se hace push sin solicitud. El usuario autorizó un único commit local de cierre que recoge el estado real actual, incluidas las fases anteriores, sin inventar un historial anterior. Nunca incluyas credenciales, wallets, `.venv` ni `work/`.


### Legibilidad de la interfaz

El ajuste visual común conserva el título de página en 32 px (28 en móvil), texto/tabla/menú en 15 px, grupos de navegación en 12 px y botones en 14 px. Los estilos específicos del panel resisten el preflight que Tailwind CDN inyecta después de cargar. Se verificó el runtime real del CDN: antes reducía el título a 14 px.

En Cuentas, Saldo y sus valores se alinean a la derecha, Tipo/Estado al centro y Cuenta/Titular a la izquierda. Las acciones de Cuentas se muestran compactas en una línea; su tabla usa texto de 14 px y filas de 55 px aproximadamente. Clientes conserva su texto de 15 px y centra las acciones. Los listados tienen un ancho máximo de 1180 px y márgenes simétricos dentro del área de trabajo. En pantallas estrechas la tabla se desplaza internamente sin ensanchar la página y puede enfocarse con teclado. Revisa el resultado con zoom 100 % (Ctrl+0) y recarga con Ctrl+F5 para descartar recursos antiguos.


El menú diferencia encabezados de grupo con mayúsculas, peso marcado, color verde suave y separadores; las opciones aparecen debajo con sangría y color propio. Este ajuste posterior es exclusivamente CSS: conserva encabezados principales, navegación, datos y operaciones. La navegación lateral dispone de scroll interno y barra discreta.


## Límites de saldo editables: actualizar la instalación existente

1. En una hoja de FreeSQL sin transacciones pendientes, ejecuta como SCRIPT `sql/11_limites_categorias.sql` **una sola vez**. Añade la configuración con Gold=5000 y Premium=50000, sin modificar clientes ni movimientos.
2. Ejecuta como SCRIPT `sql/05_funciones.sql`. Reemplaza las funciones existentes para que la clasificación consulte los límites guardados.
3. Opcionalmente ejecuta `sql/smoke/smoke_limites_categorias.sql`; debe imprimir LIMITES OK y revierte sus cambios.
4. Reinicia Flask y recarga con Ctrl+F5. En Categorías, pulsa **Editar límites**, modifica Gold/Premium y confirma **Guardar límites**. Cancelar conserva la configuración anterior.
5. **Actualizar categorías de clientes** aplica las condiciones guardadas a los clientes según sus saldos. Guardar los límites por sí solo no modifica sus categorías registradas.

La consulta por saldo y el resumen de cliente usan los mismos límites en Oracle. Las pruebas históricas con 4999.99/5000/50000 corresponden a la configuración inicial; no repetir la carga de datos ni las fases antiguas para verificar esta ampliación. En una instalación nueva, el script 11 debe ejecutarse antes del 05, como indica la tabla de instalación.


## Guía para la sustentación (Fase 8)

[docs/GUIA_SUSTENTACION.md](docs/GUIA_SUSTENTACION.md) explica los 16 puntos con analogías, acciones actuales, recorrido por Oracle, frases para exponer y preguntas probables. Incluye código literal, tabla de referencia y una demo de 14 minutos con Ana Torres y Luis Vargas. Documenta las adaptaciones y distingue pruebas locales de validación real pendiente.
