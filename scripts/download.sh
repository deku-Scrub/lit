#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


main() {
    local URL="${1}"
    local DEST="${2}"
    mkdir -p "$(dirname -- "${DEST}")"
    if [[ ! -f "${DEST}" ]]; then
        wget -O "${DEST}" "${URL}"
        if [[ ! -f "${DEST}" ]]; then
            echo "Problem downloading from "${URL}""
            exit
        fi
    fi
}


if [ "${#@}" -ne 2 ]
then
    echo 'Usage: bash download.sh <url> <outfile>'
    exit 1
fi

main "${@}"
