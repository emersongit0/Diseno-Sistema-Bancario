import {api} from './api.js';
import {$,esc,dinero,numero,badge,tabla,seguro,ocupado} from './ui.js';
async function cargar() {
  const salud = api('/api/salud',{objetos:false}).then(()=>{$('#estado-bd').innerHTML='<span class="punto"></span>Base de datos conectada';$('#estado-bd').classList.remove('error');}).catch(error=>{$('#estado-bd').innerHTML='<span class="punto"></span>Base de datos desconectada';$('#estado-bd').classList.add('error');$('#estado-bd').title=error.message;});
  const r = await api('/api/cuentas'); const filas = r.datos;
  $('#saldo-total').textContent=dinero(filas.reduce((s,c)=>s+Number(c.saldo),0)); $('#total-cuentas').textContent=numero(filas.length);$('#cuentas-activas').textContent=numero(filas.filter(c=>c.estado==='ACTIVA').length);$('#total-movimientos').textContent=numero(filas.reduce((s,c)=>s+Number(c.cantidad_movimientos),0));
  $('#distribucion').innerHTML=['BASICO','GOLD','PREMIUM'].map(c=>{const n=filas.filter(f=>f.categoria===c).length;return `<div><div style="display:flex;justify-content:space-between;font-size:11px"><span>${badge(c)}</span><span>${n} cuentas</span></div><div class="mini-barra"><span style="width:${filas.length?n/filas.length*100:0}%"></span></div></div>`;}).join('');
  tabla('#tabla-cuentas',filas.slice(0,6),[['nro_cuenta','Cuenta',(v,c)=>`<a class="enlace-texto" href="/cuentas?id_cuenta=${Number(c.id_cuenta)}">${esc(v)} ↗</a>`],['titular','Titular'],['categoria','Categoría',v=>badge(v)],['saldo','Saldo',v=>esc(dinero(v)),true],['estado','Estado',v=>badge(v)]]);
  await salud;
}
$('#actualizar').onclick=e=>ocupado(e.currentTarget,cargar); seguro(cargar);
