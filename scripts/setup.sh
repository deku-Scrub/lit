#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env


main() {
    # TODO: Moby does not define parts of speech for synonyms;
    #  define parts of speech.
    bash scripts/moby.sh
    bash scripts/ipa-dict.sh
    bash scripts/oxford.sh
    bash scripts/roget_international_6E.sh
    bash scripts/roget_new_american.sh
    bash scripts/roget_21st_century.sh
    bash scripts/wiktionary.sh
}


main
