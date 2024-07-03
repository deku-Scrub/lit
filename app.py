'''
Main entrypoint for the lit server.

Run with `python3 -m flask run` in the same directory as this file.
'''
import flask

import lit.endpoints


def create_app(test_config=None):
    app = flask.Flask(__name__)

    lit.endpoints.make_endpoints(app)

    return app
