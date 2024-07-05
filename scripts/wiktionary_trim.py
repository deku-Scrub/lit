'''
Remove extraneous content from wiktionary html files.
'''
import sys
import os
import bs4


def _clear_translations(root):
    '''
    Clear translation sections from an element.

    From a given element, root, this function removes all parent
    elements that have a child with attribute `id="Translations"`.

    Args:
        root: the element from which to search for translation elements.
    '''
    for elem in root.select('[id=\"Translations\"]'):
        elem.parent.clear()


def _write_tree(root, filename, mode='wt'):
    '''
    Write an element to a file.

    Args:
        root: element to write
        filename: filename to write to
        mode: mode to open file with (see `io.open`)
    '''
    with open(filename, mode=mode) as fos:
        fos.write(str(root.encode(), 'utf-8'))
        fos.write('\n')


def trim_file(filename, outdir):
    '''
    Remove sections of a wiktionary html file.

    This function removes all translation sections and any section
    that does not describe an English term.  The resulting html is
    written to a new file named `outdir/basename(filename)`.

    Args:
        filename: name of html file to trim
        outdir: directory in which to write the trimmed html
    '''
    tree = None
    with open(filename) as fis:
        tree = bs4.BeautifulSoup(fis, features='lxml')

    outfile = os.path.join(outdir, os.path.basename(filename))
    mode = 'wt'
    for english_elem in tree.select('[id=\"English\"]'):
        _clear_translations(english_elem.parent)
        _write_tree(english_elem.parent, outfile, mode=mode)
        mode = 'at' # Append after first iteration.


def main():
    if len(sys.argv) != 2:
        print('Usage: python3 wiktionary_trim.py <output dir>')
        exit()

    outdir = sys.argv[1]
    if not os.path.exists(outdir):
        print('directory not found')
        exit()

    if not os.path.isdir(outdir):
        print('file is not a directory')
        exit()

    for filename in sys.stdin:
        trim_file(filename.strip(), outdir)


if __name__ == '__main__':
    main()
