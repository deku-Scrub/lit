'''
Functions for preparing data that are shown in views.
'''


def _select_definitions(entries):
    '''
    Select which definitions to present.

    This selects a subset of definitions to show depending on
    how many entries in `entries` there are.  The selected
    definitions are returned.
    '''
    # Show some definitions per entry when there are multiple entries,
    # otherwise, show at most five.
    n_defs = 2 if len(entries) > 1 else 5
    definitions = [e | {'members': e['members'][:n_defs]} for e in entries]
    return definitions


class ThesaurusData:
    '''
    Container to hold thesaurus view data.
    '''

    def __init__(self):
        self.definitions = []
        self.pronunciations = []
        self.entries = []


def _populate_thes_data(entries):
    '''
    Populate a `ThesaurusData` object.

    Args:
        entries: list of db thesaurus entries

    Returns:
        A `ThesaurusData` object with members populated according
        to the data in `entries`.
    '''
    thes_data = ThesaurusData()
    for entry in entries:
        if (cls := entry['class']) == 'pronunciation':
            thes_data.pronunciations = [p for p in entry['members']]
            continue
        elif cls == 'definition':
            thes_data.definitions.append(entry)
            continue

        # At this point, `members` are synonym/antonym lists.

        toc_id = cls if cls else 'unclassified'
        title = 'Antonyms' if toc_id == 'antonym' else f'Synonyms - {toc_id}'
        thes_data.entries.append(
                entry | {'toc_id': toc_id, 'toc_title': title}
                )

    return thes_data


def get_thes_data(entries):
    '''
    Get a `ThesaurusData` object.

    This object contains the data needed to display in the thesaurus
    webpage.

    Args:
        entries: list of database thesaurus entries.

    Returns:
        The `ThesaurusData` object with data members populated
        according to the given `entries`.
    '''
    thes_data = _populate_thes_data(entries)
    thes_data.entries = sorted(thes_data.entries, key=lambda e: e['toc_title'])
    thes_data.definitions = _select_definitions(thes_data.definitions)
    return thes_data


