#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


preprocess() {
    local THESAURUS_TXT="${1}"

    sed -r -e 's/\x0c/\n/g' "${THESAURUS_TXT}" \
        | sed -r -e 's/ﬂ/fl/g' \
        | sed -r -e 's/ﬁ/fi/g' \
        | sed -r 's/(^[a-z]+$)//' \
        | sed -r -e 's/\[[^]]+\]//g' \
        | sed -r -e 's/\(see ([^)]+)\)/See \1./g' \
        | sed -r -e 's/\([^)]+\)//g' \
        | sed -r -e 's/III\././g' \
        | sed -r -e 's/II\././g' \
        | sed -r -e 's/I\././g' \
        | sed -r -e 's/IV\././g' \
        | sed -r 's/Pray, v\./Pray./' \
        | sed -r 's/History, n\./History./' \
        | sed -r -e 's/n\.  dermatitis/z.  dermatitis/g' \
        | sed -r -e 's/Slang, prep\./Slang, prep;/g' \
        | sed -r -e 's/pl\./,/g' \
        | sed -r -e 's/\. [nv]\. /. z. /g' \
        | sed -r -e 's/&\s*(n|adj|adv|v|v\.t|v\.i|prep|pron|conj|interj|Lat)\././g' \
        | sed -r -e 's/^([ a-zA-Z0-9]+),\s*(n|adj|adv|v|v\.t|v\.i|prep|pron|conj|interj|Lat)\./#\1\n\2./g' \
        | sed -r -e 's/^([^#])/   \1/g' \
        | sed -r -e 's/[— ](n|adj|adv|v|v\.t|v\.i|prep|pron|conj|interj|Ant|Lat)\./\n##\1./g' \
        | sed -r -e 's/Nouns\)/the Nouns)/g' \
        | sed -r -e 's/v\.t/vt/g' \
        | sed -r -e 's/v\.i/vi/g' \
        | sed -r -e 's/^\s*—//g' \
        | sed -r 's/informal, unofficial/informalTMP, unofficial/' \
        | sed -r -e 's/Fr\.//g' \
        | sed -r -e 's/[Ss]lang//g' \
        | sed -r -e 's/Informal//g' \
        | sed -r -e 's/informal[,.]//g' \
        | sed -r -e 's/ [a-z]\. //g' \
        | sed -r 's/([a-zA-Z0-9]\.){2,}/ACRONYMBEG&ACRONYMEND/g' \
        | sed -r 's/etc\././g' \
        | sed -r 's/’/'"'"'/g' \
        | sed -r 's/—$/./' \
        | sed -r 's/-$/CONT/' \
        | sed -r 's/^\s+infirmary,.*/#infirmary/'
}


main() {
    local THESAURUS_TXT="${1}"

    preprocess "${THESAURUS_TXT}"
}


if [ "${#@}" -ne 1 ]
then
    echo 'Usage: bash preprocess.sh <input_txt>'
    exit 1
fi

main "${@}"
