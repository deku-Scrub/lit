'''
Functions for thesaurus/dictionary/etc. database queries.
'''
import sqlite3
import json


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


def find_words(definition, page=0):
    '''
    Find words whose definitions matches a given definition.

    This is a reverse dictionary search.  Instead of finding
    the meaning of a given word, it finds the words of the
    given meaning.

    Args:
        definition: meaning of the words to search for
        page (default 0): page of results to return.  Each
            page contains at most 100 results.

    Returns:
        Iterable of words that has at least one definition which
        matches the given definition.  Matches of the given definition
        will be surrounded by `LIT_BOLDBEG_LIT` and `LIT_BOLDEND_LIT`.
    '''
    # TODO: don't hardcode db path.
    db = sqlite3.connect('data/lit.db')
    rows = iter([])
    with db:
        stmt = _MEANING_STMT.format(offset=100 * page)
        rows = db.execute(stmt, (definition,))
    return rows


def get_db_entries(query):
    '''
    Get thesaurus entries.

    Args:
        query: word for which thesaurus entries are searched.

    Returns:
        Iterable of thesaurus entries.
    '''
    # TODO: don't hardcode db path.
    db = sqlite3.connect('data/lit.db')
    entries = iter([])
    with db:
        rows = db.execute(_STMT, (query,) * 4)
        entries =  (json.loads(row[0]) for row in rows)
    return entries
