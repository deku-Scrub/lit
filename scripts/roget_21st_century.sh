#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env
source scripts/utils.sh

THESAURUS_BASENAME=roget_21st_century_3E.pdf
THESAURUS_PDF="${THESAURUS_DIR}"/"${THESAURUS_BASENAME}"
THESAURUS_TXT="${CACHE_DIR}"/"${THESAURUS_BASENAME}".txt


prepare_prereqs() {
    if [ ! -f "${THESAURUS_TXT}" ]
    then
        mkdir -p "${CACHE_DIR}"
        python3 -m pip install -t pylib pdfminer.six
        PYTHONPATH=pylib/ pylib/bin/pdf2txt.py -o - -t html -Y loose "${THESAURUS_PDF}" > "${THESAURUS_TXT}"
    fi
}


preprocess() {
    grep -Ev '^<meta http-equiv="Content-Type"' "${THESAURUS_TXT}" \
        | sed -r -e 's#</?div[^>]*>##g' \
        | sed -r -e 's/<body>/<body>\n<div>/' -e 's#</body>#</div></body>#' \
        | sed -r -e 's#(<span style="font-family: Frutiger-Bold; font-size:6px">[^—][^[]+\[)#</div><div class="entry">\1#g' \
        | sed -r \
            -e 's/ﬁ/fi/g' \
            -e 's/ﬂ/fl/g' \
            -e 's/’/'"'"'/g'
}


get_parts_of_speech() {
    preprocess | python3 scripts/roget_21st_century.py pos
}


get_synonyms() {
    preprocess | python3 scripts/roget_21st_century.py syn
}


main() {
    prepare_prereqs
    get_parts_of_speech | insert_db pos tsv
    get_synonyms | insert_db syn tsv
}


main
