import sys
import json


INVALID_POS = (
        'phrase',
        'antonym',
        'latin',
        )


short_pos_to_long = {
    'phrase': 'phrase',
    'antonym': 'antonym',
    'noun': 'noun',
    'verb': 'verb',
    'adjective': 'adjective',
    'adverb': 'adverb',
    'conjunction': 'conjunction',
    'interjection': 'interjection',
    'n': 'noun',
    'adj': 'adjective',
    'adv': 'adverb',
    'pron': 'pronoun',
    'prep': 'preposition',
    'interj': 'interjection',
    'conj': 'conjunction',
    'vt': 'verb',
    'vi': 'verb',
    'v': 'verb',
    'Ant': 'antonym',
    'Lat': 'latin',
    '': '',
}


def add_word_list(line, split=False, split_char='—'):
    line = line.split(split_char, maxsplit=1)[1].strip() if split else line
    line = line.lstrip('0123456789, ')
    return line


def get_category(lines, word):
    cur_pos = ''
    groups = []
    words = []
    for line in lines:
        line = line.strip()
        if re.match('[0-9]+,', line):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            words = [add_word_list(line)]
        elif line.startswith('Noun'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'noun'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Adjective'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'adjective'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Adverb'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'adverb'
            words = [add_word_list(line, split=True)]
        # Ignore `Verbosity`.
        elif line.startswith('Verb') and line[4] != 'o':
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'verb'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Preposition'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'prep'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Conjunction'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'conjunction'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Interjection'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'interjection'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Phrases'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'phrase'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Quotations'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'phrase'
            words = [add_word_list(line, split=True)]
        elif line.startswith('Antonym'):
            groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
            cur_pos = 'antonym'
            words = [add_word_list(line, split=True, split_char=',')]
        elif line.startswith('#'):
            break
        elif line.isupper():
            yield line, {'word': word, 'parts_of_speech': groups}
            word = line
            cur_pos = ''
            groups = []
            words = []
        elif cur_pos:
            words.append(add_word_list(line))
    if words:
        groups.append({'part_of_speech': short_pos_to_long[cur_pos], 'words': words})
    yield line, {'word': word, 'parts_of_speech': groups}


def remove_cross_references(line):
    '''
    '''
    match_intervals = []
    cross_refs = []

    parens_pattern = r'\([sS]ee [^)]+\)'
    nonparens_pattern = r'See [^;.]+.'
    cross_ref_pattern = '({})|({})'.format(parens_pattern, nonparens_pattern)
    for match in re.finditer(cross_ref_pattern, line):
        match_intervals.append((match.start(), match.end()))
        cross_ref = match.group(0).strip(' ()')
        cross_ref = cross_ref.split(maxsplit=1)[1]
        cross_ref = cross_ref.split(',')
        cross_refs.append(cross_ref)

    for (beg, end) in match_intervals[::-1]:
        line = '{} {}'.format(line[:beg], line[end:])

    cross_refs = [w.strip(' .;') for cr in cross_refs for w in cr]
    cross_refs = [w for w in cross_refs if w]
    return cross_refs, line


def finalize_group(group):
    '''
    '''
    cross_refs = []
    for pos in group['parts_of_speech']:
        words = pos['words']
        words = ' '.join(words)
        words = re.sub(r' *CONT *', '', words)
        words = re.sub(r'TMP', '', words)
        words = re.sub(r'\([^)]+\)', '', words)
        words = re.sub(r'\[[^]]+\]', '', words)
        words = re.sub(r'Informal', '', words)
        cur_cross_refs, words = remove_cross_references(words)
        word_list = []
        for w in re.split('[,;]+', words):
            if 'ACRONYMBEG' in w:
                word_list.append(
                        w.replace('ACRONYMBEG', '')
                            .replace('ACRONYMEND', '')
                            .strip()
                        )
            else:
                word_list.extend(wj.strip(' .') for wj in w.split('.'))
        pos['words'] = [w for w in word_list if w]
        cross_refs.append(cur_cross_refs)
    group['parts_of_speech'].append({
            'words': sum(cross_refs, []),
            'part_of_speech': ''
            })

    # Add back `slang` that isn't a label.
    if group['word'] == 'argot':
        group['parts_of_speech'][0]['words'].append('slang')
    elif group['word'] == 'colloquial':
        group['parts_of_speech'][0]['words'].append('informal')

    return group


def get_pairwise_synonyms(group):
    for pos_group in group['parts_of_speech']:
        if pos_group['part_of_speech'] in INVALID_POS:
            continue
        words = pos_group['words']
        for j, word_1 in enumerate(words):
            for word_2 in words[(j+1) :]:
                yield word_1, word_2


def get_single_synonyms(group):
    word = group['word']
    for pos_group in group['parts_of_speech']:
        if pos_group['part_of_speech'] in INVALID_POS:
            continue
        for synonym in pos_group['words']:
            yield word, synonym


def get_synonyms(lines):
    '''
    '''
    synonym_gen = None
    for line in lines:
        obj = json.loads(line)
        if obj['word'].isupper():
            synonym_gen = get_pairwise_synonyms(obj)
        else:
            synonym_gen = get_single_synonyms(obj)
        for syn in synonym_gen:
            yield syn


def get_parts_of_speech(lines):
    '''
    '''
    synonym_gen = None
    for line in lines:
        obj = json.loads(line)
        for pos_group in obj['parts_of_speech']:
            if not (pos := pos_group['part_of_speech']):
                continue
            for word in pos_group['words']:
                yield word, pos


def main():
    if sys.argv[1] == 'syn':
        for synonyms in get_synonyms(sys.stdin):
            print('\t'.join(synonyms))
    elif sys.argv[1] == 'pos':
        for pos in get_parts_of_speech(sys.stdin):
            print('\t'.join(pos))


if __name__ == '__main__':
    main()
