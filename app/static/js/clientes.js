import {api} from './api.js';
import {$,esc,badge,tabla,seguro,ocupado,formulario,toast,detalle,resumenHTML,dinero,enlace,continuacion,carga} from './ui.js';
let clientes=[];
function mostrar(){
 const busqueda=$('#buscar').value.toLocaleLowerCase('es');const filas=clientes.filter(c=>`${c.nombres} ${c.apellidos} ${c.dni} ${c.email}`.toLocaleLowerCase('es').includes(busqueda));
 $('#contador').textContent=`${filas.length} clientes`;
 tabla('#tabla-clientes',filas,[['dni','DNI'],['nombres','Cliente',(v,c)=>`<strong>${esc(c.nombres)} ${esc(c.apellidos)}</strong>`],['email','Correo'],['categoria','Categoría',v=>badge(v)],['id_cliente','Acciones',v=>`<div class="acciones-inline"><button type="button" class="boton secundario pequeno" data-editar="${Number(v)}">Editar</button><button type="button" class="boton secundario pequeno" data-resumen="${Number(v)}">Ver resumen</button><a class="boton secundario pequeno" href="${enlace('/cuentas',{id_cliente:v})}">Ver cuentas ↗</a></div>`]]);
}
async function cargar(auxiliar=false){carga('#tabla-clientes');clientes=(await api('/api/clientes',{objetos:!auxiliar})).datos;mostrar();}
function nuevo(){const form=$('#form-cliente');form.reset();form.querySelector('.form-error')?.remove();form.elements.id_cliente.value='';form.elements.dni.disabled=false;$('#titulo-cliente').textContent='Nuevo cliente';$('#modal-cliente').showModal();}
$('#nuevo-cliente').onclick=nuevo;$('#buscar').oninput=mostrar;
$('#tabla-clientes').onclick=e=>{
 const editar=e.target.closest('[data-editar]');
 if(editar){const c=clientes.find(c=>String(c.id_cliente)===editar.dataset.editar);const form=$('#form-cliente');form.querySelector('.form-error')?.remove();for(const n of ['id_cliente','dni','nombres','apellidos','email'])form.elements[n].value=c[n];form.elements.dni.disabled=true;$('#titulo-cliente').textContent='Editar cliente';$('#modal-cliente').showModal();}
 const boton=e.target.closest('[data-resumen]');
 if(boton)ocupado(boton,async()=>{const id=boton.dataset.resumen;const r=await api(`/api/clientes/${id}/resumen`);const d=r.datos.json;const desactualizada=d.nivel!==d.categoria_registrada;
 detalle('Relación del cliente con el banco',resumenHTML({cliente:d.nombre,'saldo total':dinero(d.saldo_total),'categoría registrada':d.categoria_registrada,'nivel calculado por saldo':d.nivel,'siguiente nivel':d.siguiente_categoria||'Nivel máximo','falta para el siguiente nivel':dinero(d.falta_para_siguiente)})+(desactualizada?'<div class="aviso">La categoría registrada difiere del nivel calculado. Actualiza las categorías desde Administración.</div>':'<p class="nota-ayuda">La categoría registrada coincide con el nivel calculado.</p>')+`<div class="acciones-continuar"><a class="boton secundario" href="${enlace('/cuentas',{id_cliente:id})}">Ver cuentas</a><a class="boton secundario" href="${enlace('/reporte',{id_cliente:id})}">Reporte del cliente</a>${desactualizada?'<a class="boton secundario" href="/intereses">Actualizar categorías</a>':''}</div>`);
 });
};
formulario('#form-cliente',async(datos)=>{const id=datos.id_cliente;delete datos.id_cliente;const r=await api(id?`/api/clientes/${id}`:'/api/clientes',{method:id?'PUT':'POST',datos});$('#modal-cliente').close();toast(r.mensaje);const identificador=id||r.datos.id_cliente;continuacion('#resultado-cliente',r.mensaje,[['Abrir cuenta para este cliente',enlace('/cuentas',{id_cliente:identificador,abrir:1})],['Ver cuentas',enlace('/cuentas',{id_cliente:identificador})]]);await cargar(true);});
seguro(async()=>{await cargar();if(new URLSearchParams(location.search).get('nuevo')==='1')nuevo();});
