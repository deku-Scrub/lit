#!/bin/bash
# Start the lit server.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env

main() {
    LOG_FILENAME="${LOG_DIR}"/lit_"$(date -Iseconds)".log
    if [ ! -d "${LOG_DIR}" ]
    then
        mkdir "${LOG_DIR}"
    fi

    # Execute in a subshell to prevent cd'ing in the root shell.
    (
        cd "${ROOT_DIR}"
        export PYTHONPATH="${DEPS_DIR}"/python
        python3 -m flask run \
            --host "${HOST}" \
            --port "${PORT}" \
            > "${LOG_FILENAME}" 2>&1
    )
}


main
