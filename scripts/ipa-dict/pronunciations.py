import sys


def clean_pronunciation(fis, fos):
    for line in fis:
        row = line.strip().split(',')
        word, ipas = row[0].strip(), row[1:]
        ipas[0] = ipas[0][1:] if ipas[0].startswith('"') else ipas[0]
        ipas[-1] = ipas[-1][:-1] if ipas[-1].endswith('"') else ipas[-1]
        for ipa in ipas:
            line_str = '"{}","{}","ipa","0"\n'.format(word, ipa.strip())
            fos.write(line_str)


def main():
    if len(sys.argv) != 3:
        print('''
Usage: python3 pronunciations.py <input_filename> <output_filename>
''')
        exit(1)

    with (
            open(sys.argv[1]) as fis,
            open(sys.argv[2], 'wt') as fos,
         ):
        clean_pronunciation(fis, fos)


if __name__ == '__main__':
    main()
