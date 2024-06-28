#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env
source scripts/utils.sh

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
    get_words | python3 scripts/moby.py arpabet | sort -t1 -k1,1
    #get_words | python3 moby.py arpabet | sort -t1 -k1,1 \
        #| sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin Pronunciation"
}


extract_if_not_extracted() {
    if [[ ! -f "${CMUDICT}" ]]; then
        tar -C "${MOBY_DIR}" -xf "${MOBY_FILE}"
    fi
}


prepare_prereqs() {
    mkdir -p "${MOBY_DIR}"
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
        | python3 scripts/moby.py pos
    #paste <(stream_parts_of_speech_words) <(stream_parts_of_speech) \
        #| python3 moby.py pos \
        #| sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin PartOfSpeech"
}


get_synonyms() {
    sed -r 's/\r/\n/g' "${SYN_FILE}" | python3 scripts/moby.py syn
    #sed -r 's/\r/\n/g' "${SYN_FILE}" | python3 moby.py syn \
        #| sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin Synonym"
}


make_db() {
    sqlite3 "${DBNAME}" '
CREATE TABLE IF NOT EXISTS Pronunciation (
    word TEXT,
    pronunciation TEXT,
    type TEXT,
    n_syllables INT,
    primary key (word, pronunciation)
);
CREATE INDEX IF NOT EXISTS Pronunciation_word ON Pronunciation (word);

CREATE TABLE IF NOT EXISTS PartOfSpeech (
    word TEXT,
    pos TEXT,
    PRIMARY KEY (word, pos)
);

CREATE TABLE IF NOT EXISTS Synonym (
    word1 TEXT,
    word2 TEXT,
    PRIMARY KEY (word1, word2)
);
    '
}


main() {
    prepare_prereqs
    #make_db
    get_pronunciations
    get_parts_of_speech
    get_synonyms
}


main
