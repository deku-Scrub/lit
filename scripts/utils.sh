#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


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
