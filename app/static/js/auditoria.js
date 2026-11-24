import {api} from './api.js';
import {$,$$,esc,fecha,tabla,seguro,ocupado} from './ui.js';
let vista='auditoria',version=0;
async function cargar(){const actual=++version;const tipo=vista;const r=await api('/api/'+tipo);if(actual!==version)return;const columnas=tipo==='auditoria'?[['fecha','Fecha',v=>esc(fecha(v))],['tabla','Tabla'],['operacion','Operación'],['id_registro','Registro'],['usuario_bd','Usuario BD'],['detalle','Detalle']]:[['fecha','Fecha',v=>esc(fecha(v))],['procedimiento','Procedimiento'],['codigo','Código'],['mensaje','Mensaje']];tabla('#tabla-registros',r.datos,columnas);}
for(const boton of $$('[data-registro]'))boton.onclick=()=>{vista=boton.dataset.registro;for(const b of $$('[data-registro]')){b.classList.toggle('activo',b===boton);b.setAttribute('aria-pressed',String(b===boton));}$('#nota-registros').textContent=vista==='auditoria'?'Últimos 200 registros de movimientos y cambios de estado.':'Últimos 200 errores registrados, incluso si la operación fue revertida.';seguro(cargar);};
$('#actualizar').onclick=e=>ocupado(e.currentTarget,cargar);seguro(cargar);
