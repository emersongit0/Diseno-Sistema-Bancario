// Una sola petición por llamada: los reintentos permitidos viven en el backend.
export class ErrorAPI extends Error {
  constructor(mensaje, http = 0, codigo = 0) { super(mensaje); this.http = http; this.codigo = codigo; this.incierta = mensaje.includes("No se pudo confirmar la operación"); }
}
let secuencia = 0;
export async function api(ruta, {method = 'GET', datos, signal, objetos = true, accion} = {}) {
  const sec = ++secuencia;
  if (objetos) document.dispatchEvent(new CustomEvent('oracle:inicio',{detail:{sec}}));
  let respuesta;
  try {
    respuesta = await fetch(ruta, {method, signal, headers: {'Accept':'application/json', ...(datos === undefined ? {} : {'Content-Type':'application/json'})}, ...(datos === undefined ? {} : {body:JSON.stringify(datos)})});
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    const escritura = method !== 'GET' && ruta !== '/api/simulador';
    throw new ErrorAPI(escritura ? 'No se pudo confirmar la operación; revisa el estado de cuenta antes de repetirla' : 'No se pudo conectar al servidor. Comprueba que esté iniciado.');
  }
  let contenido;
  try { contenido = await respuesta.json(); } catch {
    const escritura = method !== 'GET' && ruta !== '/api/simulador';
    throw new ErrorAPI(escritura ? 'No se pudo confirmar la operación; revisa el estado de cuenta antes de repetirla' : 'El servidor devolvió una respuesta no válida.', respuesta.status);
  }
  if (objetos && Array.isArray(contenido.objetos_oracle)) document.dispatchEvent(new CustomEvent('oracle:objetos', {detail:{objetos:contenido.objetos_oracle,ruta,method,accion,ok:contenido.ok,sec}}));
  if (!respuesta.ok || !contenido.ok) throw new ErrorAPI(contenido.mensaje || 'No se pudo completar la consulta.', respuesta.status, contenido.codigo);
  return contenido;
}
