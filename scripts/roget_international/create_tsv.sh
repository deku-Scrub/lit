#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

main() {
    local THESAURUS_TXT="${1}"
    local DATA_TYPE="${2}"
    local OUTFILE="${3}"

    bash "${SCRIPT_DIR}"/preprocess.sh "${THESAURUS_TXT}" \
        | python3 "${SCRIPT_DIR}"/roget_international_6E.py "${DATA_TYPE}" \
        > "${OUTFILE}"
}


if [ "${#@}" -ne 3 ]
then
    echo 'Usage: bash pdf2txt.sh <input_txt> <data_type> <outfile>'
    echo '<data_type> is one of `pos` or `syn` (part of speech, synonym)'
    exit 1
fi

main "${@}"
