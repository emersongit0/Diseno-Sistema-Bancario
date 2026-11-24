// Selector de periodo mensual independiente del popup nativo del navegador.
export function selectorPeriodo(selector){
 const origen=document.querySelector(selector);const contenedor=document.createElement('div');contenedor.className='selector-periodo';
 const meses=['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
 const campoMes=document.createElement('div'),campoAnio=document.createElement('div');campoMes.className=campoAnio.className='periodo-subcampo';
 const mes=document.createElement('select');mes.id=origen.id+'-mes';mes.required=true;
 meses.forEach((nombre,i)=>mes.append(new Option(nombre,String(i+1).padStart(2,'0'))));
 const anio=document.createElement('input');anio.type='number';anio.id=origen.id+'-anio';anio.min='1';anio.max='9998';anio.step='1';anio.required=true;anio.inputMode='numeric';
 for(const [campo,control,texto] of [[campoMes,mes,'Mes'],[campoAnio,anio,'Año']]){const label=document.createElement('label');label.htmlFor=control.id;label.textContent=texto;campo.append(label,control);}
 const ahora=()=>{const partes=new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit'}).formatToParts(new Date());return partes.find(p=>p.type==='year').value+'-'+partes.find(p=>p.type==='month').value;};
 function sincronizar(){origen.value=anio.checkValidity()&&mes.value?String(Number(anio.value)).padStart(4,'0')+'-'+mes.value:'';origen.dispatchEvent(new Event('change',{bubbles:true}));}
 function asignar(valor){const [a,m]=valor.split('-');anio.value=a;mes.value=m;sincronizar();}
 const actual=document.createElement('button');actual.type='button';actual.className='boton secundario';actual.textContent='Mes actual';actual.onclick=()=>asignar(ahora());
 mes.onchange=sincronizar;anio.oninput=sincronizar;anio.onchange=sincronizar;
 contenedor.append(campoMes,campoAnio,actual);origen.after(contenedor);asignar(origen.value||ahora());
 return {valor:()=>origen.value};
}
