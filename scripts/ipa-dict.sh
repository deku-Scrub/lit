#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env
source scripts/utils.sh

IPA_DIR="${DATA_DIR}"/ipa-dict
IPA_FILE="${IPA_DIR}"/csv.zip
IPA_CSV="${IPA_DIR}"/csv/en_US.csv
IPA_URL='https://github.com/open-dict-data/ipa-dict/releases/download/1.0/csv.zip'


get_pronunciations() {
    cat "${IPA_CSV}" | python3 scripts/moby.py ipa | sort -t, -k1,1
    #cat "${IPA_CSV}" | python3 scripts/moby.py ipa | sort -t, -k1,1 \
        #| sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin Pronunciation"
}


prepare_prereqs() {
    mkdir -p "${IPA_DIR}"
    download_file_if_not_found "${IPA_URL}" "${IPA_FILE}"
    if [[ ! -f "${IPA_CSV}" ]]; then
        unzip -d "${IPA_DIR}" "${IPA_FILE}"
    fi
}


main() {
    prepare_prereqs
    get_pronunciations
}


main
