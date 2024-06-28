import sys
import re


cross_refs = dict()
pos_abbrev_to_full = {
        'v': 'verb',
        'n': 'noun',
        'nphr': 'noun',
        'adj': 'adjective',
        'adv': 'adverb',
        'adv.phr': 'adverb',
        'adjadv': 'adjective', # TODO: label as adj and adv.
        'nadv': 'noun', # TODO: label as n and adv.
        'attributive': 'attributive',
        'prep': 'preposition',
        'interj': 'interjection',
        'interjection': 'interjection',
        'conj': 'conjunction',
        'pron': 'pronoun',
        'quasi-adv': 'adverb',
        }


def skip_header(lines):
    for line in sys.stdin:
        if line.startswith('#A'):
            break

def get_groups(lines):
    skip_header(lines)

    group = []
    was_prev_line_blank = False
    for line in lines:
        line = line.strip()
        if not line:
            was_prev_line_blank = True
        elif line.startswith('#') and was_prev_line_blank:
            # Ignore section headings that are formed as
            # `<blank line>#<line><blank line>`.
            if len(group) > 1:
                yield ' '.join(group)
            group = [line]
            was_prev_line_blank = False
        elif line.startswith('#') and not was_prev_line_blank:
            # Ignore lines of the form `<not blank line>#<line>`.
            # These were improperly labelled with `#`.
            continue
        else:
            line = line[1:] if line.startswith('#') else line
            group.append(line)
            was_prev_line_blank = False
    if len(group) > 1:
        yield ' '.join(group)


def get_phrase(entry):
    beg = entry.find(':')
    end = beg
    cur = beg
    if beg < 0:
        return beg, end
    while True:
        re_match = re.search('[.?!]', entry[cur:])
        if not re_match:
            end = len(entry)
            break
        cur += re_match.start() + 1
        end = cur
        while (cur < len(entry)) and (entry[cur] == ' '):
            cur += 1
            continue
        if (cur >= len(entry)) or entry[cur].isdigit():
            break
    return beg, end


def split_parts_of_speech(line):
    pos_groups = line.split('_')
    # For `word`, skip the initial `#`.
    word, pos_groups = pos_groups[0][1:], pos_groups[1:]
    word = word.strip()
    for pos_group in pos_groups:
        pos, entry = pos_group.split(' ', maxsplit=1)
        pos = pos_abbrev_to_full[pos.strip()]
        #phrase = get_phrase(entry)
        #entry = update_cross_refs(word, entry)
        print('WORDBEG{}WORDEND.POSBEG{}POSEND.'.format(word, pos), entry)
        #print(entry[phrase[0] : phrase[1]])


def pos(lines):
    for line in lines:
        group = split_parts_of_speech(line.strip())
        #print(group)
    #print(cross_refs)


def update_cross_refs(word, entry):
    global cross_refs
    match_intervals = []
    #pattern = r'(See[^.:]+((above)|(below))[.:])|(\(See also[^)]+\))'
    pattern = r'(See [a-z-]+\.)|(See[^.:]+((above)|(below))[.:])|(\(See also[^)]+\))|(See [a-z]+[, 0-9]+\.)|(See +[0-9]+(\(.\))?\.)|(See ineffectual and ineffective\.)|(See access,)'
    for m in re.finditer(pattern, entry):
        if not m:
            continue
        match_intervals.append((m.start(), m.end()))
        text = m.group(0)
        text = text.strip().replace('See also', 'See ').replace('See', 'See,')
        cross_refs.setdefault(word, [])
        cr_words = text.split(',')[1:] # Ignore the initial `See`.
        for w in cr_words:
            w = w.strip()
            # Ignore embedded `(x)` which refer to a section.
            if w.startswith('(') or (w == 'and') or (w == 'or'):
                continue
            cross_refs[word].append(w)

    for (beg, end) in match_intervals[::-1]:
        entry = entry[:beg] + '. ' + entry[end:]
    return entry.strip()


def main():
    if sys.argv[1] == 'pos':
        pos(sys.stdin)
    elif sys.argv[1] == 'syn':
        syn()


if __name__ == '__main__':
    main()
