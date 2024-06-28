import re
import sys
import json

import new_american_roget_postprocess as lit


short_pos_to_long = {
        'INTERJ': 'interjection',
        'CONJS': 'conjunction',
        'PHRS': 'phrase',
        'PREPS': 'preposition',
        'ADVS': 'adverb',
        'VERBS': 'verb',
        'ADJS': 'adjective',
        'NOUNS': 'noun',
        'WORDELEMENT': 'wordelement',
        }


def remove_initial_number(line):
    if (match := re.search(r'^\s*[0-9]+ ', line)):
        line = ';' + line[match.end():]
    return line


def group_lines(lines):
    '''
    '''
    group = dict()
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if line == 'ABOUT THIS BOOK':
            break
        pos_end_idx = line.find(' ')
        if (pos := line[:pos_end_idx]) in short_pos_to_long:
            if group:
                yield group
            group = {
                'part_of_speech': short_pos_to_long[pos],
                'words': [remove_initial_number(line[(pos_end_idx + 1):])],
            }
        else:
            group['words'].append(remove_initial_number(line))
    if group:
        yield group


def split_on_or(words):
    or_pattern = r'^([a-zA-Z-]+[^-] or ){1,}[a-zA-Z-]+$'
    new_words = []
    for word in words:
        if re.search(or_pattern, word):
            split_words = re.sub(or_pattern, ',', word).split(',')
            new_words.extend(split_words)
        else:
            new_words.append(word)
    return new_words


def get_subgroups(group):
    text = ' '.join(group['words'])
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'^.+>', '', text)
    text = re.sub(r'\([^)]+\)', '', text)
    text = re.sub(r'“[^”]+”\s*[^“.,;]+', ';', text)
    text = re.sub(r'"[^"]+"\s*[^".,;]+', ';', text)
    text = re.sub(r' [0-9]+([;,.])', r'\1', text)
    text = re.sub(r'[0-9]+ feet', r'', text)
    text = re.sub(r'[0-9]+-[0-9]+', r'', text)
    text = re.sub(r'(^| )-[0-9]+', r' ', text)
    text = re.sub(r'"', '', text)
    text = re.sub(r'\s+', ' ', text)
    for subgroup in text.split(';'):
        words = subgroup.split(',')
        if len(words) < 2:
            continue
        words = [w.strip() for w in words]
        words = [w for w in words if len(w) < 100]
        words = [w for w in words if not w.isnumeric()]
        words = split_on_or(words)
        words = [w for w in words if w]
        yield {
            'parts_of_speech': [{
                'part_of_speech': group['part_of_speech'],
                'words': words,
            }]
        }


def get_synonyms(groups):
    '''
    '''
    synonym_gen = None
    for group in groups:
        synonym_gen = lit.get_pairwise_synonyms(group)
        for syn in synonym_gen:
            yield syn


def get_parts_of_speech(groups):
    '''
    '''
    for group in groups:
        for pos_group in group['parts_of_speech']:
            if not (pos := pos_group['part_of_speech']):
                continue
            for word in pos_group['words']:
                yield word, pos


def main():
    if sys.argv[1] == 'syn':
        for group in group_lines(sys.stdin):
            for synonym in get_synonyms(get_subgroups(group)):
                print('\t'.join(synonym))
    elif sys.argv[1] == 'pos':
        for group in group_lines(sys.stdin):
            for pos in get_parts_of_speech(get_subgroups(group)):
                print('\t'.join(pos))


if __name__ == '__main__':
    main()
