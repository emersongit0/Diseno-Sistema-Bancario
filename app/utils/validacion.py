"""Valida estructura, formatos e importes antes de llamar a MySQL."""
from datetime import datetime, date
from decimal import Decimal, InvalidOperation
import re
from app.utils.errores import ErrorAplicacion


def entero(valor: object, nombre: str, minimo: int = 1, maximo: int = 9999999999) -> int:
    try:
        numero = Decimal(str(valor))
        if not numero.is_finite() or numero != numero.to_integral_value() or not minimo <= numero <= maximo:
            raise ValueError
        return int(numero)
    except (InvalidOperation,ValueError,TypeError):
        raise ErrorAplicacion(f"{nombre}: entero entre {minimo} y {maximo}.") from None


def importe(valor: object, nombre: str, *, minimo: Decimal = Decimal('0.01'), maximo: Decimal = Decimal('999999999999.99')) -> Decimal:
    try:
        numero = Decimal(str(valor))
        if not numero.is_finite() or not minimo <= numero <= maximo or numero != numero.quantize(Decimal('0.01')):
            raise ValueError
        return numero
    except (InvalidOperation,ValueError,TypeError):
        raise ErrorAplicacion(f"{nombre}: importe válido con hasta dos decimales.") from None


def texto(datos: dict, nombre: str, limite: int) -> str:
    valor = datos.get(nombre)
    if not isinstance(valor,str) or not valor.strip() or len(valor.strip()) > limite:
        raise ErrorAplicacion(f"{nombre}: texto obligatorio, máximo {limite} caracteres.")
    return valor.strip()


def cliente(datos: dict, crear: bool = False) -> dict:
    salida = {n:texto(datos,n,limite) for n,limite in [('nombres',100),('apellidos',100),('email',254)]}
    if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+',salida['email']):
        raise ErrorAplicacion("Email inválido.")
    if crear:
        salida['dni'] = texto(datos,'dni',8)
        if not re.fullmatch(r'[0-9]{8}',salida['dni']):
            raise ErrorAplicacion("El DNI debe tener 8 dígitos")
    return salida


def mes_referencia(valor: object) -> date | None:
    if valor is None:
        return None
    if not isinstance(valor,str) or not re.fullmatch(r'\d{4}-\d{2}',valor):
        raise ErrorAplicacion("mes_ref debe tener formato YYYY-MM.")
    try:
        fecha=datetime.strptime(valor,'%Y-%m').date()
        if fecha.year<1000: raise ValueError
        return fecha
    except ValueError:
        raise ErrorAplicacion("mes_ref contiene una fecha inválida.") from None
