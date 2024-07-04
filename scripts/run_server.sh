#!/bin/bash
# Start the lit server.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env
source "${SCRIPT_DIR}"/utils.sh

# Ignore ctrl-z.  When the server is started from the `lit` script
# and that script is stopped with ctrl-z, then the server is also
# stopped, preventing any other clients from sending requests.  This
# only happens when the server is started.  If `lit` is run again
# after the server is already running, ctrl-z does not affect the
# server.
trap '' SIGTSTP

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
