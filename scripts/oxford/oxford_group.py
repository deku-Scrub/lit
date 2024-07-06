import sys
import re


def get_word(line):
    word, line = line.split('WORDEND', 1)
    word = word[(word.find('G') + 1):].strip()
    return word, line


def get_part_of_speech(line):
    pos, line = line.split('POSEND', 1)
    pos = pos[(pos.find('G') + 1):].strip()
    return pos, line.strip(' .,')


def get_senses(line):
    senses = line.split('SENSE')
    all_senses = []
    for sense in senses:
        if not sense:
            continue
        subgroups = sense.split('SUBGROUP')
        for subgroup in subgroups:
            all_senses.append(subgroup)
    return all_senses if all_senses else senses


def get_groups(lines):
    for line in lines:
        line = line.strip()
        word, line = get_word(line)
        pos, line = get_part_of_speech(line)
        senses = get_senses(line)
        for sense in senses:
            synonyms = (s.strip() for s in re.split('[,.;]+', sense))
            for synonym in synonyms:
                if synonym:
                    yield word, synonym, pos, 'syn'


def main():
    if len(sys.argv) != 2:
        print('Usage: python3 oxford_group.py <input_txt>')
        exit(1)

    with open(sys.argv[1]) as fis:
        for group in get_groups(fis):
            print('\t'.join(group))


if __name__ == '__main__':
    main()
