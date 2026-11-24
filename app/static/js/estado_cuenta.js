import {api} from './api.js';
import {$,esc,dinero,fecha,badge,tabla,formulario,seguro,cargarCuentas,mesActual} from './ui.js';
$('#mes').value=mesActual();
formulario('#form-estado',async datos=>{const [anio,mes]=datos.mes_ref.split('-');const r=await api(`/api/estado-cuenta/${datos.id_cuenta}?anio=${anio}&mes=${mes}`);const filas=r.datos;tabla('#tabla-estado',filas,[['fecha','Fecha',v=>esc(fecha(v))],['tipo','Movimiento',v=>badge(v)],['descripcion','Descripción'],['monto','Monto',v=>esc(dinero(v)),true],['saldo_acumulado','Saldo acumulado',v=>esc(dinero(v)),true]],'Esta cuenta no registra movimientos en el mes seleccionado.');$('#resumen-estado').innerHTML=`<span class="texto-suave">${filas.length} movimientos · ${esc(datos.mes_ref)}</span>`;});
seguro(()=>cargarCuentas(['#cuenta']));
