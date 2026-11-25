// Explicaciones descriptivas separadas del código SQL y de las reglas financieras.
import {api} from './api.js';
const q=s=>document.querySelector(s);
let catalogo={},ultima=null,secuencia=0,versionCodigo=0;
const acciones=[
 [/^POST \/api\/cuentas$/,'Abrir cuenta','MySQL valida al titular y genera automáticamente el identificador y el número de cuenta.'],
 [/^POST \/api\/transferir$/,'Transferir','MySQL valida las cuentas y registra envío, comisión y recepción.'],
 [/^POST \/api\/depositar$/,'Depositar','MySQL valida la cuenta y registra el abono; los triggers mantienen saldo y auditoría.'],
 [/^POST \/api\/retirar$/,'Retirar','MySQL verifica el saldo disponible antes de registrar el cargo.'],
 [/^POST \/api\/clientes$/,'Registrar cliente','MySQL conserva al titular, normaliza sus nombres y asigna un identificador.'],
 [/^PUT \/api\/clientes\//,'Editar cliente','Se actualizan los datos del titular mediante su vista de compatibilidad.'],
 [/^POST \/api\/cuentas\/\d+\/estado$/,'Cambiar estado de cuenta','MySQL valida el estado y audita el cambio; no elimina la cuenta.'],
 [/^GET \/api\/estado-cuenta\//,'Consultar estado mensual','Un procedimiento con cursor explícito recorre los movimientos y obtiene el saldo acumulado desde el saldo anterior al mes.'],
 [/^POST \/api\/intereses\/aplicar$/,'Aplicar intereses','Se procesan cuentas elegibles y se devuelve la cantidad realmente actualizada y omitida.'],
 [/^POST \/api\/categorias\/actualizar$/,'Actualizar categorías','Un cursor recorre los clientes y actualiza solo los niveles que cambiaron.'],
 [/^GET \/api\/categoria$/,'Consultar categoría','Una función determina el nivel para el saldo consultado; no actualiza clientes.'],
 [/^POST \/api\/simulador$/,'Simular ahorro','Un procedimiento MySQL proyecta el ahorro sin registrar movimientos ni modificar saldos.'],
 [/^POST \/api\/laboratorio\//,'Probar manejo de errores','Se provoca y captura una excepción controlada. Los cambios de prueba se revierten; el log autónomo puede permanecer.'],
 [/^GET \/api\/clientes\/\d+\/resumen$/,'Consultar resumen de cliente','Un procedimiento lee al titular y suma sus cuentas para explicar el nivel calculado.'],
 [/^GET \/api\/reporte\/clientes$/,'Generar reporte de clientes','Cursores con parámetros y anidados construyen el árbol de clientes, cuentas y últimos movimientos.'],
 [/^GET \/api\/cuentas\/\d+\/historial$/,'Consultar historial completo','La vista relaciona movimientos, cuentas y titulares; no aplica un filtro mensual.'],
 [/^GET \/api\/cuentas\/\d+\/movimientos$/,'Consultar últimos movimientos','La vista de compatibilidad permite consultar rápidamente los movimientos más recientes con un límite.'],
 [/^GET \/api\/auditoria$/,'Consultar auditoría','Se consultan los últimos hechos registrados por los triggers. Una transacción revertida no conserva su auditoría.'],
 [/^GET \/api\/errores$/,'Consultar registro de errores','El log autónomo puede conservar errores incluso cuando la operación se revierte.'],
 [/^GET \/api\/cuentas$/,'Consultar cuentas','La vista resume la actividad y la vista de compatibilidad permite identificar al titular por su ID.'],
 [/^GET \/api\/clientes$/,'Consultar clientes','La vista de compatibilidad permite acceder a los titulares sin usar nombres físicos en la aplicación.'],
];
function describir(d){const clave=d.method+' '+d.ruta.split('?')[0];const a=acciones.find(a=>a[0].test(clave));return [d.accion||a?.[1]||'Consultar información',a?.[2]||'La aplicación consulta los objetos MySQL indicados en la respuesta.'];}
function mostrar(){
 const nombres=ultima?.objetos||[];
 q('#oracle-estado').textContent=ultima?`Última respuesta: ${ultima.titulo}${ultima.ok?'':' · acción no completada'}`:'Implementación disponible; aún no hay una acción reportada.';
 q('#oracle-accion').textContent=ultima?.titulo||'Implementación relacionada con esta pantalla';
 q('#oracle-explicacion').textContent=ultima?(ultima.ok?ultima.explicacion:'MySQL o la API rechazó la acción. Revisa el mensaje de error; estos son los objetos declarados por esa respuesta.'):'Abre el código para explorar su implementación. Todavía no se reportan objetos de una acción realizada.';
 q('#objetos-oracle').replaceChildren(...nombres.map(n=>{const b=document.createElement('button');b.type='button';b.className='chip';b.textContent=n+' — '+(catalogo[n]?.proposito||'Ver implementación SQL');b.onclick=()=>verCodigo(n);return b;}));
 const temas=[...new Set(nombres.flatMap(n=>catalogo[n]?.temas||[]))];q('#oracle-temas').textContent=temas.length?'Temas del curso: '+temas.join(' · '):'';
}
async function cargarCodigo(nombre){const v=++versionCodigo;q('#contenido-codigo').textContent='Cargando código…';q('#copiar-codigo').disabled=true;q('#archivo-codigo').textContent='';q('#alcance-codigo').textContent=ultima?.objetos.includes(nombre)?'Objeto reportado por la última respuesta. Metadatos declarados por la aplicación.':'Implementación disponible relacionada con la pantalla; no implica que se haya ejecutado en la última acción.';
 try{const r=await api('/api/codigo/'+encodeURIComponent(nombre),{objetos:false});if(v!==versionCodigo)return;q('#contenido-codigo').textContent=r.datos.codigo;q('#archivo-codigo').textContent=r.datos.tipo+' · '+r.datos.archivo;q('#copiar-codigo').disabled=false;}catch(error){if(v===versionCodigo)q('#contenido-codigo').textContent=error.message;}
}
function verCodigo(nombre){const select=q('#objeto-codigo');select.replaceChildren();const reportados=ultima?.objetos||[];const disponibles=JSON.parse(q('#objetos-pagina').textContent).filter(n=>!reportados.includes(n));for(const [etiqueta,nombres] of [['Reportados por la última respuesta',reportados],['Otros objetos disponibles de esta pantalla',disponibles]]){if(!nombres.length)continue;const grupo=document.createElement('optgroup');grupo.label=etiqueta;for(const n of nombres)grupo.append(new Option(n,n));select.append(grupo);}if(!select.options.length)return;select.value=nombre||select.options[0].value;if(!q('#modal-codigo').open)q('#modal-codigo').showModal();cargarCodigo(select.value);}
export function iniciarMySQL(){
 document.addEventListener('oracle:inicio',ev=>{secuencia=ev.detail.sec;});
 document.addEventListener('oracle:objetos',ev=>{const d=ev.detail;if(d.sec!==secuencia)return;const [titulo,explicacion]=describir(d);ultima={objetos:[...new Set(d.objetos)],titulo,explicacion,ok:d.ok};mostrar();});
 q('#toggle-oracle').onclick=()=>{const abierto=q('#oracle-contexto').hidden;q('#oracle-contexto').hidden=!abierto;q('#toggle-oracle').setAttribute('aria-expanded',String(abierto));};
 q('#ver-codigo').onclick=()=>verCodigo();q('#objeto-codigo').onchange=e=>cargarCodigo(e.target.value);
 q('#copiar-codigo').onclick=async()=>{try{await navigator.clipboard.writeText(q('#contenido-codigo').textContent);q('#copiar-codigo').textContent='Copiado';setTimeout(()=>q('#copiar-codigo').textContent='Copiar código',1500);}catch{q('#archivo-codigo').textContent+=' · Selecciona y copia el código con Ctrl+C.';}};
 fetch('/static/datos/objetos_oracle.json').then(r=>{if(!r.ok)throw new Error();return r.json();}).then(datos=>{catalogo=datos;mostrar();}).catch(()=>{q('#oracle-temas').textContent='Catálogo descriptivo no disponible; el código SQL sigue accesible.';});
}
