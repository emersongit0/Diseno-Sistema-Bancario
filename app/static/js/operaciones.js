import {api} from './api.js';
import {$,$$,dinero,formulario,seguro,toast,cargarCuentas,revisar,invalidarRevision,enlace,continuacion,parametroID,preseleccionar} from './ui.js';
let operacion='depositar',temporizador,version=0,controlador,comisionLista=false,cotizacion=null,enviando=false,incierta=false;
const nombres={depositar:'depósito',retirar:'retiro',transferir:'transferencia'};
function invalidar(){clearTimeout(temporizador);controlador?.abort();version++;comisionLista=false;cotizacion=null;invalidarRevision();}
async function saldo(){const id=$('#cuenta-origen').value;$('#saldo-disponible').textContent=id?'Consultando…':'Selecciona una cuenta';if(!id)return;const r=await api(`/api/cuentas/${id}/saldo`,{objetos:false});if(id===$('#cuenta-origen').value)$('#saldo-disponible').textContent=dinero(r.datos.saldo);}
function cotizar(){
 invalidar();const monto=$('#monto').value;$('#resumen-monto').textContent=dinero(monto||0);$('#comision').textContent='—';
 if(operacion!=='transferir'){$('#total-operacion').textContent=dinero(monto||0);return;}
 $('#total-operacion').textContent='—';const id=$('#cuenta-origen').value;
 if(!id||!$('#monto').checkValidity()||!monto)return;
 const actual=version;$('#comision').textContent='Consultando…';
 temporizador=setTimeout(()=>seguro(async()=>{controlador=new AbortController();const r=await api(`/api/comision?monto=${encodeURIComponent(monto)}&id_cuenta=${encodeURIComponent(id)}`,{signal:controlador.signal,objetos:false});if(actual!==version)return;cotizacion=r.datos;$('#comision').textContent=dinero(cotizacion.comision);$('#total-operacion').textContent=dinero(cotizacion.total_debitar);comisionLista=true;}),300);
}
function cambiarTipo(tipo){if(enviando)return;operacion=tipo;for(const t of $$('[data-operacion]')){t.classList.toggle('activo',t.dataset.operacion===tipo);t.setAttribute('aria-pressed',String(t.dataset.operacion===tipo));}$('#titulo-operacion').textContent=`Registrar ${tipo==='transferir'?'una':'un'} ${nombres[tipo]}`;$('#confirmar-operacion').textContent=`Revisar ${nombres[tipo]} ↗`;$('#campo-destino').hidden=tipo!=='transferir';$('#cuenta-destino').required=tipo==='transferir';$('#fila-comision').hidden=tipo!=='transferir';$('#etiqueta-cuenta').textContent=tipo==='transferir'?'Cuenta de origen':'Cuenta';$('#etiqueta-total').textContent=tipo==='depositar'?'Total a depositar':'Total a debitar';$('#nota-operacion').textContent=tipo==='transferir'?'Cotización previa: MySQL vuelve a validar el saldo y la comisión al confirmar. No se reserva dinero al revisar.':'Revisa los datos antes de confirmar. Abrir la revisión todavía no registra movimientos.';cotizar();}
for(const tab of $$('[data-operacion]'))tab.onclick=()=>cambiarTipo(tab.dataset.operacion);
$('#cuenta-origen').onchange=()=>{cotizar();seguro(saldo);};$('#cuenta-destino').onchange=cotizar;$('#monto').oninput=cotizar;
function datosActuales(){return {tipo:operacion,origen:$('#cuenta-origen').value,destino:$('#cuenta-destino').value,monto:$('#monto').value};}
async function enviar(datos){
 if(enviando)return;enviando=true;for(const b of $$('[data-operacion]'))b.disabled=true;
 try{
  const cuerpo=datos.tipo==='transferir'?{origen:datos.origen,destino:datos.destino,monto:datos.monto}:{id_cuenta:datos.origen,monto:datos.monto};
  const r=await api('/api/'+datos.tipo,{method:'POST',datos:cuerpo});
  toast(r.mensaje);continuacion('#resultado-operacion',r.mensaje,[['Ver movimientos',enlace('/cuentas',{id_cuenta:datos.origen})],['Consultar cuenta',enlace('/cuentas',{id_cuenta:datos.origen})]]);
  const otra=document.createElement('button');otra.type='button';otra.className='boton secundario pequeno';otra.id='otra-operacion';otra.textContent='Realizar otra operación';otra.onclick=()=>{$('#resultado-operacion').replaceChildren();$('#monto').value='';incierta=false;cotizar();$('#monto').focus();};$('#resultado-operacion .acciones-continuar').append(otra);
  $('#monto').value='';cotizar();
  await seguro(async()=>{await cargarCuentas(['#cuenta-origen','#cuenta-destino'],{soloActivas:true});await saldo();});
 }catch(error){
  incierta=Boolean(error.incierta);continuacion('#resultado-operacion',error.message,[['Revisar movimientos de origen',enlace('/cuentas',{id_cuenta:datos.origen})],['Revisar movimientos de destino',enlace('/cuentas',{id_cuenta:datos.destino||datos.origen})]],true);
  if(incierta){const b=document.createElement('button');b.type='button';b.className='boton secundario pequeno';b.id='habilitar-otra';b.textContent='Ya revisé los movimientos: preparar otra operación';b.onclick=()=>{incierta=false;$('#monto').value='';cotizar();toast('Selecciona los datos de la nueva operación.');b.remove();};$('#resultado-operacion .acciones-continuar').append(b);}
  throw error;
 }finally{enviando=false;for(const b of $$('[data-operacion]'))b.disabled=false;}
}
formulario('#form-operacion',async()=>{
 if(enviando)return;if(incierta)throw new Error('La operación anterior tiene resultado incierto. Revisa los movimientos y usa la acción de preparar otra operación.');
 const datos=datosActuales();if(datos.tipo==='transferir'&&datos.origen===datos.destino)throw new Error('Selecciona una cuenta de destino diferente.');if(datos.tipo==='transferir'&&!comisionLista)throw new Error('Espera la cotización de comisión antes de revisar.');
 const foto=JSON.stringify(datos),v=version;const filas={cuenta:$('#cuenta-origen').selectedOptions[0].textContent,monto:dinero(datos.monto)};
 if(datos.tipo==='transferir'){filas.destino=$('#cuenta-destino').selectedOptions[0].textContent;filas['comisión cotizada']=dinero(cotizacion.comision);filas['total cotizado a debitar']=dinero(cotizacion.total_debitar);}
 await revisar({titulo:'Revisar '+nombres[datos.tipo],filas,nota:datos.tipo==='transferir'?'La cotización no reserva saldo ni comisión. MySQL revalida al confirmar y el resultado final informa el cobro efectivo.':'Solo al confirmar se registra la operación.',confirmar:'Confirmar '+nombres[datos.tipo],vigente:()=>v===version&&foto===JSON.stringify(datosActuales())&&!incierta,ejecutar:()=>enviar(datos)});
});
seguro(async()=>{await cargarCuentas(['#cuenta-origen','#cuenta-destino'],{soloActivas:true});const tipo=new URLSearchParams(location.search).get('tipo');if(tipo){if(Object.hasOwn(nombres,tipo))cambiarTipo(tipo);else toast('El tipo de operación del enlace no es válido. Selecciona una operación.',true);}preseleccionar('#cuenta-origen',parametroID('id_cuenta'));});
