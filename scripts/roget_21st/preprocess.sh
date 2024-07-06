#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


preprocess() {
    local THESAURUS_TXT="${1}"

    grep -Ev '^<meta http-equiv="Content-Type"' "${THESAURUS_TXT}" \
        | sed -r -e 's#</?div[^>]*>##g' \
        | sed -r -e 's/<body>/<body>\n<div>/' -e 's#</body>#</div></body>#' \
        | sed -r -e 's#(<span style="font-family: Frutiger-Bold; font-size:6px">[^—][^[]+\[)#</div><div class="entry">\1#g' \
        | sed -r \
            -e 's/ﬁ/fi/g' \
            -e 's/ﬂ/fl/g' \
            -e 's/’/'"'"'/g'
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
