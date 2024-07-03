'''
Module for creating endpoints.
'''
import os
import pathlib

import flask

import markupsafe

import lit.view_utils
import lit.database


def _escape_definitions(entries):
    '''
    Escape any html contained in definitions.

    Once escaped, the `LIT_BOLDBEG_LIT` and `LIT_BOLDEND_LIT`
    are replaced with non-escaped `<b>` and `</b>`, respectively.

    This is a generator.  Each element is a tuple of
    `(word, definition)`, where `definition` is a
    `markupsafe.Markup` object.
    '''
    for (word, definition) in entries:
        definition = markupsafe.Markup \
                     .escape(definition) \
                     .replace(
                             'LIT_BOLDBEG_LIT',
                             markupsafe.Markup('<b>'),
                             ) \
                     .replace(
                             'LIT_BOLDEND_LIT',
                             markupsafe.Markup('</b>'),
                             )
        yield word, definition


def make_endpoints(app, open_db):
    '''
    Attach endpoints to a Flask app object.

    This function creates endpoints using `app.route`.

    Args:
        app: a flask.Flask object
    '''


    @app.before_request
    def before_req():
        open_db()


    @app.route('/search')
    def search():
        word = flask.request.args.get('q', '')
        search_type = flask.request.args.get('t', '0')

        if search_type == '0':
            return flask.redirect(flask.url_for('thesaurus', word=word))
        elif search_type == '1':
            return flask.redirect(
                    flask.url_for('dictionary', word=word.replace(' ', '_'))
                    )
        elif search_type == '2':
            return flask.redirect(flask.url_for('meaning', q=word))

        flask.abort(404)


    @app.route('/meaning')
    def meaning():
        definition = flask.request.args.get('q', '')
        page = int(flask.request.args.get('p', '0'))
        entries = lit.database.find_words(flask.g.db, definition, page=page)
        entries = _escape_definitions(entries)
        return flask.render_template(
                'reverse_dictionary.html',
                search_value=definition,
                select_rev=True,
                entries=entries,
                q=definition,
                next_page=page + 1,
                prev_page=max(0, page - 1),
                )


    @app.route('/thesaurus/<word>')
    def thesaurus(word):
        entries = lit.database.get_db_entries(flask.g.db, word)
        thes_data = lit.view_utils.get_thes_data(entries)
        is_text_client = 'w3m' in flask.request.headers['User-Agent']
        word_sep = ' | ' if is_text_client else ''
        return flask.render_template(
                'thesaurus.html',
                search_value=word,
                select_thes=True,
                head_word=word,
                thes_data=thes_data,
                word_sep=word_sep,
                )


    @app.route('/dictionary/<word>')
    def dictionary(word):
        filename = 'data/wiktionary/english/A/' + word
        if not os.path.exists(filename):
            return 'word not found'
        html = flask.render_template(
                'base.html',
                search_value=word,
                select_dict=True,
                )
        return html + pathlib.Path(filename).read_text()
        # TODO: if the files are gzip compressed, do something
        #  like the commented code.
        #import gzip
        #html = gzip.decompress(pathlib.Path(filename).read_bytes()).decode('utf-8')
        #
        #html = pathlib.Path(filename).read_bytes()
        #response = flask.Response(html)
        #response.content_encoding = 'gzip'
        #return response
