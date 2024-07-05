#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


# insert_db <filename> <data_type> <file_format>
# `<data_type>` is one of `pos`, `syn`, `pro`, `def`.
# `<file_format>` is one of `csv`, `tsv`.
insert_db() {
    local DBNAME="${1}" 
    local FILENAME="${2}" 
    local DATA_TYPE="${3}" 
    local FILE_FORMAT="${4}" 
    local TABLE=''

    if [ "${DATA_TYPE}" = 'pro' ]; then
        TABLE='Pronunciation'
    elif [ "${DATA_TYPE}" = 'syn' ]; then
        TABLE='SemanticLink'
    elif [ "${DATA_TYPE}" = 'pos' ]; then
        TABLE='PartOfSpeech'
    elif [ "${DATA_TYPE}" = 'def' ]; then
        TABLE='Definitions'
    else
        echo 'Invalid argument ('"${DATA_TYPE}"').  Valid values are `syn`, `pos`, `pro`, `def`.'
        exit
    fi

    if [ ! "${FILE_FORMAT}" = 'csv' ] && [ ! "${FILE_FORMAT}" = 'tsv' ]
    then
        echo 'Invalid argument ('"${FILE_FORMAT}"').  Valid values are `csv`, `tsv`.'
        exit
    fi
    if [ "${FILE_FORMAT}" = 'tsv' ]; then
        FILE_FORMAT='tabs'
    fi

    set +e
    sqlite3 "${DBNAME}" '.mode '"${FILE_FORMAT}" ".import "${FILENAME}" "${TABLE}""

    if [ "${TABLE}" = 'Definitions' ]
    then
        populate_definitions_fts "${DBNAME}"
    fi

    set -e
}


populate_definitions_fts() {
    local DBNAME="${1}" 

    sqlite3 "${DBNAME}" 'INSERT INTO DefinitionsFTS (word, definition) SELECT basename, definition FROM Definitions'
}


make_db() {
    local DBNAME="${1}"
    sqlite3 "${DBNAME}" < "${SCRIPT_DIR}"/create_tables.sql
    sqlite3 "${DBNAME}" <  "${SCRIPT_DIR}"/create_indexes.sql
}


main() {
    DBNAME="${1}" 
    FILENAME="${2}" 
    DATA_TYPE="${3}" 
    FILE_FORMAT="${4}" 

    if [ ! -s "${DBNAME}" ]
    then
        make_db "${DBNAME}"
    fi

    insert_db "${@}"
}


if [ "${#@}" -ne 4 ]
then
    cat <<HEREDOC
Usage: bash insert_db.sh <db_path> <input_file> <data_type> <file_format>

\`<data_type>\` is one of \`pos\`, \`syn\`, \`pro\`, \`def\` (part of speech,
synonym, pronunciation, definition).

\`<file_format>\` is one of \`csv\`, \`tsv\`.
HEREDOC
    exit 1
fi

main "${@}"
