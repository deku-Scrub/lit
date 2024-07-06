#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


preprocess() {
    local THESAURUS_TXT="${1}"

    < "${THESAURUS_TXT}" sed -r \
        -e 's/^[0-9]+$//g' \
        -e 's/\x0c/\n/g' \
        -e 's/<[^>]+>//g' \
        -e 's/[0-9]+\.[0-9]+//g' \
        | python3 -c 'import re; import sys; sys.stdout.writelines(f if not ((sum([l.isupper() for l in f.split("<")[0]]) > sum([l.islower() for l in f.split("<")[0]])) and (re.match("^[0-9]+ ",f))) else "" for f in sys.stdin)' \
        | grep -E '.' \
        | sed -r \
            -e 's/INTERJS/INTERJ/g' \
            -e 's/INTERJ$/\nINTERJ/g' \
            -e 's/, PREPS/ /g' \
            -e 's/, CONJS/ /g' \
            -e 's/ADJS, ?/ /g' \
            -e 's/(CONJS$)|( CONJS)/\nCONJS/g' \
            -e 's/(PHR$)|( PHR$)/\nPHRS/g' \
            -e 's/ADVS$/\nADVS/g' \
            -e 's/WORD$//g' \
            -e 's/^ELEMENT$/WORDELEMENT/g' \
            -e 's/^WORD ELEMENTS?/WORDELEMENT/g' \
            -e 's/^WORDELEMENT */WORDELEMENT /g' \
            -e 's/born on itself/born on itself"/g' \
            -e 's/—Horace/;/g' \
            -e 's/([a-z])\s+-?[0-9]+\s*([;,.]|$)/\1\2/g' \
            -e 's/self881/self/g' \
            -e 's/self663/self/g' \
            -e 's/assembly736/assembly/g' \
            -e 's/; 263//g' \
            -e 's/strike 341 down/strike down/g' \
            -e 's/pass635/pass/g' \
            -e 's/watered651/watered/g' \
            -e 's/VER3S/\nVERBS/g' \
            -e 's/chick\)/chick,/g' \
            -e 's/ etc//g'
}


main() {
    local THESAURUS_TXT="${1}"

    preprocess "${THESAURUS_TXT}"
}


if [ "${#@}" -ne 1 ]
then
    echo 'Usage: bash preprocess.sh <input_txt>'
    exit 1
fi

main "${@}"
