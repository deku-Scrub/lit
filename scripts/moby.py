import sys
import csv


def clean_pronunciation():
    for line in sys.stdin:
        row = line.strip().split(',')
        word, ipas = row[0].strip(), row[1:]
        ipas[0] = ipas[0][1:] if ipas[0].startswith('"') else ipas[0]
        ipas[-1] = ipas[-1][:-1] if ipas[-1].endswith('"') else ipas[-1]
        for ipa in ipas:
            line_str = '"{}","{}","ipa","0"'.format(word, ipa.strip())
            print(line_str)


def count_syllables():
    for line in sys.stdin:
        row = line.strip().split()
        word = row[0].strip()
        word = word[:word.find('(')] if '(' in word else word
        n_syllables = sum(any(map(str.isdigit, sound)) for sound in row[1:])
        line_str = '"{}","{}","arpabet","{}"'.format(
                word,
                ' '.join(row[1:]).strip(),
                n_syllables,
                )
        print(line_str)


def pos():
    short_pos_to_full = {
            'o': 'nominative',
            'I': 'article',
            'D': 'article',
            'h': 'phrase',
            'p': 'plural',
            'N': 'noun',
            'V': 'verb',
            't': 'verb',
            'i': 'verb',
            'A': 'adjective',
            '!': 'interrogative',
            'r': 'pronoun',
            'P': 'preposition',
            'C': 'conjunction',
            'v': 'adverb',
            }
    sys.stdin.reconfigure(encoding='latin-1')
    lines = (line.strip().split('\t') for line in sys.stdin)
    rows = ((r[0], short_pos_to_full[rj]) for r in lines for rj in r[1:])
    csv.writer(sys.stdout).writerows(rows)


def syn():
    lines = (line.strip().split(',') for line in sys.stdin)
    rows = ((r[0], rj, '', 'syn') for r in lines for rj in r[1:])
    csv.writer(sys.stdout).writerows(rows)


def main():
    if sys.argv[1] == 'arpabet':
        count_syllables()
    elif sys.argv[1] == 'ipa':
        clean_pronunciation()
    elif sys.argv[1] == 'pos':
        pos()
    elif sys.argv[1] == 'syn':
        syn()


if __name__ == '__main__':
    main()
