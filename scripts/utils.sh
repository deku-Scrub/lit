#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env


download_file_if_not_found() {
    local URL="${1}"
    local DEST="${2}"
    if [[ ! -f "${DEST}" ]]; then
        wget -O "${DEST}" "${URL}"
        if [[ ! -f "${DEST}" ]]; then
            echo "Problem downloading from "${URL}""
            exit
        fi
    fi
}


# ... | insert_db <data_type> <data_format>
# `<data_type>` is one of `pos`, `syn`, `pro`.
# `<data_format>` is one of `csv`, `tsv`.
insert_db() {
    TABLE=''
    if [ "${1}" -eq 'pro' ]
    then
        TABLE='Pronunciation'
    elif [ "${1}" -eq 'syn' ]
    then
        TABLE='Synonym'
    elif [ "${1}" -eq 'pos' ]
    then
        TABLE='PartOfSpeech'
    else
        echo 'Invalid argument ('"${1}"').  Valid values are `syn`, `pos`, `pro`.'
        exit
    fi

    FORMAT="${2}"
    if [ "${FORMAT}" = 'csv' ] || [ "${FORMAT}" = 'tsv' ]
    then
        echo 'Invalid argument ('"${FORMAT}"').  Valid values are `csv`, `tsv`.'
        exit
    fi

    sqlite3 "${DBNAME}" '.mode '"${FORMAT}" ".import /dev/stdin "${TABLE}""
}


make_db() {
    sqlite3 "${DBNAME}" scripts/db/create_tables.sql
    sqlite3 "${DBNAME}" scripts/db/create_indexes.sql
}
