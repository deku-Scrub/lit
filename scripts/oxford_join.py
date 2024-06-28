import sys


def skip_header(lines):
    for line in lines:
        if line.strip() == 'zone... 25.3':
            break


def join_lines(lines):
    skip_header(lines)

    group = []
    for line in lines:
        line = line.strip()
        if line.startswith('#'):
            if group:
                yield ' '.join(group)
            group = [line]
        elif line:
            group.append(line)
    if group:
        yield ' '.join(group)


def main():
    for group in join_lines(sys.stdin):
        print(group)


if __name__ == '__main__':
    main()
