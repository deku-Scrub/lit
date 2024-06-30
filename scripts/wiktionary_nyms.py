import os
import sys
import xml
import xml.etree.ElementTree


def find_nym_thesaurus(filenames, nym_type):
    '''
    '''
    for filename in filenames:
        filename = filename.strip()
        tree = xml.etree.ElementTree.parse(filename)
        xpath = './/*[@id="{}"]/..//*[@lang="en"]'.format(nym_type)
        matches = [
            next(elem.itertext()).lower().replace(' ', '_')
            for elem
            in tree.findall(xpath)
        ]
        for j, match_1 in enumerate(matches):
            for match_2 in matches[(j + 1):]:
                print(match_1, match_2, '', 'syn', sep='\t')


def find_nym(filenames, nym_type):
    '''
    '''
    for filename in filenames:
        filename = filename.strip()
        tree = xml.etree.ElementTree.parse(filename)
        xpath = './/*[@class="nyms {}"]/*[@lang="en"]'.format(nym_type)
        matches = [os.path.basename(filename).lower()] + [
            next(elem.itertext()).lower().replace(' ', '_')
            for elem
            in tree.findall(xpath)
        ]
        for j, match_1 in enumerate(matches):
            for match_2 in matches[(j + 1):]:
                print(match_1, match_2, '', 'syn', sep='\t')


def main():
    if sys.argv[1] == 'syn':
        find_nym(sys.stdin, 'synonym')
    elif sys.argv[1] == 'thes_syn':
        find_nym_thesaurus(sys.stdin, 'Synonyms')
    # TODO: these require a more complex implementation:
    # for each antonym, pair with each synonym.
    #elif sys.argv[1] == 'ant':
        #find_nym(sys.stdin, 'antonym')
    #elif sys.argv[1] == 'thes_ant':
        #find_nym_thesaurus(sys.stdin, 'Antonyms')


if __name__ == '__main__':
    main()
