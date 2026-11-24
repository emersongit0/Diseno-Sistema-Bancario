"""Mapeo central de errores; nunca expone mensajes técnicos fuera del laboratorio."""
import re

MAPA = {
    -20001: (409,"Saldo insuficiente"), -20002: (404,"Cuenta inexistente"),
    -20003: (409,"Cuenta bloqueada"), -20004: (400,"Monto inválido"),
    -20005: (400,"No se puede transferir a la misma cuenta"),
    -20006: (404,"Cliente inexistente"), -20007: (400,"Estado de cuenta inválido"),
    -1: (409,"Registro duplicado"), -2291: (400,"Referencia inexistente (cliente o cuenta no existe)"),
    -2292: (409,"Tiene registros relacionados"), -2290: (400,"Restricción violada"),
    -60: (409,"Conflicto de concurrencia, intenta de nuevo"),
    -30006: (409,"Cuenta ocupada por otra operación, intenta de nuevo"),
}
for _codigo in (-1400,-1438,-12899,-1722):
    MAPA[_codigo] = (400,"Dato faltante o con formato o tamaño inválido")
RESTRICCIONES = {
    "UQ_CLIENTES_DNI":"DNI ya registrado", "UQ_CLIENTES_EMAIL":"Email ya registrado",
    "CK_CLIENTES_DNI":"El DNI debe tener 8 dígitos", "CK_CUENTAS_SALDO":"La operación dejaría saldo negativo",
    "CK_CUENTAS_TIPO":"Tipo de cuenta inválido",
    "CK_LIMITES_ORDEN":"Premium debe ser mayor que Gold y ambos límites deben ser positivos",
}
CONEXION = "No se pudo conectar a la base de datos, revisa tu internet"
INCIERTA = "No se pudo confirmar la operación; revisa el estado de cuenta antes de repetirla"

class ErrorAplicacion(Exception):
    """Error validado que puede presentarse al usuario."""
    def __init__(self, mensaje: str, http: int = 400, codigo: int = -20004):
        super().__init__(mensaje)
        self.mensaje, self.http, self.codigo = mensaje, http, codigo


def datos_error(error: Exception) -> tuple[int, str, str]:
    """Extrae código y detalle de excepciones Oracle o de objetos simulados."""
    detalle = error.args[0] if error.args else error
    codigo = getattr(detalle,"code",0)
    texto = str(getattr(detalle,"message",detalle))
    completo = str(getattr(detalle,"full_code",""))
    if not codigo:
        match = re.search(r"ORA-(\d{5})",texto)
        codigo = int(match[1]) if match else 0
    return -abs(int(codigo or 0)), texto, completo


def es_conexion(error: Exception) -> bool:
    """Reconoce las caídas recuperables definidas en la especificación."""
    codigo,texto,completo = datos_error(error)
    return codigo in (-3113,-3114) or any(x in texto or x in completo for x in ("DPY-4011","DPY-6005"))


def restriccion(texto: str) -> str | None:
    """Extrae el segundo grupo ESQUEMA.RESTRICCION."""
    match = re.search(r"\(([^.]+)\.([^)]+)\)",texto)
    return match[2].strip('"').upper() if match else None


def ocultar_esquema(texto: str) -> str:
    """Oculta prefijos en restricciones y en detalles extendidos del laboratorio."""
    texto = re.sub(r"\(([^.()]+)\.([^)]+)\)",r"(\2)",texto)
    return re.sub(r'\b[A-Za-z][A-Za-z0-9_$#]*\.([A-Z][A-Z0-9_$#]*)\b',r'\1',texto)


def mapear(codigo: int, texto: str = "", *, negocio: bool = False) -> tuple[int,str]:
    """Mapea tanto SQLCODE OUT como excepciones del controlador."""
    http,mensaje = MAPA.get(codigo,(500,"Error interno"))
    if negocio and -20007 <= codigo <= -20001 and texto:
        return http, re.sub(r"^ORA-\d+:\s*","",texto).strip()
    if codigo in (-1,-2290):
        mensaje = RESTRICCIONES.get(restriccion(texto),mensaje)
    return http,mensaje


def traducir(error: Exception, durante_escritura: bool = False) -> tuple[int,int,str]:
    """Traduce sin revelar credenciales, DSN ni SQLERRM."""
    if isinstance(error,ErrorAplicacion):
        return error.http,error.codigo,error.mensaje
    codigo,texto,_ = datos_error(error)
    if es_conexion(error):
        return 503,codigo,INCIERTA if durante_escritura else CONEXION
    http,mensaje = mapear(codigo,texto)
    return http,codigo,mensaje
