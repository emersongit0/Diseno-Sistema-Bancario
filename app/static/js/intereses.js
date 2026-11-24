import {api} from './api.js';
import {$,badge,formulario,toast,aviso,ocupado,mesActual} from './ui.js';
$('#mes-intereses').value=mesActual();
formulario('#form-intereses',async datos=>{const r=await api('/api/intereses/aplicar',{method:'POST',datos});toast(r.mensaje);aviso('#resultado-intereses',r.mensaje);});
$('#actualizar-categorias').onclick=e=>ocupado(e.currentTarget,async()=>{const r=await api('/api/categorias/actualizar',{method:'POST',datos:{}});toast(r.mensaje);aviso('#resultado-categorias',`${r.mensaje}.`);});
formulario('#form-categoria',async datos=>{const r=await api('/api/categoria?'+new URLSearchParams(datos));$('#resultado-categoria').innerHTML=badge(r.datos.categoria);});
