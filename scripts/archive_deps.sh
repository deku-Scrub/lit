#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env


main() {
    tar -cjf "${DEPS_ARCHIVE}" "${DEPS_DIR}"

    cat \
        <(sqlite3 "${DBNAME}" '.schema') \
        <(sqlite3 "${DBNAME}" '.dump Pronunciation PartOfSpeech SemanticLink Definitions') \
        | bzip2 -ck9 > "${DB_DUMP}"
}


main
