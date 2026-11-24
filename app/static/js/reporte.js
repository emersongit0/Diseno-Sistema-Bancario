import {api} from './api.js';
import {$,esc,dinero,badge,fecha,tabla,formulario,seguro,cargarClientes,vacio,parametroID,preseleccionar} from './ui.js';

// Etiquetas de presentación: Oracle conserva sus nombres y reglas originales.
const tiposMovimiento={
 DEPOSITO:'Depósito',RETIRO:'Retiro',TRANSF_ENVIADA:'Transferencia enviada',
 TRANSF_RECIBIDA:'Transferencia recibida',INTERES:'Interés',COMISION:'Comisión',
};
function cuentaHTML(cuenta,i,j){
 return `<details class="reporte-cuenta"><summary class="reporte-cuenta-cabecera"><span class="reporte-identificador"><span class="reporte-etiqueta">Cuenta</span><strong>${esc(cuenta.nro_cuenta)}</strong></span><span class="reporte-cuenta-datos"><span class="reporte-saldo"><span class="reporte-etiqueta">Saldo actual</span><strong>${esc(dinero(cuenta.saldo))}</strong></span>${badge(cuenta.estado)}</span><span class="reporte-flecha" aria-hidden="true"></span></summary><div class="reporte-movimientos"><p class="reporte-movimientos-titulo">Últimos movimientos <span>${cuenta.movimientos.length} ${cuenta.movimientos.length===1?'registro mostrado':'registros mostrados'}</span></p><div id="movimientos-${i}-${j}"></div></div></details>`;
}
function clienteHTML(cliente,i){
 const cantidad=cliente.cuentas.length;
 return `<details class="reporte-cliente" open><summary class="reporte-cliente-cabecera"><span class="reporte-persona"><span class="reporte-avatar" aria-hidden="true">${esc((cliente.nombre||'C').trim().charAt(0))}</span><span class="reporte-identificador"><span class="reporte-etiqueta">Cliente</span><strong>${esc(cliente.nombre)}</strong></span></span><span class="reporte-cliente-datos">${badge(cliente.categoria)}<span>${cantidad} ${cantidad===1?'cuenta':'cuentas'}</span></span><span class="reporte-flecha" aria-hidden="true"></span></summary><div class="reporte-cuentas">${cantidad?cliente.cuentas.map((cuenta,j)=>cuentaHTML(cuenta,i,j)).join(''):'<p class="nota-ayuda">Este cliente todavía no tiene cuentas registradas.</p>'}</div></details>`;
}
formulario('#form-reporte',async datos=>{
 const r=await api('/api/reporte/clientes?'+new URLSearchParams(datos));const clientes=r.datos.json;
 if(!clientes.length){vacio('#arbol-reporte','No hay clientes','Registra un cliente para generar el reporte.');return;}
 $('#arbol-reporte').innerHTML=clientes.map(clienteHTML).join('');
 clientes.forEach((cli,i)=>cli.cuentas.forEach((cuenta,j)=>tabla(`#movimientos-${i}-${j}`,cuenta.movimientos,[
  ['fecha','Fecha',v=>esc(fecha(v))],
  ['tipo','Movimiento',v=>`<span class="reporte-tipo-movimiento">${esc(tiposMovimiento[v]||v)}</span>`],
  ['descripcion','Descripción'],['monto','Monto',v=>esc(dinero(v)),true],
 ],'No hay movimientos dentro del límite consultado.')));
});
seguro(async()=>{await cargarClientes('#cliente',true);preseleccionar('#cliente',parametroID('id_cliente'),'persona titular');});
