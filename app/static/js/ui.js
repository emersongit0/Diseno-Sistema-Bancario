import {api} from './api.js';
export const $ = (selector, raiz = document) => raiz.querySelector(selector);
export const $$ = (selector, raiz = document) => [...raiz.querySelectorAll(selector)];
export const esc = valor => String(valor ?? '').replace(/[&<>"']/g, letra => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[letra]));
export const dinero = valor => valor === null || valor === undefined ? '—' : new Intl.NumberFormat('es-PE',{style:'currency',currency:'PEN',minimumFractionDigits:2}).format(Number(valor));
export const numero = valor => new Intl.NumberFormat('es-PE').format(Number(valor || 0));
export function fecha(valor) { if (!valor) return '—'; const d = new Date(valor); return Number.isNaN(d.getTime()) ? String(valor) : new Intl.DateTimeFormat('es-PE',{dateStyle:'medium',timeStyle:'short'}).format(d); }
export function mesActual() { const p = new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit'}).formatToParts(new Date()); return p.find(x=>x.type==='year').value + '-' + p.find(x=>x.type==='month').value; }
export const badge = valor => `<span class="badge ${['ACTIVA','BLOQUEADA','GOLD','PREMIUM','BASICO','ERROR'].includes(valor) ? esc(valor.toLowerCase()) : ''}">${esc(valor)}</span>`;
export function vacio(contenedor, titulo = 'No hay registros todavía', descripcion = 'Los resultados aparecerán aquí.') { const el = typeof contenedor === 'string' ? $(contenedor) : contenedor; el.innerHTML = `<div class="vacio"><h3>${esc(titulo)}</h3><p>${esc(descripcion)}</p></div>`; }
export function tabla(contenedor, filas, columnas, mensaje = 'No hay registros para esta consulta.') {
  const el = typeof contenedor === 'string' ? $(contenedor) : contenedor;
  if (!filas?.length) { vacio(el,'Sin resultados',mensaje); return; }
  el.innerHTML = `<div class="tabla-contenedor" role="region" aria-label="Tabla de resultados" tabindex="0"><table><thead><tr>${columnas.map(c=>`<th scope="col"${c[3] ? ' class="'+(c[3] === 'centro' ? 'centrado' : 'importe')+'"' : ''}>${esc(c[1])}</th>`).join('')}</tr></thead><tbody>${filas.map(f=>`<tr>${columnas.map(c=>`<td${c[3] ? ' class="'+(c[3] === 'centro' ? 'centrado' : 'importe')+'"' : ''}>${c[2] ? c[2](f[c[0]],f) : esc(f[c[0]])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}
export function toast(mensaje, error = false) {
  const el = document.createElement('div'); el.className = 'toast' + (error ? ' error' : ''); el.setAttribute('role',error?'alert':'status');
  const texto = document.createElement('span'); texto.textContent = mensaje;
  const cerrar = document.createElement('button'); cerrar.type = 'button'; cerrar.textContent = '×'; cerrar.setAttribute('aria-label','Cerrar aviso'); cerrar.onclick = () => el.remove();
  el.append(texto,cerrar); $('#toasts').append(el); if (!error) setTimeout(()=>el.remove(),7000);
}
export async function seguro(accion) { try { return await accion(); } catch(error) { if (error.name !== 'AbortError') {toast(error.message,true);for(const el of $$('.carga')){el.classList.add('form-error');el.textContent=error.message+' Puedes usar Actualizar o recargar la página para volver a consultar.';el.setAttribute('role','alert');}} return undefined; } }
export async function ocupado(boton, accion) { if (boton.disabled) return; const texto = boton.textContent; boton.disabled = true; boton.textContent = 'Procesando…'; try { return await seguro(accion); } finally { boton.textContent = texto; boton.disabled = false; } }
export function formulario(selector, accion) {
  const form = $(selector);
  form.addEventListener('submit',evento=>{evento.preventDefault();if(!form.reportValidity())return;
    ocupado($('[type="submit"]',form),async()=>{form.querySelector('.form-error')?.remove();try{return await accion(Object.fromEntries(new FormData(form)),form);}catch(error){const aviso=document.createElement('p');aviso.className='form-error';aviso.setAttribute('role','alert');aviso.textContent=error.message+' '+(error.incierta?'Revisa los movimientos antes de volver a confirmar.':'Revisa los datos y vuelve a intentarlo; se conservaron los valores escritos.');form.append(aviso);throw error;}});
  });
}
export function aviso(selector, mensaje, error = false) { $(selector).innerHTML = `<div class="aviso${error?' error':''}">${esc(mensaje)}</div>`; }
export function detalle(titulo, html) { $('#titulo-detalle').textContent = titulo; $('#contenido-detalle').innerHTML = html; $('#modal-detalle').showModal(); }
export function resumenHTML(datos) { return Object.entries(datos || {}).map(([clave,valor])=>`<div class="resumen-linea"><span>${esc(clave.replaceAll('_',' '))}</span><strong>${esc(valor ?? '—')}</strong></div>`).join(''); }
export function movimientosTabla(contenedor, filas) { const columnas = [['fecha','Fecha',v=>esc(fecha(v))],['tipo','Movimiento',v=>badge(v)],['descripcion','Descripción'],['monto','Monto',v=>esc(dinero(v)),true]]; if (filas.some(f=>Object.hasOwn(f,'saldo_posterior'))) columnas.push(['saldo_posterior','Saldo posterior',v=>esc(dinero(v)),true]); tabla(contenedor,filas,columnas); }
export async function cargarCuentas(selectores, {opcional = false, soloActivas = false} = {}) {
  const r = await api('/api/cuentas/opciones',{objetos:false});
  for (const selector of selectores) {
    const select = $(selector), anterior = select.value; select.replaceChildren(new Option(opcional?'Ingresar valores manualmente':'Selecciona una cuenta',''));
    for (const c of r.datos) { const op = new Option(`${c.nro_cuenta} · ${dinero(c.saldo)}${c.estado==='BLOQUEADA'?' · Bloqueada':''}`,c.id_cuenta); op.disabled = soloActivas && c.estado !== 'ACTIVA'; select.append(op); }
    if ([...select.options].some(x=>x.value===anterior && !x.disabled)) select.value = anterior;
  }
  return r.datos;
}
export async function cargarClientes(selector, todos = false) { const r = await api('/api/clientes',{objetos:false}); const select = $(selector); select.replaceChildren(new Option(todos?'Todos los clientes':'Selecciona un cliente','')); for (const c of r.datos) select.append(new Option(`${c.nombres} ${c.apellidos} · ${c.dni}`,c.id_cliente)); return r.datos; }
export function grafico(proyeccion){
 if(!proyeccion?.length)return '';
 const filas=proyeccion.map(f=>({mes:Number(f.mes),saldo:Number(f.saldo)}));
 if(filas.some(f=>!Number.isFinite(f.mes)||!Number.isFinite(f.saldo)))return '';
 const izquierda=112,derecha=650,arriba=28,abajo=248;const maximo=Math.max(0,...filas.map(f=>f.saldo));
 const magnitud=10**Math.floor(Math.log10(maximo||1));const paso=Math.max(1,Math.ceil((maximo||1)/4/magnitud*10)/10*magnitud);const techo=paso*4;
 const ultimoMes=filas.at(-1).mes;const x=m=>izquierda+(ultimoMes?m/ultimoMes:0)*(derecha-izquierda),y=v=>abajo-v/techo*(abajo-arriba);
 const puntos=filas.map(f=>`${x(f.mes)},${y(f.saldo)}`).join(' ');
 const rejilla=Array.from({length:5},(_,i)=>{const v=paso*i,alto=y(v);return `<line x1="${izquierda}" y1="${alto}" x2="${derecha}" y2="${alto}" stroke="#e1e9db"/><text x="${izquierda-12}" y="${alto+4}" text-anchor="end" fill="#66775f" font-size="12">${esc(dinero(v))}</text>`;}).join('');
 const meses=[...new Set([0,Math.round(ultimoMes/2),ultimoMes])];
 const etiquetas=meses.map(m=>`<text x="${x(m)}" y="${abajo+25}" text-anchor="${m===0?'start':m===ultimoMes?'end':'middle'}" fill="#66775f" font-size="12">Mes ${m}</text>`).join('');
 const marcadores=filas.map((f,i)=>`<circle cx="${x(f.mes)}" cy="${y(f.saldo)}" r="${i===0||i===filas.length-1?4:2}" fill="currentColor"><title>Mes ${f.mes}: ${esc(dinero(f.saldo))}</title></circle>`).join('');
 return `<div class="grafico-contenedor"><svg class="grafico grafico-proyeccion" viewBox="0 0 700 295" role="img" aria-label="Proyección mensual en soles, escala desde cero. Inicio ${esc(dinero(filas[0].saldo))}; final ${esc(dinero(filas.at(-1).saldo))} en el mes ${ultimoMes}.">${rejilla}<polygon points="${izquierda},${abajo} ${puntos} ${x(ultimoMes)},${abajo}" fill="currentColor" opacity=".07"/><polyline data-serie-saldos="true" points="${puntos}" fill="none" stroke="currentColor" stroke-width="3" stroke-linejoin="round"/>${marcadores}${etiquetas}</svg></div>`;
}

import {iniciarMySQL} from './oracle.js';
iniciarMySQL();

document.addEventListener('click',evento=>{const b=evento.target.closest('[data-cerrar]'); if(b) document.getElementById(b.dataset.cerrar)?.close();});
const menu = $('#menu-movil'); const mediaMovil = window.matchMedia('(max-width:700px)'); const sincronizarMenu = ()=>{ $('#barra-lateral').inert = mediaMovil.matches && !$('#barra-lateral').classList.contains('abierta'); }; mediaMovil.addEventListener('change',sincronizarMenu); sincronizarMenu(); menu.onclick=()=>{const abierta=$('#barra-lateral').classList.toggle('abierta');menu.setAttribute('aria-expanded',String(abierta));sincronizarMenu();};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&$('#barra-lateral').classList.contains('abierta')){$('#barra-lateral').classList.remove('abierta');menu.setAttribute('aria-expanded','false');sincronizarMenu();menu.focus();}});
document.addEventListener('click',e=>{if($('#barra-lateral').classList.contains('abierta') && !e.target.closest('#barra-lateral,#menu-movil')){$('#barra-lateral').classList.remove('abierta');menu.setAttribute('aria-expanded','false');sincronizarMenu();}});

// Contexto de navegación: solo selecciona opciones existentes, nunca escribe al abrir URL.
export const enlace = (ruta, parametros = {}) => ruta + (Object.keys(parametros).length ? '?' + new URLSearchParams(parametros) : '');
export function parametroID(nombre) {
  const valores=new URLSearchParams(location.search).getAll(nombre);
  if(!valores.length)return null;
  if(valores.length!==1 || !/^[1-9][0-9]{0,9}$/.test(valores[0])){toast(`El parámetro ${nombre} no es válido. Puedes elegir manualmente.`,true);return null;}
  return valores[0];
}
export function preseleccionar(selector, valor, nombre = 'cuenta') {
  if(valor===null)return false;
  const select=$(selector),opcion=[...select.options].find(o=>o.value===String(valor)&&!o.disabled);
  if(!opcion){toast(`La ${nombre} del enlace no está disponible. Selecciona otra opción.`,true);return false;}
  select.value=String(valor);select.dispatchEvent(new Event('change',{bubbles:true}));return true;
}
export function continuacion(selector, mensaje, enlaces, error = false) {
  $(selector).innerHTML=`<div class="aviso estado-resultado${error?' error':''}">${esc(mensaje)}</div><div class="acciones-continuar">${enlaces.map(([titulo,ruta])=>`<a class="boton secundario pequeno" href="${esc(ruta)}">${esc(titulo)} ↗</a>`).join('')}</div>`;
}
export function carga(selector, texto = 'Consultando datos…') {$(selector).innerHTML=`<div class="carga" role="status">${esc(texto)}</div>`;}
export async function revisar({titulo,filas,nota='',confirmar='Confirmar',ejecutar,vigente=()=>true}) {
  const modal=$('#modal-revision');
  if(modal.open)return;
  $('#titulo-revision').textContent=titulo;$('#contenido-revision').innerHTML=`<div class="revision-datos">${resumenHTML(filas)}</div>`;
  $('#nota-revision').textContent=nota;const boton=$('#aceptar-revision');boton.textContent=confirmar;boton.disabled=false;
  boton.onclick=()=>ocupado(boton,async()=>{if(!vigente()){modal.close();throw new Error('Los datos cambiaron. Revisa nuevamente antes de confirmar.');}
    const controles=$$('button',modal);controles.filter(b=>b!==boton).forEach(b=>b.disabled=true);
    const evitarEscape=e=>e.preventDefault();modal.addEventListener('cancel',evitarEscape);
    try {await ejecutar();modal.close();} catch(error) {modal.close();throw error;} finally {controles.filter(b=>b!==boton).forEach(b=>b.disabled=false);modal.removeEventListener('cancel',evitarEscape);}
  });modal.showModal();
}
export function invalidarRevision() {if($('#modal-revision').open&&!$('#aceptar-revision').disabled)$('#modal-revision').close();}
