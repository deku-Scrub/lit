#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}"/env


main() {
    git add "${DB_DUMP}" "${DEPS_ARCHIVE}" "${BIN_DIR}"/lit
    echo
    echo '###########################################################'
    echo 'Files have been staged.  Review and if all looks good, run'
    echo '`git commit`.'
    echo '###########################################################'
}


main
