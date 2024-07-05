#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


main() {
    local SYN_FILE="${1}"
    local OUTFILE="${2}"
    sed -r 's/\r/\n/g' "${SYN_FILE}" \
        | python3 "${SCRIPT_DIR}"/moby.py syn \
        > "${OUTFILE}"
}


if [ "${#@}" -ne 2 ]
then
    echo 'Usage: bash synonyms.sh <moby_syn_file> <outfile>'
    exit 1
fi

main "${@}"
