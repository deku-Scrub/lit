#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env
source "${SCRIPT_DIR}"/utils.sh


prepare_prereqs() {
    if [ ! -d "${DEPS_DIR}" ]
    then
        tar -xf "${DEPS_ARCHIVE}"
    fi

    if [ ! -s "${DBNAME}" ]
    then
        echo 'Database not found.  Attempting to create it.  This takes a few minutes. '

        sleep 1

        set +e
        sqlite3 "${DBNAME}" < <(bunzip2 -c "${DB_DUMP}")
        populate_definitions_fts
        set -e
    fi
}


main() {
    prepare_prereqs
}


main
