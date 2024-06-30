import json
import re
import sys
import xml.etree.ElementTree


short_pos_to_full = {
    'v': 'verb',
    'adv': 'adverb',
    'adj': 'adjective',
    'a': 'adjective',
    'ad': 'adjective',
    'n': 'noun',
    'prep': 'preposition',
    'conj': 'conjunction',
    'det': 'determiner',
    'interj': 'interjection',
    'pron': 'pronoun',
}


def get_antonyms(children):
    has_antonym = False
    for child in children:
        if ('font-family: Times-BoldItalic' in child.attrib.get('style', '')) and (child.text.strip() == 'Ant.'):
            has_antonym = True
            break
    if has_antonym:
        raw_antonyms = ''
        for child in children:
            if 'font-family: Times-Roman' in child.attrib.get('style', ''):
                return child.text
    return ''


def get_synonyms(children):
    for child in children:
        if 'font-family: Times-Roman' in child.attrib.get('style', ''):
            return child.text
    return ''


def clear_tree(elem):
    elem.clear()
    while elem.getprevious() is not None:
        del elem.getparent()[0]


def get_words(text):
    # Remove line break hyphens.
    text = text.replace('-\n', '')
    # Remove newlines that interrupt compound words.
    text = re.sub('\n', ' ', text)
    # `*` denotes the word is slang.
    text = re.sub('\*', ',', text)
    words = re.split(r'[/,;]', text)
    words = [ws for w in words if (ws := w.strip())]
    words = [re.sub(r' +', ' ', w) for w in words]
    return words


def get_entry_generator(entry):
    entry['word'] = re.sub(r'\([^)]+\)', '', entry['word'])
    if '/' not in entry['word']:
        yield entry
    else:
        for w in entry['word'].split('/'):
            entry['word'] = w
            yield entry


def get_entries(lines):
    '''
    '''
    entry = dict()
    cur_word = ''
    elements = xml.etree.ElementTree.iterparse(lines)
    for event, elem in elements:
        if elem.attrib.get('class', '') != 'entry':
            continue
        children = elem.iter()
        next(children) # Skip outer `div`.
        word = next(children).text.strip()
        next(children) # Skip `[`.
        part_of_speech = re.sub(r'/.+$', '', next(children).text)
        part_of_speech = re.sub(r'\d+$', '', part_of_speech)
        part_of_speech = short_pos_to_full[part_of_speech]
        next(children) # Skip `]`.
        definition = next(children)

        if word != cur_word:
            if entry:
                for cur_entry in get_entry_generator(entry):
                    yield cur_entry
            cur_word = word
            entry = {
                'word': word,
                'parts_of_speech': [],
            }

        raw_synonyms = get_synonyms(children)
        synonyms = get_words(raw_synonyms)
        raw_antonyms = get_antonyms(children)
        antonyms = get_words(raw_antonyms)

        if synonyms:
            entry['parts_of_speech'].append({
                    'part_of_speech': part_of_speech,
                    'words': synonyms,
                    })
        if antonyms:
            entry['parts_of_speech'].append({
                    'part_of_speech': 'antonym',
                    'words': antonyms,
                    })
    if entry:
        for cur_entry in get_entry_generator(entry):
            yield cur_entry


def get_entry_synonyms(entries):
    for entry in entries:
        word = entry['word']
        pos_groups = entry['parts_of_speech']
        for pos_group in pos_groups:
            part_of_speech = pos_group['part_of_speech']
            group_type = 'ant' if part_of_speech == 'antonym' else 'syn'
            for synonym in pos_group['words']:
                yield word, synonym, part_of_speech, group_type


def get_entry_parts_of_speech(entries):
    for entry in entries:
        word = entry['word']
        pos_groups = entry['parts_of_speech']
        for pos_group in pos_groups:
            # TODO: don't ignore.  Have 'ant' be a cmdline arg.
            if pos_group['part_of_speech'] == 'antonym':
                continue
            yield word, pos_group['part_of_speech']


def main():
    if sys.argv[1] == 'syn':
        entries = get_entries(sys.stdin)
        for syn in get_entry_synonyms(entries):
            print('\t'.join(syn))
    elif sys.argv[1] == 'pos':
        entries = get_entries(sys.stdin)
        for pos in get_entry_parts_of_speech(entries):
            print('\t'.join(pos))


if __name__ == '__main__':
    main()
