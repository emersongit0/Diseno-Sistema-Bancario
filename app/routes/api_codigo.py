"""Consulta del índice de código construido al arrancar."""
from flask import Blueprint, current_app, jsonify
from app.utils.resultado import respuesta

api_codigo = Blueprint("api_codigo",__name__,url_prefix="/api")

@api_codigo.get('/codigo/<objeto>')
def codigo(objeto: str):
    entrada = current_app.extensions['codigo_plsql'].get(objeto.upper())
    if entrada is None:
        return jsonify(respuesta(None,'Objeto desconocido',404,[],False)),404
    return jsonify(respuesta(entrada,objetos=[entrada['objeto']]))
