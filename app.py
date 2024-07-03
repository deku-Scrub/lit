'''
Main entrypoint for the lit server.

Run with `python3 -m flask run` in the same directory as this file.
'''
import sqlite3

import flask

import lit.endpoints


def open_db_for_request():
    '''
    Function called before each request to open the db.
    '''
    if 'db' not in flask.g:
        # TODO: don't hardcode db path.
        flask.g.db = sqlite3.connect('data/lit.db')


def close_db_for_request(e=None):
    '''
    Function called after each request to close the db.
    '''
    if (db := flask.g.pop('db', None)):
        db.close()


def create_app(test_config=None):
    '''
    Main entrypoint for `flask run`.
    '''
    app = flask.Flask(__name__)

    app.teardown_appcontext(close_db_for_request)
    lit.endpoints.make_endpoints(app, open_db_for_request)

    return app
