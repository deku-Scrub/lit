#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

get_synonyms() {
    preprocess | python3 "${SCRIPT_DIR}"/oxford_group.py
}


get_parts_of_speech() {
    preprocess | python3 "${SCRIPT_DIR}"/oxford_group.py | cut -f1,3
}







main() {
    get_synonyms | insert_db syn tsv
    get_parts_of_speech | insert_db pos tsv
}


main
