#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env
source "${SCRIPT_DIR}"/utils.sh

MOBY_DIR="${DATA_DIR}"/moby
MOBY_FILE="${MOBY_DIR}"/moby.tar.Z
CMUDICT="${MOBY_DIR}"/share/ilash/common/Packages/Moby/mpron/cmudict0.3
POS_FILE="${MOBY_DIR}"/share/ilash/common/Packages/Moby/mpos/mobyposi.i
SYN_FILE="${MOBY_DIR}"/share/ilash/common/Packages/Moby/mthes/mobythes.aur
MOBY_URL='https://ai1.ai.uga.edu/ftplib/natural-language/moby/moby.tar.Z'


get_words() {
    grep -vE '(^#)|(^\W)' "${CMUDICT}" | tr '[:upper:]' '[:lower:]'
}


get_pronunciations() {
    get_words | python3 "${SCRIPT_DIR}"/moby.py arpabet | sort -t1 -k1,1
}


extract_if_not_extracted() {
    if [[ ! -f "${CMUDICT}" ]]; then
        tar -C "${MOBY_DIR}" -xf "${MOBY_FILE}"
    fi
}


prepare_prereqs() {
    if [ ! -d "${MOBY_DIR}" ]
    then
        mkdir -p "${MOBY_DIR}"
    fi

    make_db
    download_file_if_not_found "${MOBY_URL}" "${MOBY_FILE}"
    extract_if_not_extracted
}


read_parts_of_speech() {
    sed -r 's/\r/\n/g' "${POS_FILE}" \
        | sed -r -e 's/\xd7/\t/'
}


stream_parts_of_speech_words() {
    read_parts_of_speech | cut -f1 | tr '[:upper:]' '[:lower:]'
}


stream_parts_of_speech() {
    read_parts_of_speech | cut -f2 | sed -r 's/(.)/\1\t/g'
}


get_parts_of_speech() {
    paste <(stream_parts_of_speech_words) <(stream_parts_of_speech) \
        | grep -Ev '^cowardic\s' \
        | python3 "${SCRIPT_DIR}"/moby.py pos
}


get_synonyms() {
    sed -r 's/\r/\n/g' "${SYN_FILE}" | python3 "${SCRIPT_DIR}"/moby.py syn
}


main() {
    prepare_prereqs
    get_pronunciations | insert_db pro csv
    get_parts_of_speech | insert_db pos csv
    get_synonyms | insert_db syn csv
}


main
