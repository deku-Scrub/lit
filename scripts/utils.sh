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
# `<data_type>` is one of `pos`, `syn`, `pro`, `def`.
# `<data_format>` is one of `csv`, `tsv`.
insert_db() {
    TABLE=''
    if [ "${1}" = 'pro' ]; then
        TABLE='Pronunciation'
    elif [ "${1}" = 'syn' ]; then
        TABLE='SemanticLink'
    elif [ "${1}" = 'pos' ]; then
        TABLE='PartOfSpeech'
    elif [ "${1}" = 'def' ]; then
        TABLE='Definitions'
    else
        echo 'Invalid argument ('"${1}"').  Valid values are `syn`, `pos`, `pro`, `def`.'
        exit
    fi

    FORMAT="${2}"
    if [ ! "${FORMAT}" = 'csv' ] && [ ! "${FORMAT}" = 'tsv' ]
    then
        echo 'Invalid argument ('"${FORMAT}"').  Valid values are `csv`, `tsv`.'
        exit
    fi
    if [ "${FORMAT}" = 'tsv' ]; then
        FORMAT='tabs'
    fi

    set +e
    sqlite3 "${DBNAME}" '.mode '"${FORMAT}" ".import /dev/stdin "${TABLE}""

    if [ "${TABLE}" = 'Definitions' ]
    then
        sqlite3 "${DBNAME}" 'INSERT INTO DefinitionsFTS (word, definition) SELECT word, definition FROM Definitions'
    fi

    set -e
}


make_db() {
    sqlite3 "${DBNAME}" < scripts/db/create_tables.sql
    sqlite3 "${DBNAME}" < scripts/db/create_indexes.sql
}
