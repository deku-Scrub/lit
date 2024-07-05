#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


read_parts_of_speech() {
    local POS_FILE="${1}"
    sed -r 's/\r/\n/g' "${POS_FILE}" \
        | sed -r -e 's/\xd7/\t/'
}


stream_parts_of_speech_words() {
    local POS_FILE="${1}"
    read_parts_of_speech "${POS_FILE}" | cut -f1 | tr '[:upper:]' '[:lower:]'
}


stream_parts_of_speech() {
    local POS_FILE="${1}"
    read_parts_of_speech "${POS_FILE}" | cut -f2 | sed -r 's/(.)/\1\t/g'
}


main() {
    local POS_FILE="${1}"
    local OUTFILE="${2}"
    paste \
        <(stream_parts_of_speech_words "${POS_FILE}") \
        <(stream_parts_of_speech "${POS_FILE}") \
        | grep -Ev '^cowardic\s' \
        | python3 "${SCRIPT_DIR}"/moby.py pos \
        > "${OUTFILE}"
}


if [ "${#@}" -ne 2 ]
then
    echo 'Usage: bash parts_of_speech.sh <moby_pos_file> <outfile>'
    exit 1
fi

main "${@}"
