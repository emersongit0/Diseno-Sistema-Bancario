# Matriz activa MySQL

Rama migracion/MySQL. Estos objetos existen en el SQL actual. Se instalaron y probaron en MySQL 9.7.1. La base activa contiene demo; la exportación remota Oracle sigue pendiente. Las confirmaciones históricas Oracle están en docs/oracle/MATRIZ_OBJETOS.md.

| Tipo | Objeto | Archivo activo | Evidencia |
| --- | --- | --- | --- |
| TABLE | TBL_CLIENTES | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TABLE | TBL_CUENTAS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TABLE | TBL_MOVIMIENTOS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TABLE | TBL_AUDITORIA | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TABLE | TBL_LOG_ERRORES | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TABLE | TBL_LIMITES_CATEGORIAS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TABLE | TBL_SECUENCIAS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | CLIENTES | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | CUENTAS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | MOVIMIENTOS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | AUDITORIA | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | LOG_ERRORES | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | LIMITES_CATEGORIAS | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | SQ_CUENTA | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | V_ESTADO_CUENTA | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| VIEW | V_CUENTAS_RESUMEN | [sql/mysql/01_esquema.sql](../sql/mysql/01_esquema.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| FUNCTION | FN_SALDO_DISPONIBLE | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| FUNCTION | FN_CATEGORIA_CLIENTE | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| FUNCTION | FN_COMISION | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TRIGGER | TRG_CLIENTES_BI | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TRIGGER | TRG_CLIENTES_BU | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TRIGGER | TRG_CUENTAS_BI | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TRIGGER | TRG_MOVIMIENTOS_BI | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TRIGGER | TRG_MOVIMIENTOS_AI | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| TRIGGER | TRG_CUENTAS_AU | [sql/mysql/02_funciones_triggers.sql](../sql/mysql/02_funciones_triggers.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_LOG_ERROR | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_ABRIR_CUENTA | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_DEPOSITAR | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_RETIRAR | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_TRANSFERIR | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_CAMBIAR_ESTADO_CUENTA | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_APLICAR_INTERESES | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_ACTUALIZAR_CATEGORIAS | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_RESUMEN_CLIENTE | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_SIMULADOR_INTERES | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_ESTADO_CUENTA_MENSUAL | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_REPORTE_CLIENTES | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |
| PROCEDURE | SP_LAB_ERRORES | [sql/mysql/03_procedimientos.sql](../sql/mysql/03_procedimientos.sql) | Instalación real, catálogo/API y prueba integral MySQL |

38 objetos: 7 tablas, 9 vistas, 3 funciones, 13 procedimientos y 6 triggers. El auxiliar CARGAR_DEMO_MYSQL se crea y elimina al cargar el SQL autónomo y no pertenece al índice de producción.

Verificación: 112 pruebas unitarias, prueba real de transacciones e importación con datos de prueba, instalación desde INSTALAR_MYSQL.sql y navegador en diez pantallas. No se afirma haber migrado aún los registros remotos actuales.
