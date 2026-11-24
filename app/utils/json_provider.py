"""Serialización consistente de fechas y cantidades Oracle."""
from datetime import date, datetime
from decimal import Decimal
from flask.json.provider import DefaultJSONProvider

class BancoJSONProvider(DefaultJSONProvider):
    @staticmethod
    def default(valor: object) -> object:
        if isinstance(valor,Decimal):
            return int(valor) if valor == valor.to_integral_value() else float(valor)
        if isinstance(valor,(date,datetime)):
            return valor.isoformat()
        return DefaultJSONProvider.default(valor)
