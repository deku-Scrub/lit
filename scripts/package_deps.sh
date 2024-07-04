#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env


main() {
    python3 -m pip install \
        -t "${DEPS_DIR}"/python \
        -r "${ROOT_DIR}"/requirements.txt
    tar -cjf "${DEPS_ARCHIVE}" "${DEPS_DIR}"
}


main
