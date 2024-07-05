#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env
source "${SCRIPT_DIR}"/utils.sh

THESAURUS_BASENAME=roget_21st_century_3E.pdf
THESAURUS_PDF="${THESAURUS_DIR}"/"${THESAURUS_BASENAME}"
THESAURUS_TXT="${CACHE_DIR}"/"${THESAURUS_BASENAME}".txt


prepare_prereqs() {
    make_db
    if [ ! -f "${THESAURUS_TXT}" ]
    then
        mkdir -p "${CACHE_DIR}"
        python3 -m pip install -t "${DEPS_DIR}"/python -r "${ROOT_DIR}"/requirements.txt
        PYTHONPATH="${DEPS_DIR}"/python "${DEPS_DIR}"/python/bin/pdf2txt.py -o - -t html -Y loose "${THESAURUS_PDF}" > "${THESAURUS_TXT}"
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
    preprocess | python3 "${SCRIPT_DIR}"/roget_21st_century.py pos
}


get_synonyms() {
    preprocess | python3  "${SCRIPT_DIR}"/roget_21st_century.py syn
}


main() {
    prepare_prereqs
    get_parts_of_speech | insert_db pos tsv
    get_synonyms | insert_db syn tsv
}


main
