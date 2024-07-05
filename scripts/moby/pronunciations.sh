#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


get_words() {
    local CMUDICT="${1}"
    grep -vE '(^#)|(^\W)' "${CMUDICT}" | tr '[:upper:]' '[:lower:]'
}


main() {
    local CMUDICT="${1}"
    local OUTFILE="${2}"

    get_words "${CMUDICT}" \
        | python3 "${SCRIPT_DIR}"/moby.py arpabet \
        | sort -t1 -k1,1 \
        > "${OUTFILE}"
}


if [ "${#@}" -ne 2 ]
then
    echo 'Usage: bash pronuciations.sh <cmudict_path> <outfile>'
    exit 1
fi

main "${@}"
