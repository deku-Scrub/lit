#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env


main() {
    if [ -d "${DIST_DIR}" ]
    then
        rm -r "${DIST_DIR}"
    fi

    mkdir -p "${DIST_DIR}"/data
    mkdir -p "${DIST_DIR}"/bin
    mkdir -p "${DIST_DIR}"/scripts

    cp "${SCRIPT_DIR}"/run_server.sh "${DIST_DIR}"/scripts
    cp "${SCRIPT_DIR}"/utils.sh "${DIST_DIR}"/scripts
    cp "${SCRIPT_DIR}"/env "${DIST_DIR}"/scripts
    cp "${SCRIPT_DIR}"/run_server.sh "${DIST_DIR}"/scripts
    cp "${ROOT_DIR}"/app.py "${DIST_DIR}"/
    cp -r "${ROOT_DIR}"/static "${DIST_DIR}"/
    cp -r "${ROOT_DIR}"/templates "${DIST_DIR}"/
    cp -r "${ROOT_DIR}"/lit "${DIST_DIR}"/

    cp "${BIN_DIR}"/lit "${DIST_DIR}"/bin
    cp "${DB_DUMP}" "${DIST_DIR}"/data
    cp "${DEPS_ARCHIVE}" "${DIST_DIR}"/data

    #tar -jcf w.tar.bz2 ~/code/lit/data/wiktionary/english/A
}


main
