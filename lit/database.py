'''
Functions for thesaurus/dictionary/etc. database queries.
'''
import sqlite3
import json
import re


_MEANING_STMT = '''
SELECT
    word,
    SNIPPET(DefinitionsFTS, 1, 'LIT_BOLDBEG_LIT', 'LIT_BOLDEND_LIT', '...', 128) AS definition
FROM DefinitionsFTS
WHERE definition MATCH ?
ORDER BY rank
LIMIT 100
OFFSET {offset}
'''

_STMT = '''
SELECT
    JSON_OBJECT(
        'class', 'definition',
        'word', basename,
        'members', JSON_GROUP_ARRAY(definition)
    ) AS entry
FROM Definitions
WHERE word = ?
GROUP BY basename
UNION ALL
SELECT
    JSON_OBJECT(
        'class', 'pronunciation',
        'members', JSON_GROUP_ARRAY(pronunciation)
    ) AS entry
FROM Pronunciation
WHERE word = ? AND type = 'ipa'
UNION ALL
SELECT
    JSON_OBJECT(
        'class', pos,
        'members', JSON_GROUP_ARRAY(word)
    ) AS entry
FROM (
    SELECT word2 AS word, pos
    FROM SemanticLink
    WHERE word1 = ?
    UNION
    SELECT word1 AS word, pos
    FROM SemanticLink
    WHERE word2 = ?
    )
GROUP BY pos
'''


def find_words(db, definition, page=0):
    '''
    Find words whose definitions matches a given definition.

    This is a reverse dictionary search.  Instead of finding
    the meaning of a given word, it finds the words of the
    given meaning.

    Args:
        db: an sqlite3.Connection instance.
        definition: meaning of the words to search for
        page (default 0): page of results to return.  Each
            page contains at most 100 results.

    Returns:
        Iterable of words that has at least one definition which
        matches the given definition.  Matches of the given definition
        will be surrounded by `LIT_BOLDBEG_LIT` and `LIT_BOLDEND_LIT`.
    '''
    # The sqlite3 package doesn't properly escape input for fts
    # match queries, so it has to be done manually.  Double quotes
    # need to be escaped with an additional double quote, that is
    # every `"` needs to be `""`.  Then each term must be surrounded
    # by double quotes.
    definition = definition.replace('"', '""')
    definition = re.sub(r'(\S+)', r'"\1"', definition)

    rows = iter([])
    with db:
        stmt = _MEANING_STMT.format(offset=100 * page)
        rows = db.execute(stmt, (definition,))
    return rows


def get_db_entries(db, query):
    '''
    Get thesaurus entries.

    Args:
        db: an sqlite3.Connection instance.
        query: word for which thesaurus entries are searched.

    Returns:
        Iterable of thesaurus entries.
    '''
    entries = iter([])
    with db:
        rows = db.execute(_STMT, (query,) * 4)
        entries =  (json.loads(row[0]) for row in rows)
    return entries
