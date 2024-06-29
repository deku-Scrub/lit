import re
import os
import sys
import bs4


def print_definitions(filenames):
    '''
    '''
    tostr = lambda x: x.strip() if isinstance(x, str) else ''
    exclude_tags = ('dl', 'ul', 'dd', 'ol', 'li')
    for filename in filenames:
        filename = filename.strip()
        tree = None
        with open(filename) as fis:
            tree = bs4.BeautifulSoup(fis, features='lxml')

        for order, li in enumerate(tree.select('ol > li')):
            definitions = []
            for child in li.children:
                if child.name in exclude_tags:
                    break
                if '<![CDATA' in child.text:
                    continue
                if '↑' in child.text:
                    break
                definitions.append(child.text)
            definition = ''.join(definitions).strip()

            if not definition:
                continue

            definition = definition.replace('\n', ' ')
            definition = re.sub(r'\s+', ' ', definition)

            print(
                    os.path.basename(filename).lower(),
                    os.path.basename(filename),
                    order,
                    definition,
                    sep='\t',
                    )


def main():
    print_definitions(sys.stdin)


if __name__ == '__main__':
    main()
