"""Factoría Flask: configura rutas e índice SQL sin abrir Oracle."""
import logging
from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException
from app.utils.json_provider import BancoJSONProvider
from app.utils.codigo_plsql import indexar
from app.utils.errores import ErrorAplicacion
from app.utils.resultado import respuesta


def create_app(configuracion: dict | None = None) -> Flask:
    app = Flask(__name__)
    app.json_provider_class = BancoJSONProvider
    app.json = BancoJSONProvider(app)
    app.config.update(MAX_CONTENT_LENGTH=65536)
    if configuracion:
        app.config.update(configuracion)
    app.extensions['codigo_plsql'] = indexar()
    from app.routes.api_banca import api
    from app.routes.api_codigo import api_codigo
    from app.routes.paginas import paginas
    app.register_blueprint(api)
    app.register_blueprint(api_codigo)
    app.register_blueprint(paginas)

    @app.errorhandler(ErrorAplicacion)
    def validacion(error):
        return jsonify(respuesta(None,error.mensaje,error.codigo,[],False)),error.http

    @app.errorhandler(HTTPException)
    def error_http(error):
        mensajes = {404:'Recurso no encontrado',405:'Método no permitido',413:'Solicitud demasiado grande',400:'Solicitud inválida',415:'Se requiere JSON'}
        return jsonify(respuesta(None,mensajes.get(error.code,'Solicitud inválida'),error.code,[],False)),error.code

    @app.errorhandler(Exception)
    def inesperado(error):
        logging.getLogger(__name__).error('Error no controlado: %s',type(error).__name__)
        return jsonify(respuesta(None,'Error interno',0,[],False)),500
    return app
