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
  el.innerHTML = `<div class="tabla-contenedor"><table><thead><tr>${columnas.map(c=>`<th scope="col">${esc(c[1])}</th>`).join('')}</tr></thead><tbody>${filas.map(f=>`<tr>${columnas.map(c=>`<td${c[3] ? ' class="importe"' : ''}>${c[2] ? c[2](f[c[0]],f) : esc(f[c[0]])}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}
export function toast(mensaje, error = false) {
  const el = document.createElement('div'); el.className = 'toast' + (error ? ' error' : ''); el.setAttribute('role',error?'alert':'status');
  const texto = document.createElement('span'); texto.textContent = mensaje;
  const cerrar = document.createElement('button'); cerrar.type = 'button'; cerrar.textContent = '×'; cerrar.setAttribute('aria-label','Cerrar aviso'); cerrar.onclick = () => el.remove();
  el.append(texto,cerrar); $('#toasts').append(el); if (!error) setTimeout(()=>el.remove(),7000);
}
export async function seguro(accion) { try { return await accion(); } catch(error) { if (error.name !== 'AbortError') toast(error.message,true); return undefined; } }
export async function ocupado(boton, accion) { if (boton.disabled) return; const texto = boton.textContent; boton.disabled = true; boton.textContent = 'Procesando…'; try { return await seguro(accion); } finally { boton.textContent = texto; boton.disabled = false; } }
export function formulario(selector, accion) { const form = $(selector); form.addEventListener('submit',evento=>{ evento.preventDefault(); if (!form.reportValidity()) return; ocupado($('[type="submit"]',form),()=>accion(Object.fromEntries(new FormData(form)),form)); }); }
export function aviso(selector, mensaje, error = false) { $(selector).innerHTML = `<div class="aviso${error?' error':''}">${esc(mensaje)}</div>`; }
export function detalle(titulo, html) { $('#titulo-detalle').textContent = titulo; $('#contenido-detalle').innerHTML = html; $('#modal-detalle').showModal(); }
export function resumenHTML(datos) { return Object.entries(datos || {}).map(([clave,valor])=>`<div class="resumen-linea"><span>${esc(clave.replaceAll('_',' '))}</span><strong>${esc(valor ?? '—')}</strong></div>`).join(''); }
export function movimientosTabla(contenedor, filas) { const columnas = [['fecha','Fecha',v=>esc(fecha(v))],['tipo','Movimiento',v=>badge(v)],['descripcion','Descripción'],['monto','Monto',v=>esc(dinero(v)),true]]; if (filas.some(f=>Object.hasOwn(f,'saldo_posterior'))) columnas.push(['saldo_posterior','Saldo posterior',v=>esc(dinero(v)),true]); tabla(contenedor,filas,columnas); }
export async function cargarCuentas(selectores, {opcional = false, soloActivas = false} = {}) {
  const r = await api('/api/cuentas/opciones');
  for (const selector of selectores) {
    const select = $(selector), anterior = select.value; select.replaceChildren(new Option(opcional?'Ingresar valores manualmente':'Selecciona una cuenta',''));
    for (const c of r.datos) { const op = new Option(`${c.nro_cuenta} · ${dinero(c.saldo)}${c.estado==='BLOQUEADA'?' · Bloqueada':''}`,c.id_cuenta); op.disabled = soloActivas && c.estado !== 'ACTIVA'; select.append(op); }
    if ([...select.options].some(x=>x.value===anterior && !x.disabled)) select.value = anterior;
  }
  return r.datos;
}
export async function cargarClientes(selector, todos = false) { const r = await api('/api/clientes'); const select = $(selector); select.replaceChildren(new Option(todos?'Todos los clientes':'Selecciona un cliente','')); for (const c of r.datos) select.append(new Option(`${c.nombres} ${c.apellidos} · ${c.dni}`,c.id_cliente)); return r.datos; }
export function grafico(proyeccion) {
  if (!proyeccion?.length) return '';
  const valores = proyeccion.map(x=>Number(x.saldo)); const minimo = Math.min(...valores), maximo = Math.max(...valores), rango = maximo-minimo || 1;
  const puntos = valores.map((v,i)=>`${30+i/Math.max(valores.length-1,1)*520},${180-(v-minimo)/rango*145}`).join(' ');
  return `<svg class="grafico" viewBox="0 0 580 220" role="img" aria-label="Proyección del saldo desde ${esc(dinero(valores[0]))} hasta ${esc(dinero(valores.at(-1)))}"><line x1="30" y1="180" x2="550" y2="180" stroke="#dce5d6"/><line x1="30" y1="107" x2="550" y2="107" stroke="#eef2e9"/><polyline points="${puntos}" fill="none" stroke="currentColor" stroke-width="3" stroke-linejoin="round"/><text x="30" y="209" font-size="11" fill="#82907c">Mes 0</text><text x="490" y="209" font-size="11" fill="#82907c">Mes ${esc(proyeccion.at(-1).mes)}</text></svg>`;
}

// Panel compartido: los chips se obtienen de las respuestas de la API.
const usados = new Set(); const disponibles = new Set(JSON.parse($('#objetos-pagina').textContent));
let versionCodigo = 0;
async function cargarCodigo(nombre) { const version = ++versionCodigo; $('#contenido-codigo').textContent = 'Cargando código…'; $('#archivo-codigo').textContent = ''; $('#copiar-codigo').disabled = true; try { const r = await api('/api/codigo/'+encodeURIComponent(nombre),{objetos:false}); if (version !== versionCodigo) return; $('#contenido-codigo').textContent = r.datos.codigo; $('#archivo-codigo').textContent = r.datos.tipo+' · '+r.datos.archivo; $('#copiar-codigo').disabled = false; } catch(error) { if (version !== versionCodigo) return; $('#contenido-codigo').textContent = 'No se pudo cargar el código. Selecciona de nuevo un objeto para intentarlo.'; toast(error.message,true); } }
function verCodigo(nombre) { const select = $('#objeto-codigo'); select.replaceChildren(...[...new Set([...usados,...disponibles])].map(n=>new Option(n,n))); if (!select.options.length) { toast('Realiza una consulta para conocer los objetos.',true); return; } select.value = nombre || select.options[0].value; if (!$('#modal-codigo').open) $('#modal-codigo').showModal(); cargarCodigo(select.value); }
document.addEventListener('oracle:objetos',evento=>{ for (const n of evento.detail) { usados.add(n); disponibles.add(n); } if (!usados.size) return; $('#objetos-oracle').replaceChildren(...[...usados].map(n=>{const b=document.createElement('button'); b.type='button';b.className='chip';b.textContent=n;b.onclick=()=>verCodigo(n);return b;})); });
$('#ver-codigo').onclick = ()=>verCodigo(); $('#objeto-codigo').onchange = evento=>cargarCodigo(evento.target.value);
$('#copiar-codigo').onclick = ()=>seguro(async()=>{if (!navigator.clipboard) throw new Error('Selecciona el código y cópialo con Ctrl+C.'); await navigator.clipboard.writeText($('#contenido-codigo').textContent); toast('Código copiado.');});
document.addEventListener('click',evento=>{const b=evento.target.closest('[data-cerrar]'); if(b) document.getElementById(b.dataset.cerrar)?.close();});
const menu = $('#menu-movil'); const mediaMovil = window.matchMedia('(max-width:700px)'); const sincronizarMenu = ()=>{ $('#barra-lateral').inert = mediaMovil.matches && !$('#barra-lateral').classList.contains('abierta'); }; mediaMovil.addEventListener('change',sincronizarMenu); sincronizarMenu(); menu.onclick=()=>{const abierta=$('#barra-lateral').classList.toggle('abierta');menu.setAttribute('aria-expanded',String(abierta));sincronizarMenu();};
document.addEventListener('keydown',e=>{if(e.key==='Escape'){$('#barra-lateral').classList.remove('abierta');menu.setAttribute('aria-expanded','false');sincronizarMenu();}});
document.addEventListener('click',e=>{if($('#barra-lateral').classList.contains('abierta') && !e.target.closest('#barra-lateral,#menu-movil')){$('#barra-lateral').classList.remove('abierta');menu.setAttribute('aria-expanded','false');sincronizarMenu();}});
