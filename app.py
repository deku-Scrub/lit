'''
Main entrypoint for the lit server.

Run with `python3 -m flask run` in the same directory as this file.
'''
import sqlite3
import pathlib
import sys
import json
import os

import flask

import lit.endpoints


def get_config():
    root_dir = os.path.dirname(__file__)
    config_filename = os.path.join(root_dir, 'config.json')

    config_str = ''
    if os.path.exists(config_filename):
        config_str = pathlib.Path(config_filename).read_text()

    # Config with default values.
    config = {
        'db_path': os.path.join(root_dir, 'data', 'lit.db'),
        'dictionary_dir': os.path.join(
                root_dir, 'data', 'wiktionary', 'english', 'A'
                ),
    }

    if config_str:
        config = config | json.loads(config_str)

    if not os.path.exists(config['db_path']):
        msg = 'ERROR: Database file not found: {}'.format(config['db_path'])
        print(msg, file=sys.stderr)
        exit()

    config = {k.upper(): v for k, v in config.items()}
    return config


def open_db_for_request(dbname):
    '''
    Function called before each request to open the db.

    Args:
        dbname: filename of database to open
    '''
    if 'db' not in flask.g:
        flask.g.db = sqlite3.connect(dbname)


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
    app.config.from_mapping(mapping=get_config())

    app.teardown_appcontext(close_db_for_request)
    lit.endpoints.make_endpoints(app)


    @app.before_request
    def before_req():
        open_db_for_request(app.config['DB_PATH'])


    return app
