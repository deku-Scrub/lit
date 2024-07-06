#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

main() {
    local THESAURUS_TXT="${1}"
    local DATA_TYPE="${2}"
    local OUTFILE="${3}"

    if [ "${DATA_TYPE}" == 'pos' ]
    then
        python3 "${SCRIPT_DIR}"/oxford_group.py "${THESAURUS_TXT}" \
            | cut -f1,3 \
            > "${OUTFILE}"
    elif [ "${DATA_TYPE}" == 'syn' ]
    then
        python3 "${SCRIPT_DIR}"/oxford_group.py "${THESAURUS_TXT}" \
            > "${OUTFILE}"
    else
        echo 'ERROR: invalid data type: '"${DATA_TYPE}"'.  Must be one'
        echo 'of `pos` or `syn`.'
        exit 1
    fi
}


if [ "${#@}" -ne 3 ]
then
    echo 'Usage: bash pdf2txt.sh <input_txt> <data_type> <outfile>'
    echo '<data_type> is one of `pos` or `syn` (part of speech , synonym)'
    exit 1
fi

main "${@}"
