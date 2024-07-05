#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


main() {
    local DB_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    local DBNAME="${1}"
    mkdir -p "$(dirname -- "${DBNAME}")"
    sqlite3 "${DBNAME}" < "${DB_DIR}"/create_tables.sql
    sqlite3 "${DBNAME}" < "${DB_DIR}"/create_indexes.sql
}


if [ "${#@}" -ne 1 ]
then
    echo 'Usage: bash make_db.sh <dbpath>'
    exit 1
fi

main "${@}"
