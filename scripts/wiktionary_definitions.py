import os
import sys
import bs4


def print_definitions(filenames):
    '''
    '''
    tostr = lambda x: x.strip() if isinstance(x, str) else ''
    exclude_tags = ('dl', 'ul')
    for filename in filenames:
        filename = filename.strip()
        tree = None
        with open(filename) as fis:
            tree = bs4.BeautifulSoup(fis, features='lxml')

        for li in tree.select('ol > li'):
            definition = ''.join(
                    child.text
                    for child
                    in li.children
                    if child.name not in exclude_tags
                    ).strip()

            if not definition:
                continue

            print(os.path.basename(filename).lower(), definition, sep='\t')


def main():
    print_definitions(sys.stdin)


if __name__ == '__main__':
    main()
