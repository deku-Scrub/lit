#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env

URL='https://download.kiwix.org/zim/wiktionary/wiktionary_en_all_nopic_2023-11.zim'
WIKTIONARY_DIR="${DATA_DIR}"/wiktionary
ZIM_FILENAME="${WIKTIONARY_DIR}"/"$(basename "${URL}")"
EXTRACTED_DIR="${WIKTIONARY_DIR}"/extracted
ENGLISH_WORDLIST="${WIKTIONARY_DIR}"/english_filenames.txt
export ENGLISH_DIR="${WIKTIONARY_DIR}"/english # Export for parallel.
MALFORMED_DIR="${WIKTIONARY_DIR}"/malformed_names
PARTS_OF_SPEECH_PATTERNS=scripts/parts_of_speech.txt


download_if_not_found() {
    wget -P "${WIKTIONARY_DIR}" "${URL}" || echo 'Problem downloading' "${URL}"
}


handle_decompression_exceptions() {
    mkdir -p "${MALFORMED_DIR}"

    # The `"${EXTRACTED_DIR}"/A` folder should only contain text files.
    # Any directory here is a result of an exception due to the text file
    # having a `/` in its basename.  These directories are moved to
    # `"${MALFORMED_DIR}"`.
    find "${EXTRACTED_DIR}"/A -maxdepth 1 -mindepth 1 \
        -type d -regex '.*.*' -exec mv {} "${MALFORMED_DIR}" \;

    # Copy exceptions to `"${EXTRACTED_DIR}"/A` if they don't exist.
    # This is fine since the exceptions do not have malformed names --
    # they are text files without any `/` in their basenames.
    #
    # Exception basenames start with `A`.
    # `%2f` encodes a `/`.
    find "${EXTRACTED_DIR}"/_exceptions/ -type f -regex '.*/A[^/]+' \
        | while read -r FILENAME; \
        do
          # Sanitize filename then check if it exists.  If not, then
          # the exception wasn't handled and so is copied.
          CLEANLINE="$(echo "$FILENAME" | sed -r -e 's/%2f//g' -e 's#/A#/#')"
          if [ ! -s "${EXTRACTED_DIR}"/A/"$(basename "$CLEANLINE")" ]
          then
            cp "${FILENAME}" "${EXTRACTED_DIR}"/A/
            cp "${FILENAME}" "${MALFORMED_DIR}"/
          fi
        done
}


decompress_zim() {
    zimdump dump --dir "${EXTRACTED_DIR}" "${ZIM_FILENAME}"
    handle_decompression_exceptions
}


find_english_entries() {
    # Find pages with `English` sections.
    find "${EXTRACTED_DIR}"/A -type f -iregex '.*.*' \
        | parallel -N100000 -j"${N_JOBS}" 'grep -m1 -lF "id=\"English\"" ' \
        > "${ENGLISH_WORDLIST}"
}


move_english_entries() {
    # TODO: do -j"${N_JOBS}"?
    mkdir -p "${ENGLISH_DIR}"/A
    mv "${EXTRACTED_DIR}"/- "${ENGLISH_DIR}"/-
    cat "${ENGLISH_WORDLIST}" \
        | parallel --env ENGLISH_DIR -j1 -N10000 'mv {} "${ENGLISH_DIR}"/A'
}


trim_html_files() {
    mkdir -p "${ENGLISH_DIR}"/slim
    find "${ENGLISH_DIR}"/A -type f \
        | parallel -j"${N_JOBS}" --env ENGLISH_DIR 'xmllint --xpath "//*[@id=\"English\"]/.." --html {} > "${ENGLISH_DIR}"/slim/{/} 2>/dev/null'
    rm -r "${ENGLISH_DIR}"/A
    mv "${ENGLISH_DIR}"/slim "${ENGLISH_DIR}"/A
    mkdir -p "${ENGLISH_DIR}"/slim
}


remove_encoded_slashes() {
    find "${ENGLISH_DIR}"/A -iregex '.*a%2f.*' \
        | parallel -j1 'A="$(echo {} | sed -r -e s/A%2f// -e s/%2f/-/g)"; mv {} "$A"'
}


prepare_prereqs() {
    mkdir -p "${WIKTIONARY_DIR}"

    python3 -m pip install -t pylib beautifulsoup4 lxml

    if [ ! -s "${ZIM_FILENAME}" ]
    then
        download_if_not_found
    fi

    if [ ! -s "${EXTRACTED_DIR}" ]
    then
        decompress_zim
    fi

    if [ ! -s "${ENGLISH_WORDLIST}" ]
    then
        find_english_entries
    fi

    if [ ! -s "${ENGLISH_DIR}" ]
    then
        move_english_entries
    fi

    find "${EXTRACTED_DIR}"/ -mindepth 1 -maxdepth 1 -type d -exec rm -r {} \;

    if [ ! -s "${ENGLISH_DIR}"/slim ]
    then
        trim_html_files
        remove_encoded_slashes
    fi
}


get_parts_of_speech() {
    # Extract `xxx` and `yyy` from `xxx:id="yyy"`.
    # The `xxx` is the file name and `yyy` is the part of speech.
    local POS_EXTRACTION_FROM_HTML='s/([^:]+)[^"]+"([^"]+).+/\1\t\2/'
    # Some words have several senses of the same part of speech.
    # In this case, the senses are suffixed with `_<number>`.
    local ENUMERATION_REMOVAL='s/_[0-9]+$//g'
    # Remove `a/b/c/` from `a/b/c/y`.
    local DIRNAME_REMOVAL='s#.+/([^/]+$)#\1#'

    find "${ENGLISH_DIR}"/A -type f -iregex '.*.*' \
        | parallel -N10000 -j"${N_JOBS}" 'grep -oE "id=\"[^\"]+\""' \
        | tr '[:upper:]' '[:lower:]' \
        | grep -f "${PARTS_OF_SPEECH_PATTERNS}" -F \
        | sed -r \
            -e "${POS_EXTRACTION_FROM_HTML}" \
            -e "${ENUMERATION_REMOVAL}" \
            -e "${DIRNAME_REMOVAL}"
}


get_synonyms() {
    find "${ENGLISH_DIR}"/A -type f \
        | parallel --pipe -N10000 -j"${N_JOBS}" 'python3 scripts/wiktionary_nyms.py syn'
    find "${ENGLISH_DIR}"/A -type f -regex '.*Thesaurus.*' \
        | parallel --pipe -N10000 -j"${N_JOBS}" 'python3 scripts/wiktionary_nyms.py thes_syn'
}


get_pronunciations() {
    # Extract `xxx` and `yyy` from `xxx:class="IPA">yyy<`.
    # The `xxx` is the file name and `yyy` is the IPA string.
    local IPA_EXTRACTION_FROM_HTML='s/([^:]+)[^>]+>([^<]+).+/\1\t\2/'
    # Remove `a/b/c/` from `a/b/c/y\tz`.  Here, `z` may have slashes.
    local DIRNAME_REMOVAL='s#[^\t]+/([^\t]+\t.+)#\1#'

    find "${ENGLISH_DIR}"/A -type f \
        | parallel -N10000 -j"${N_JOBS}" 'grep -Eo "class=\"IPA\">[^-][^<]+</span>"' \
        | tr '[:upper:]' '[:lower:]' \
        | sed -r \
            -e "${IPA_EXTRACTION_FROM_HTML}" \
            -e "${DIRNAME_REMOVAL}" \
            -e "s/$/\tipa\t0/"
}


get_definitions() {
    export PYTHONPATH=pylib
    find "${ENGLISH_DIR}"/A -type f \
        | parallel --pipe -N10000 -j"${N_JOBS}" 'python3 scripts/wiktionary_definitions.py'
}


main() {
    prepare_prereqs
    get_synonyms
    get_parts_of_speech
    get_pronunciations
    get_definitions
}


main
