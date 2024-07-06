#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


main() {
    THESAURUS_PDF="${1}" 
    THESAURUS_TXT="${2}" 

    pdf2txt.py -o - -t html -Y loose "${THESAURUS_PDF}" > "${THESAURUS_TXT}"
}


if [ "${#@}" -ne 2 ]
then
    echo 'Usage: bash pdf2txt.sh <input_pdf> <output_txt>'
    exit 1
fi

main "${@}"
