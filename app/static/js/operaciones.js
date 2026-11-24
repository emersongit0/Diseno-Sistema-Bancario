import {api} from './api.js';
import {$,$$,dinero,formulario,seguro,toast,cargarCuentas,aviso} from './ui.js';
let operacion='depositar',temporizador,version=0,controlador,comisionLista=false;
const nombres={depositar:'depósito',retirar:'retiro',transferir:'transferencia'};
function invalidar(){clearTimeout(temporizador);controlador?.abort();version++;comisionLista=false;}
async function saldo(){const id=$('#cuenta-origen').value;$('#saldo-disponible').textContent=id?'Consultando…':'Selecciona una cuenta';if(!id)return;const r=await api(`/api/cuentas/${id}/saldo`);if(id===$('#cuenta-origen').value)$('#saldo-disponible').textContent=dinero(r.datos.saldo);}
function cotizar(){
  invalidar();const monto=$('#monto').value;$('#resumen-monto').textContent=dinero(monto||0);$('#comision').textContent='—';
  if(operacion!=='transferir'){$('#total-operacion').textContent=dinero(monto||0);return;}
  $('#total-operacion').textContent='—';const id=$('#cuenta-origen').value;
  if(!id || !$('#monto').checkValidity() || !monto)return;
  const actual=version;$('#comision').textContent='Consultando…';
  temporizador=setTimeout(()=>seguro(async()=>{controlador=new AbortController();const r=await api(`/api/comision?monto=${encodeURIComponent(monto)}&id_cuenta=${encodeURIComponent(id)}`,{signal:controlador.signal});if(actual!==version)return;$('#comision').textContent=dinero(r.datos.comision);$('#total-operacion').textContent=dinero(r.datos.total_debitar);comisionLista=true;}),300);
}
for(const tab of $$('[data-operacion]'))tab.onclick=()=>{operacion=tab.dataset.operacion;for(const t of $$('[data-operacion]')){t.classList.toggle('activo',t===tab);t.setAttribute('aria-pressed',String(t===tab));}$('#titulo-operacion').textContent=`Realizar ${operacion==='transferir'?'una':'un'} ${nombres[operacion]}`;$('#confirmar-operacion').textContent=`Confirmar ${nombres[operacion]} ↗`;$('#campo-destino').hidden=operacion!=='transferir';$('#cuenta-destino').required=operacion==='transferir';$('#fila-comision').hidden=operacion!=='transferir';$('#etiqueta-cuenta').textContent=operacion==='transferir'?'Cuenta de origen':'Cuenta';$('#etiqueta-total').textContent=operacion==='depositar'?'Total a depositar':'Total a debitar';$('#nota-operacion').textContent=operacion==='transferir'?'La comisión depende de la categoría del titular y se confirma al transferir.':'El saldo se actualiza al confirmar la operación.';$('#resultado-operacion').replaceChildren();cotizar();};
$('#cuenta-origen').onchange=()=>{cotizar();seguro(saldo);};$('#monto').oninput=cotizar;
formulario('#form-operacion',async()=>{const tipo=operacion,origen=$('#cuenta-origen').value,destino=$('#cuenta-destino').value,monto=$('#monto').value;if(tipo==='transferir'&&origen===destino)throw new Error('Selecciona una cuenta de destino diferente.');if(tipo==='transferir'&&!comisionLista)throw new Error('Espera la consulta de comisión antes de confirmar.');const datos=tipo==='transferir'?{origen,destino,monto}:{id_cuenta:origen,monto};const r=await api('/api/'+tipo,{method:'POST',datos});toast(r.mensaje);aviso('#resultado-operacion',r.mensaje);$('#monto').value='';cotizar();await cargarCuentas(['#cuenta-origen','#cuenta-destino'],{soloActivas:true});await saldo();});
seguro(()=>cargarCuentas(['#cuenta-origen','#cuenta-destino'],{soloActivas:true}));
