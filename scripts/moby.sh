DATA_DIR=data

IPA_PRONUNCIATION_FILE="${DATA_DIR}"/ipa.csv
ARPABET_PRONUNCIATION_FILE="${DATA_DIR}"/arpabet.csv
NEW_POS_FILE="${DATA_DIR}"/pos.csv
SYNONYM_FILE="${DATA_DIR}"/synonyms.csv
DBNAME="${DATA_DIR}"/a.db

MOBY_FILE=moby.tar.Z
MOBY_URL='https://ai1.ai.uga.edu/ftplib/natural-language/moby/moby.tar.Z'
CMUDICT="${DATA_DIR}"/share/ilash/common/Packages/Moby/mpron/cmudict0.3
POS_FILE="${DATA_DIR}"/share/ilash/common/Packages/Moby/mpos/mobyposi.i
SYN_FILE="${DATA_DIR}"/share/ilash/common/Packages/Moby/mthes/mobythes.aur

IPA_FILE=csv.zip
IPA_URL='https://github.com/open-dict-data/ipa-dict/releases/download/1.0/csv.zip'
IPA_CSV="${DATA_DIR}"/csv/en_US.csv


download_file_if_not_found() {
    local URL="${1}"
    local DEST="${2}"
    if [[ ! -f "${DATA_DIR}"/"${DEST}" ]]; then
        wget -P "${DATA_DIR}" "${URL}"
        if [[ ! -f "${DATA_DIR}"/"${DEST}" ]]; then
            echo "Problem downloading from "${URL}""
            exit
        fi
    fi
}


format_as_tsv() {
    # Convert to lower case;
    # convert first space to tab;
    # remove carriage return;
    # remove enumeration of duplicate words.
    tr '[:upper:]' '[:lower:]' \
        | sed -r -e 's/ /\t/' -e 's/\r//g' -e 's/\([0-9]+\)//'
}


get_words() {
    grep -vE '(^#)|(^\W)' "${CMUDICT}" | tr '[:upper:]' '[:lower:]'
}


count_syllables() {
    cut -d' ' -f2- \
        | grep -Eno '[0-9]+' \
        | cut -f1 -d: \
        | uniq -c \
        | sed -r 's/^\s+//' \
        | cut -f1 -d' '
}


insert_pronunciations() {
    get_words | python3 setup.py arpabet | sort -t1 -k1,1 \
        | sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin Pronunciation"
    cat "${IPA_CSV}" | python3 setup.py ipa | sort -t, -k1,1 \
        | sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin Pronunciation"
}


extract_if_not_extracted() {
    if [[ ! -f "${CMUDICT}" ]]; then
        tar -C "${DATA_DIR}" -xf "${DATA_DIR}"/"${MOBY_FILE}"
    fi
    if [[ ! -f "${IPA_CSV}" ]]; then
        unzip -d "${DATA_DIR}" "${DATA_DIR}"/"${IPA_FILE}"
    fi
}


setup_files() {
    download_file_if_not_found "${MOBY_URL}" "${MOBY_FILE}"
    download_file_if_not_found "${IPA_URL}" "${IPA_FILE}"
    extract_if_not_extracted
}


read_parts_of_speech() {
    sed -r 's/\r/\n/g' "${POS_FILE}" \
        | sed -r -e 's/\xd7/\t/'
}


get_parts_of_speech_words() {
    read_parts_of_speech | cut -f1 | tr '[:upper:]' '[:lower:]'
}


get_parts_of_speech() {
    read_parts_of_speech | cut -f2 | sed -r 's/(.)/\1\t/g'
}


insert_parts_of_speech() {
    paste <(get_parts_of_speech_words) <(get_parts_of_speech) \
        | python3 setup.py pos \
        | sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin PartOfSpeech"
}


insert_synonyms() {
    sed -r 's/\r/\n/g' "${SYN_FILE}" | python3 setup.py syn \
        | sqlite3 "${DBNAME}" '.mode csv' ".import /dev/stdin Synonym"
}


make_db() {
    sqlite3 "${DBNAME}" '
CREATE TABLE IF NOT EXISTS Pronunciation (
    word TEXT,
    pronunciation TEXT,
    type TEXT,
    n_syllables INT,
    primary key (word, pronunciation)
);
CREATE INDEX IF NOT EXISTS Pronunciation_word ON Pronunciation (word);

CREATE TABLE IF NOT EXISTS PartOfSpeech (
    word TEXT,
    pos TEXT,
    PRIMARY KEY (word, pos)
);

CREATE TABLE IF NOT EXISTS Synonym (
    word1 TEXT,
    word2 TEXT,
    PRIMARY KEY (word1, word2)
);
    '
}


get_roget() {
ROGET_FILE=data/share/ilash/common/Packages/Moby/mthes/roget13a.txt
# TODO: 
# done: check for parts of speech that are not at the beginning
#   of a line
# done: replace `(see` with `&c`
# done: check for words not separated by commas (maybe they were
#   separated by newlines in the raw text?)
    sed -r \
	    -e 's/\(see falsehood\)/\&c.(falsehood)/g' \
	    -e 's/upharson" \[Old Testament\]\./upharson" /g' \
	    -e 's/endure" \[Shelley\];/endure" /g' \
	    -e 's/noon" \[Milton\];/noon" /g' \
	    -e 's/repose" \[Henry VIII\]\./repose" /g' \
	    -e 's/repose" \[Thompson\];/repose" /g' \
	    -e 's/bygone superstitions:-/bygone superstitions:/g' \
	    -e 's/she, her, hers.'"'"'/she, her, hers./g' \
	    -e 's/screen.'"'"'/screen./g' \
	    -e 's/effervescence.'"'"'/effervescence./g' \
	    -e 's/cushiony\[obs3\].'"'"'/cushiony[obs3]./g' \
	    -e 's/"slow-consuming age"'"'"'/"slow-consuming age"/g' \
	    -e 's/progressive\. -/progressive./g' \
	    -e 's/\(sponge\) 252a./sponge/g' \
	    -e 's/\(perseverence\) 604a/,perseverence,/g' \
	    -e 's/      ?v\./     V./g' \
	    -e 's/Reasoning, -- N./Reasoning. -- N./g' \
	    -e 's/hold- a course/hold a course/g' \
	    -e 's/laevo-\./laevo./g' \
	    -e 's/leuco-/leuco/g' \
	    -e 's/sesqui-/sesqui/g' \
	    -e 's/-;/;/g' \
	    -e 's/-\././g' \
	    -e 's/,\s*-/, /g' \
	    -e 's/dextro-/dextro/g' \
	    -e 's/- as a/as a/g' \
	    -e 's/- cineri/ cineri/g' \
	    -e 's/-,/,/g' \
	    -e 's/, -blow/, blow/g' \
	    -e 's/bend -/bend/g' \
	    -e 's/No\. 2 oil/Number 2 oil/g' \
    -e 's/3\.2 beer/beer/g' \
    -e 's/1 beneath/beneath/g' \
    -e 's/xenogenesis1/xenogenesis/g' \
    -e 's/astrology1/astrology/g' \
    -e 's/palaetiology1/palaetiology/g' \
    -e 's/location 184/location/g' \
    -e 's/\[[^]]+\]//g' \
    -e 's/&[ex]/\&c./g' \
    -e 's/&\.\s*v/\&c./g' \
    -e 's/&,,c\./\&c/g' \
    -e 's/&,:c\./\&c/g' \
    -e 's/(disagreeable) c\./\1./g' \
    -e 's/7c\./\&c./g' \
    -e 's/\|!?//g' \
	    -e 's/^Absolute//' \
	    -e 's/(2. Transfer of Property)/% \1\n%/' \
	    -e 's/(4. MODAL EXISTENCE)/% \1\n%/' \
	    -e 's/(3. CONJUNCTIVE QUANTITY)/% \1%\n/' \
	    -e 's/(4. CONCRETE QUANTITY)/% \1%\n/' \
	    -e 's/(SECTION II. RELATION)/% \1/' \
	    -e 's/(\. 1\. ABSOLUTE RELATION)/\1\n%/' \
	    -e 's/(SECTION IV\. ORDER)/% \1/' \
		    -e 's/^(1\. ORDER)//' \
-e 's/(2. CONSECUTIVE ORDER)/% \1/' \
-e 's/(4. DISTRIBUTIVE ORDER)/% \1/' \
-e 's/(5. ORDER AS REGARDS CATEGORIES)/% \1/' \
-e 's/(2. Subservience to Ends)/% \1/' \
-e 's/(5. EXTRINSIC AFFECTIONS)/% \1/' \
-e 's/(3. COLLECTIVE ORDER)/\n\n% \1\n%/' \
-e 's/(1. NUMBER, IN THE ABSTRACT)/\n% \1\n%/' \
-e 's/SECTION V. NUMBER//' \
-e 's/(2.  CONNECTION BETWEEN CAUSE AND EFFECT)/\n% \1\n%/' \
-e 's/(2. RELATIVE SPACE)/\n% \1\n%/' \
-e 's/(3. EXISTENCE IN SPACE)/\n% \1\n%/' \
-e 's/3.  CENTRICAL DIMENSIONS//' \
-e 's/^1\.  General\./3.  CENTRICAL DIMENSIONS/' \
-e 's/(3. IMPERFECT FLUIDS)/\n% \1\n%/' \
-e 's/(\(i\) LIGHT IN GENERAL)//' \
-e 's/(SECTION VII.  CREATIVE THOUGHT)/\n% \1\n%/' \
-e 's/(DIVISION \(II\) COMMUNICATION OF IDEAS)//' \
-e 's/(SECTION I. NATURE OF IDEAS COMMUNICATED.)/\n% \1\n%/' \
-e 's/(SECTION II.  MODES OF COMMUNICATION)/\n% \1\n%/' \
-e 's/(4. MORAL PRACTICE)/\n% \1\n%/' \
-e 's/(Various Qualities of Style)/\n% \1\n%/' \
	    -e 's/\{ant\. of 388\}/ -- N./g' \
	    -e 's/--  end  --//g' \
	    -e 's/^ +(CLASS I)\s*$/% \1/g' \
        -e 's/copy\. Phr\./copy.\n      Phr./g' \
        -e 's/^Phr\./\n      Phr./g' \
	    -e 's/(^.+)Adv\./\1\n      Adv./g' \
        -e 's/^V\./      V/g' \
        -e 's/^Adv/      Adv/g' \
        -e 's/^Adj/      Adj/g' \
        -e 's/mull. Adj/mull.\n      Adj/g' \
        -e 's/1The/The/g' \
	-e 's/(^ +)(252a )/\1#\2/g' \
        -e 's/4O8/408/g' \
        -e 's/5O8/508/g' \
        -e 's/"wolf!'"'"'/"wolf!"/' \
	-e 's/(Contrariety\.) N\./\1 -- N./' \
        -e 's/(\{ant. of 388\})/\1 -- N. /' \
        -e 's/&c\.?\s*[aA]dj\.?;/;/g' \
        -e 's/&c\.?\s*[vVnN]\.?;/;/g' \
	-e 's/(Contrariety.) N. (contrariety)/\1 -- N. \2/g' \
	-e 's/(%)/     \1\n/g' \
	data/share/ilash/common/Packages/Moby/mthes/roget13a.txt \
        | python3 join_roget.py \
	| sed -r \
-e 's/(Subtraction\.) - N\./\1 --N./' \
-e 's/(Incoherence\.) - N\./\1 --N./' \
-e 's/(Liquefaction\.) -N\./\1 --N./' \
-e 's/(Vision\.) - N\./\1 --N./' \
-e 's/(Blindness\.) - N\./\1 --N./' \
-e 's/(er Evidence\.) - N\./\1 --N./' \
-e 's/<--[^>]+-->//g' \
        | python3 roget.py \
        | sed -r \
            -e 's/&c\.?\s*[aA]dj\.?;/;/g' \
            -e 's/&c\.?\s*[vVnN]\.?;/;/g' \
	    -e 's/&c\S*\s*adj([.;]*)\s*$/\1/g' \
	    -e 's/&c\S*\s*adj[. ,]*([;%])/\1/g' \
	    -e 's/&c.*\s*adj\.?\s*([0-9])/\&c. \1/g' \
	    -e 's/&c\. adj\.- of/./g' \
	    -e 's/&c. adj\.,/,/g' \
	    -e 's/irritable &c. adj. temper/irritable temper/g' \
	    -e 's/be incumbent &c. adj. on/be incumbent on/g' \
	    -e 's/be due &c. adj. to/be due to/g' \
	    -e 's/&c. adj. ([^(])/,\1/g' \
	    -e 's/&c. n.,/,/g' \
	    -e 's/&c. v.,/,/g' \
	    -e 's/&c. adv.;/;/g' \
	    -e 's/&c. adv.$/./g' \
	    -e 's/&c. Adj.\s*(;)?$/\1/g' \
	    -e 's/&c. Adj./,/g' \
	    -e 's/&c. adj\[[^]]+].?/./g' \
	    -e 's/&c. v([;. ]+)$/\1/g' \
	    -e 's/&c. v[. ]+([;:)%])/\1/g' \
	    -e 's/burning &c. v. hot/burning hot/g' \
	    -e 's/&c. v. \(see touch 379\)/\&c. touch 379/g' \
	    -e 's/&c. v./,/g' \
	    -e 's/&c. n([;. ]+)$/\1/g' \
	    -e 's/&c. n[. ]+([;:)%])/\1/g' \
	    -e 's/c. n.-? of/of/g' \
	    -e 's/claim relationship with &c. n. with/claim relationship with/g' \
	    -e 's/&c. n[. ]+for/for/g' \
	    -e "s/be one's fate &c. n./be one's fate,/g" \
	    -e 's/&c. n.\s*to/to,/g' \
	    -e 's/in abundance &c. n./in abundance,/g' \
	    -e 's/&c. n. with/with/g' \
	    -e 's/pleasure &c. n.\s*((in)|(from))/pleasure \1/g' \
	    -e 's/fall into  a place &c. n./fall into a place/g' \
	    -e 's/&c. n./,/g' \
	    -e 's/&c[. ]*;/;/g' \
	    -e 's/&c.,\s*n\././g' \
	    -e 's/&c.,\s*etc\././g' \
	    -e 's/&c.,/,/g' \
	    -e 's/&c.\s*v\././g' \
	    -e 's/&cv\. v/./g' \
	    -e 's/&c.v\[obs3\]/./g' \
	    -e 's/&c\.n\././g' \
	    -e 's/&c\.\[obs3\]/./g' \
	    -e 's/&c\.$/./g' \
	    -e 's/&c\.\]/]/g' \
	    -e 's/&c\.\s*@[.0-9]+/./g' \
	    -e 's/&c\.?\s*((adj\.)|(ad \.))/./g' \
	    -e 's/&c\.?\s*(adj\[)/[/g' \
	    -e 's/&c[. ]*[aA]dv(\.|\[)/\1/g' \
	    -e 's/&c\.  n of/of/g' \
	    -e 's/&can\./\& Canada/g' \
	    -e 's/ten &c. to one/ten to one/g' \
	    -e 's/&c[. ]*of/of/g' \
	    -e 's/&c[. ]*for/for/g' \
	    -e 's/&c. in for/in for/g' \
	    -e 's/&c[. ]*all/all/g' \
	    -e 's/&c[. ]*\[/[/g' \
	    -e 's/(&c\.)\./\1/g' \
	    -e 's/(&c.) c. (250)/\1 \2/g' \
	    -e 's/(&c[. ]*)\*\(/\1 (/g' \
	    -e 's/(&c) /\1. /g' \
	    -e 's/(&c\.) &c\./\1/g' \
	    -e 's/(&c),\.?/\1./g' \
	    -e 's/(&c\.)\s*\./\1/g' \
            -e 's/paying &c. paid/paying, paid/' \
            -e 's/vital &c. importance/vital importance/' \
            -e 's/be in love &c. with adj./be in love with./' \
            -e 's/caressed &c. V./caressed/' \
            -e 's/rend &c. rend asunder/rend, rend asunder/' \
            -e 's/contend &c. with/contend with/' \
            -e 's/cousin twice &c. removed/cousin twice removed/' \
            -e 's/good penny &c. worth/good penny worth/' \
            -e 's/ailing &c. " all/ailing, " all/' \
            -e 's/flame &c. color, adj./flame color/' \
            -e 's/pencil &c. drawing/pencil drawing/' \
            -e 's/ichthy &c. ichthyotomy/ichthy, ichthyotomy/' \
            -e 's/last but two, &c. unbegun/last but two, unbegun/' \
            -e 's/insert &c. itself/insert itself/' \
            -e 's/penny &c. worth/penny worth/' \
            -e 's/worldly &c. minded/worldly minded/' \
            -e 's/thousandth, &c./thousandth/' \
            -e 's/oil paint &c. painting  556/oil paint, \&c. (painting)  556/' \
            -e 's/discover &c. itself/discover itself/' \
	    -e 's/(&c\.) +/\1/g' \
	    -e 's/(&c.)(touch)/\1(\2)/' \
	    -e 's/(&c.)(determination)/\1(\2)/' \
	    -e 's/(&c.)(press)/\1(\2)/' \
	    -e 's/(&c.)(deteriorated)/\1(\2)/' \
	    -e 's/(&c.)(anchor)/\1(\2)/' \
	    -e 's/(&c.)one.s (\(originate\) 153)/\1\2/' \
            -e 's/(compromise) (&c.774) (neutralization)/\1 \2, \3/' \
            -e 's/(interpolation) (&c.228) (adulteration)/\1 \2, \3/' \
            -e 's/(follow) (&c.281) (after)/\1 \3 \2/' \
            -e 's/(use) (&c.677) (an opportunity)/\1 \3 \2/' \
            -e 's/(give) (&c.784) (an opportunity)/\1 \3 \2/' \
            -e 's/(neglect) (&c.460) (an opportunity)/\1 \3 \2 /' \
            -e 's/(customary) (&c.613) (habit 613)/\1 \2, \3/' \
            -e 's/(as chance) (&c.156) (would have it)/\1 \3 \2/' \
            -e 's/(increase) (&c.35) (of size)/\1 \3 \2/' \
            -e 's/(decrease) (&c.36) (of size)/\1 \3 \2/' \
            -e 's/(throw) (&c.284) (throw out)/\1 \2, \3/' \
            -e 's/(push) (&c.276) (throw out)/\1 \2, \3/' \
            -e 's/(baking) (&c.384) (heat)/\1 \3 \2/' \
            -e 's/(gurgle) (&c.405) (plash)/\1 \2, \3/' \
            -e 's/(vindication) (&c.937) (counter protest)/\1 \2, \3/' \
	    -e 's/(ontention) (&c.720) (logomachy)/\1 \2, \3/' \
	    -e 's/(bliteration) (&c.552) (of)/\1 \3 \2/' \
            -e 's/(verify) (&c.467) (settle the question)/\1 \2, \3/' \
            -e 's/(insensibility) (&c.823) (to the past)/\1 \3 \2/' \
            -e 's/(insensible) (&c.823) (to the past)/\1 \3 \2/' \
            -e 's/(not wonder) (&c.870) (at)/\1 \3 \2/' \
            -e 's/(honest) (&c.543) (m)/\1 \3 \2/' \
            -e 's/(the meaning) (&c.516) (of)/\1 \3 \2/' \
            -e 's/(tell the cause) (&c.153) (of)/\1 \3 \2/' \
            -e 's/(repentance) (&c.950)- (redintegratio)/\1 \2, \3/' \
            -e 's/(come short of) (&c.304) (run dry)/\1 \2, \3/' \
            -e 's/(retrograde) (&c.283)- (decl)/\1 \2, \3/' \
            -e 's/(ize the opportunity) (&c.134) (lose no time)/\1 \2, \3/' \
            -e 's/(exact) (&c.494) - (observance)/\1 \3 \2/' \
            -e 's/(be the possessor) (&c.779) (of)/\1 \3 \2/' \
            -e 's/(have given) (&c.784) (to one)/\1 \3 \2/' \
            -e 's/(check) (&c.751) (check oneself)/\1 \2, \3/' \
            -e 's/(be pleased) (&c.829) (with)/\1 \3 \2/' \
            -e 's/(make friends) (&c.890) (with)/\1 \3 \2/' \
            -e 's/(lament) (&c.839) (with)/\1 \3 \2/' \
            -e 's/find out &c.480a &c.516 the meaning of/find out the meaning of &c.480a &c.516/' \
            -e 's/(taliation) (&c.718) (equ)/\1 \2, \3/' \
            -e 's/(property) (&c.780) and G/\1 \2, G/' \
            -e 's/(spectator) (&c.444) (of)/\1 \3 \2/' \
            -e 's/(find out) (&c.480a) (the m)/\1 \3 \2/' \
            -e 's/(favorable) (&c.707) (to)/\1 \3 \2/' \
            -e 's/(coxcomb) (&c.854) S/\1 \2, S/' \
            -e 's/(shrill) (&c.410) (clamorous)/\1 \2, \3/' \
            -e 's/(&c.vociferous +411) +(stentorian)/\1, \2/' \
	    -e 's/&c[^(]*\(([^)]+)(&c\.)([^)]*)\)/\&c.(\1, \3)/g' \
	    -e 's/larger &c.\(large &c.192;/larger \&c.(large 192)/' \
-e 's/(under +the +head +of +&c.\(class\) +75) +of/\1/' \
-e 's/(akin to &c.\(consanguineous\) 1) 1/\1/' \
-e 's/(seize) &c.\(take\) 789 (an opportunity)/\1 \2, take \2 \&c.789/' \
-e 's/&c.\(receptacle\) 191 of/\&c.(receptacle)191/' \
-e 's/put a mark &c.\(sign\) 550 upon/put a mark upon, \&c.(sign)550/' \
-e 's/&c.\(neglect\) 460 a distinction/neglect a distinction, \&c.460/' \
-e 's/the m &c.480aeaning of/the meaning of, \&c.480,/' \
-e 's/(&c.\(warfare\) 722) -with/\1/' \
-e 's/linked &c.\(joined\) 43- together/linked together, joined together \&c.(joined)43/' \
-e 's/&c.\(unimportance\) 643 for/unimportance for \&c.643/' \
-e 's/(&c.613 +\(habit\)) +613/\&c.613(habit)/' \
-e 's/true &c.\(exact\) 494 meaning/true meaning, \&c.(exact)494/' \
-e 's/(&c\.\([^)]+\)\s*[0-9]+[a-zA-Z]*)\s+/\1,/g' \
    -e 's/(larger) (&c.\(large 192\)) (swollen)/\1, \2, \3/' \
    -e 's/(mean) (&c.29) (middle)/\1, \2, \3/' \
	-e 's/\(see (falsehood)/\&.(\1/' \
	-e 's/\(see /(/g' \
	| sed -r 's/(&c\.)(\([^)]+\))\s*(\[[^]]+\])\s*([;.,:])\s*([0-9]+[a-zA-Z]*)/\1\2\3\5\4/g' \
	| sed -r 's/(&c\.)(\([^)]+\))\s*([;.,:])\s*([0-9]+[a-zA-Z]*)/\1\2\4\3/g' \
	| sed -r -e 's/(&c\.\([^)]+\))\s*&c/\1, \&c/g' \
-e 's/(\[[^]]+)(&c\.\s*[0-9]+[a-zA-Z]*)(\])/\1 \2.\3/' \
-e 's/(\([^)]+)(&c\.\s*[0-9]+[a-zA-Z]*)(\))/\1 \2.\3/' \
-e 's/&c\.\(([ a-zA-Z'"'"'-]+)\.\)/\&c.(\1)/' \
-e 's/&c\.\(sun\[obs3\], light, , 423\)/sun[obs3], light,/' \
| sed -r 's/&c\.\((['"'"' ,a-zA-Z-]+)\)[^;:,.]*([:;,.]|$)/. \1, /g' \
| sed -r 's/&c\.[0-9]+[a-zA-Z]*([;:,.]|[^;:,.]+)/./g' \
| sed -r 's/&c\.\((['"'"' ,a-zA-Z-]+)[0-9]+\)[^;:,.]*([:;,.]|$)/\1 . \2/g' \
    | sed -r \
    -e 's/%.*[0-9]+[^]]\W+/% /i' \
    -e 's/%(.*)\([^)]+\)(.*)/% \1 \2/gi' \
    -e 's/%.*section\s*(i+|iv|vi+|v|ill)\W+/% /i' \
    -e 's/(^%[^%]+)%/\1/' \
    -e 's/(^%[ a-zA-Z]+)\W+$/\1/' \
    -e 's/(^%.+)\[obs3\]/\1/' \
    | python3 remove_comments.py \
    | sed -r -e 's/(\(heat air)/\1)/' \
    | sed -r 's/\(([^)]+)\)\s*[0-9]+/,\1,/g' \
    | sed -r 's/\{[^\}]+\}/ /g' \
    | sed -r 's/\([^)]+\)//g' \
    | sed -r \
    -e 's/be\s*-\s*(\w)/be \1/g' \
    -e 's/one'"'"'s\s*-\s*fate/one'"'"'s fate/g' \
    -e 's/to an\s*-\s*end/to an end/g' \
    -e 's/regular\s*-\s*steps/regular steps/g' \
    -e 's/the\s*-\s*agency\s*&of/the agency of/g' \
    -e 's/draw- to a -close/draw to a close/g' \
    -e 's/any\s*-\s*time/any time/g' \
    -e 's/\*//g' \
    -e 's/have -influence/have influence/g' \
    -e 's/have in- petto/have in petto/g' \
    -e 's/have no -brains/have no brains/g' \
    -e 's/have no -influence/have no influence/g' \
    -e 's/not an -illusion/not an illusion/g' \
    -e 's/not -bright/not bright/g' \
    -e 's/there is -no question/there is no question/g' \
    -e 's/want of - intellect/want of intellect/g' \
    -e 's/want of -intelligence/want of intelligence/g' \
    -e 's/without a grave- unknell'"'"'d/without a grave unknell'"'"'d/g' \
    -e 's/without- foundation/without foundation/g' \
    -e 's/whip c\./whip/g' \
    -e 's/( -)|(- )|( - )/-/g' \
    -e 's/@[.0-9]+/,/g' \
    -e 's/&v//g' \
    -e 's/dark 421/dark/g' \
    -e 's#point system: 4-1/2, 5, 5-1/2, 6, 7, 8 point, etc.#point system#' \
-e 's/combination 48/combination/' \
-e 's/causation 153/causation/' \
-e 's/attribution 155/attribution/' \
-e 's/inattentive 458/inattentive/' \
    -e 's/raise 307/raise/' \
    -e 's/unpassable2/unpassable/' \
    -e 's/see Answer 462//' \
    -e 's#<gr/[^/]+/(gr)?>##' \
    -e 's/environment 229a/environment/' \
    -e 's/discrimination 465/discrimination/' \
    -e 's/indiscrimination 465a/indiscrimination/' \
    -e 's/identification 465b/identification/' \
    -e 's/(bear the impress) &of/\1 of/' \
    -e 's/(be the due) &of/\1 of/' \
    -e 's/(be the sign) &of/\1 of/' \
    -e 's/(come to the aid) &of/\1 of/' \
    -e 's/(in corroboration) &of/\1 of/' \
    -e 's/(restlessness) &c/\1/' \
    -e 's/\[[^]]+\]//g' \
    -e 's/e\.\s*g\./e.g./g' \
    -e 's/A\.\s*B\./A.B./g' \
    -e 's/D\.\s*V\./D.V./g' \
    -e 's/([a-zA-Z])\.([a-zA-Z])\.([a-zA-Z])\.([a-zA-Z])\./ACRONYM\1\2\3\4ACRONYM/g' \
    -e 's/([a-zA-Z])\.([a-zA-Z])\.([a-zA-Z])\./ACRONYM\1\2\3ACRONYM/g' \
    -e 's/([a-zA-Z])\.([a-zA-Z])\./ACRONYM\1\2ACRONYM/g' \
    | python3 group_roget.py 
}

insert_parts_of_speech_roget() {
    get_roget | python3 roget_syn.py pos
}


insert_synonyms_roget() {
    get_roget | python3 roget_syn.py syn
}
#exit
#N=0
#C_CONTEXT='(^|([^&]*))&c[^&]+'
#END='([;.,:]|$)'
#ID='[0-9]+[a-zA-Z]*'
#BRACKETS='(\[[^]]+\])+'
#PARENS='\([^)]+\)'
#EMBEDDED_ID='\([^)]+'"${ID}"'[^)]+\)'
#echo 'id := '"${ID}"
#echo 'end := '"${END}"
#echo 'brackets := '"${BRACKETS}"
#echo 'parens := '"${PARENS}"
#echo 'embeddedid := '"${EMBEDDED_ID}"
#
#PATTERN_ID_END='&c\.'"${ID}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo '&c[^&]+' \
#    | grep -E "${PATTERN_ID_END}" \
#    | wc -l)
#echo '&c.id_end: '"${M}"
#N=$((N + M))
#
#PATTERN_PARENS_END='&c\.'"${PARENS}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_PARENS_END}" \
#    | wc -l)
#echo '&c.(_)_end: '"${M}"
#N=$((N + M))
#
#PATTERN_ID_BRACKETS_END='&c\.'"${ID}"'\s*'"${BRACKETS}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E  "${PATTERN_ID_BRACKETS_END}"\
#    | wc -l)
#echo '&c.id_[_]_end: '"${M}"
#N=$((N + M))
#
#PATTERN_ID_PARENS_END='&c\.'"${ID}"'\s*'"${PARENS}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_ID_PARENS_END}" \
#    | wc -l)
#echo '&c.id_(_)_end: '"${M}"
#N=$((N + M))
#
#PATTERN_PARENS_ID_END='&c\.'"${PARENS}"'\s*'"${ID}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_PARENS_ID_END}" \
#    | wc -l)
#echo '&c.(_)_id_end: '"${M}"
#N=$((N + M))
#
#PATTERN_PARENS_ID_BRACKETS_END='&c\.'"${PARENS}"'\s*'"${ID}"'\s*'"${BRACKETS}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_PARENS_ID_BRACKETS_END}" \
#    | wc -l)
#echo '&c.(_)_id_[_]_end: '"${M}"
#N=$((N + M))
#
#PATTERN_EMBEDDEDID_END='&c\.'"${EMBEDDED_ID}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_EMBEDDEDID_END}" \
#    | wc -l)
#echo '&c.(_id_)_end: '"${M}"
#N=$((N + M))
#
#PATTERN_EMBEDDEDID_BRACKETS_END='&c\.'"${EMBEDDED_ID}"'\s*'"${BRACKETS}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_EMBEDDEDID_BRACKETS_END}" \
#    | wc -l)
#echo '&c.(_id_)_[_]_end: '"${M}"
#N=$((N + M))
#
#PATTERN_PARENS_BRACKETS_ID_END='&c\.'"${PARENS}"'\s*'"${BRACKETS}"'\s*'"${ID}"'\s*'"${END}"
#M=$(get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -E "${PATTERN_PARENS_BRACKETS_ID_END}" \
#    | wc -l)
#echo '&c.(_)_[_]_id_end: '"${M}"
#N=$((N + M))
#
#echo "${N}"
#
#get_roget \
#    | grep -Eo "${C_CONTEXT}" \
#    | grep -Ev "${PATTERN_PARENS_END}" \
#    | grep -Ev "${PATTERN_PARENS_ID_END}" \
#    | grep -Ev "${PATTERN_ID_PARENS_END}" \
#    | grep -Ev "${PATTERN_ID_BRACKETS_END}" \
#    | grep -Ev "${PATTERN_ID_END}" \
#    | grep -Ev "${PATTERN_PARENS_ID_BRACKETS_END}" \
#    | grep -Ev "${PATTERN_EMBEDDEDID_BRACKETS_END}" \
#    | grep -Ev "${PATTERN_EMBEDDEDID_END}" \
#    | grep -Ev "${PATTERN_PARENS_BRACKETS_ID_END}"
##echo 'complement: '"${M}"
#exit


insert_synonyms_oxford() {
    setup_oxford | python3 oxford_group.py | cut -f1,2
}


insert_parts_of_speech_oxford() {
    setup_oxford | python3 oxford_group.py | cut -f1,3
}


oxford_enclose_crossref() {
    sed -r 's/(See [0-9]+)\.(\(.\))/\1 \2,/g' \
        | sed -r 's/([0-9]+)\.([0-9]+)/\1*\2/g' \
        | sed -r 's/(See [a-z-]+\.)|(See[^.:]+((above)|(below))[.:])|(\(See also[^)]+\))|(See [a-z]+[, 0-9]+\.)|(See +[0-9]+(\(.\))?\.)|(See ineffectual and ineffective\.)|(See access,)/{&}/g'
}


oxford_label_senses() {
    sed -r \
        -e 's/ [0-9]+ /SENSE/g' \
        -e 's/ +/ /g' \
        | sed -r \
            -e 's/(a cappella)/,DUMMY\1/' \
            -e 's/, (a lot)/, DUMMY\1/' \
        | sed -r 's/\W ([a-z] )+/. SUBGROUP /g' \
	| sed -r 's/DUMMY//g'
}


oxford_remove_elements() {
    sed -r \
        -e 's/\([^)]+\)//g' \
        -e 's/<[^>]+>/ /g' \
        -e 's/\{[^}]+\}/ /g' \
        -e 's/\[[^]]+\]/ /g'
}


oxford_enclose_label() {
	    sed -r 's/(<[^>]+)Sports ([^>]+>)/\1 Climbs \2/g' \
	    | sed -r 's/(<[^>]+)Irish([^>]+>)/\1 Esperanto \2/g' \
	    | sed -r 's/(<[^>]+)English([^>]+>)/\1 Esperanto \2/g' \
	    | sed -r 's/(<[^>]+)US([^>]+>)/\1 USA \2/g' \
	    | sed -r 's/(<[^>]+)Scots ([^>]+>)/\1 Scottish \2/g' \
	    | sed -r 's/(<[^>]+)Australian([^>]+>)/\1 Aussie \2/g' \
	    | sed -r 's/(<[^>]+)New Zealand([^>]+>)/\1 NZ \2/g' \
	    | sed -r 's/(<[^>]+)Canadian([^>]+>)/\1 CAN \2/g' \
	    | sed -r 's/(<[^>]+)Welsh([^>]+>)/\1 Gaelic \2/g' \
	    | sed -r 's/(<[^>]+)Usually([^>]+>)/\1 Typically \2/g' \
	    | sed -r 's/(<[^>]+)Often([^>]+>)/\1 Oftentimes \2/g' \
	    | sed -r 's/(<[^>]+)Military([^>]+>)/\1 Armed \2/g' \
	    | sed -r 's/(<[^>]+)Formal ([^>]+>)/\1 The formal \2/g' \
	    | sed -r 's/(<[^>]+)Law ([^>]+>)/\1 Law-\2/g' \
	    | sed -r 's/(<[^>]+)French ([^>]+>)/\1 Esperanto \2/g' \
	    | sed -r 's/(<[^>]+)Sometimes([^>]+>)/\1 At times \2/g' \
	    | sed -r 's/(<[^>]+)Rather([^>]+>)/\1 Preferring more \2/g' \
	    | sed -r 's/(<[^>]+)Music ([^>]+>)/\1 Some music \2/g' \
	    | sed -r 's/(<[^>]+)Buddhism ([^>]+>)/\1 Satanism \2/g' \
	    | sed -r 's/(<[^>]+)Naval ([^>]+>)/\1 Some \2/g' \
	    | sed -r 's/(<[^>]+)Printing ([^>]+>)/\1 Laminating \2/g' \
	    | sed -r 's/2 often/2 /g' \
	    | sed -r 's/often derogatory/ Often Derogatory /g' \
	    | sed -r 's/often liberties/liberties/g' \
	    | sed -r 's/Also,//g' \
	    | sed -r 's/\(In [^)]+\)//g' \
	    | sed -r -e 's/(Colloq )|(US )|(Brit )|(Scots )|(Australian )|(New Zealand)|(Canadian )|(Taboo (slang)?)|(Slang )|(Welsh )|(Technical )|(Chiefly )|(Archaic )|(Usually,? )|(Literary )|(Often,? )|(Military )|(Old-fashioned )|(Nautical )|(Rare )|(Formal )|(Sometimes,? )|(Rather [a-z-]+)|(Derogatory )|(No\. Eng\. (dialect)?)|(Dialect )|(English )|(Irish )|(Law )|(French )|(Facetious )|(Non-Standard )|(Euphemistic )|(Offensive )|(Medicine )|(Loosely )|(Historical )|(South African )|(Music )|(Archaeology )|(Archery )|(Golf )|(Hinduism )|(Tibetan )|(Buddhism )|(Humorous )|(Hyperbolic sports jargon )|(Immunology )|(Mechanics )|(Metaphysics )|(Naval )|(Nontechnical )|(Pathology )|(Philosophy )|(Printing )|(Psych jargon )|(Psychology )|(Publishing )|(Rhetoric )|(Technically inaccurate)|(Baseball )|(Ecclesiastical )|(Imperitive )|(Judaism )|(NE )|(Poetic )|(Sports )|(SW )|(Yiddish )|(Architecture )|(Babytalk )|(Biblical )|(Obsolete )|(Possible offensive )|(Prosody )|(Theatre )|(Typography )|(Cricket )|(Dialectal )|(Jocular )|(All the following are offensive and derogatory)/ [&] /g'

}


oxford_enclose_phrase() {
    sed -r 's/:\s*(['"'"'A-Z-][^.!?]*[.!?]+\s*)+/<&>/g' \
        | sed -r 's/<:/</g' \
        | sed -r 's/:\s*([0-9][^.!?]+[.!?]+\s*)/<&>/g' \
        | sed -r 's/<:/</g' \
        | sed -r 's/\s*>/>/g'
}


setup_oxford() {
    pdftotext -layout ~/Downloads/The\ Oxford\ Thesaurus.pdf - \
        | sed -r \
	    -e 's/\x0c/\n\n/g' \
	    -e 's/threatening: it was/threatening: It was/' \
	    -e 's/\[[^]]+\]//' \
	    -e 's/no elasticity:/no elasticity,/' \
	    -e 's/inert: it was/inert, it was/' \
	    -e 's/for instance: she/for instance, she/' \
	    -e 's/he clouds loured:/he clouds loured,/' \
	    -e 's/little monkey: you/little monkey, you/' \
	    -e 's/every year: it has/every year, it has/' \
	    -e 's/not important: he/not important, he/' \
	    -e 's/accident: you kicked/accident, you kicked/' \
	    -e 's/quandary: should it/quandary, should it/' \
	    -e 's/recant: otherwise,/recant, otherwise,/' \
	    -e 's/passions: it is not/passions, it is not/' \
	    -e 's/old car: nobody wants/old car, nobody wants/' \
	    -e 's/atisfy him: he is/atisfy him, he is/' \
	    -e 's/bathroom scales: the/bathroom scales, the/' \
	    -e 's/scoff: your turn/scoff, your turn/' \
	    -e 's/want to go: first,/want to go, first,/' \
	    -e 's/our pursuers: at last/our pursuers, at last/' \
	    -e 's/theorists: we need/theorists, we need/' \
	    -e 's/home slowly: the accident/home slowly, the accident/' \
	    -e 's/own: she'"'"'s a mere/own, she'"'"'s a mere/' \
	    -e 's/brain\(s\): it would take a/brain(s), it would take a/' \
	    -e 's/not required: you may/not required, you may/' \
	    -e 's/apricious: as Mark/apricious, as Mark/' \
	    -e 's/too often: we'"'"'ll have/too often, we'"'"'ll have/' \
	    -e 's/suggestion: in fact,/suggestion, in fact,/' \
	    -e 's/conditions were ideal: a fresh/conditions were ideal, a fresh/' \
	    -e 's/2 In US: trousers,/2 trousers,/' \
	    -e 's/: allowance, consideration./, allowance, consideration./' \
	    -e 's/building is on fire:/building is on fire,/' \
	    -e 's/No, madam:/No, madam,/' \
	    -e 's/Phone the plumber: the drain/Phone the plumber, the drain/' \
	    -e 's/official:/official,/' \
	    -e 's/piece: document/piece, document/' \
	    -e 's/construct: carve,/construct, carve,/' \
	    -e 's/work and live, etc./work and live./' \
	    -e 's/etc\./etc/g' \
	    -e 's/\-\-he/, he/g' \
	    -e 's/m\.p\.h/mph/g' \
	    -e 's/U\.S\.A\./USA/g' \
	    -e 's/J\.B\./JB/g' \
	    -e 's/M\.I\.([0-9])/MI\1/g' \
	    -e 's/2 Often/2 often/g' \
	    -e 's/'"'"'\s+([0-9]+)/'"'"'. \1/g' \
	    -e 's/:/.:/g' \
	    -e 's/°//g' \
	    -e 's/^[0-9.]+.+//g' \
	    -e 's/(=-)+//g' \
	    -e 's/ n\.phr\./ _nphr /g' \
	    -e 's/ n\., adv\./ _nadv /' \
	    -e 's/adj\., adv\./_adjadv /' \
	    -e 's/( |\-\-\-?)(adj|n|adv|v|pron|prep|conj|interj|interjection|adv\.phr|quasi.adv)\./ _\2 /g' \
	    -e 's/\-\-(attributive)/ _\1/g' \
	    -e 's/Colloq//g' \
	    -e 's/ See 5\./ See 5/g' \
	    | sed -r \
	    -e 's/^ +//' \
	    -e 's/ +/ /g' \
	    | sed -r \
	    -e 's/^([A-Za-z-]+)$/#\1/' \
	    -e 's/^([A-Za-z-]+ [A-Za-z-]+)$/#\1/' \
	    -e 's/^([A-Za-z-]+ [A-Za-z-]+ [A-Za-z-]+)$/#\1/' \
	    | sed -r 's/^([^_]+_)/#\1/' \
	    | sed -r 's/def\.//g' \
	    | sed -r -e 's/^#below$/below./' \
                -e 's/#completely blank/completely blank./' \
	    | python3 oxford_join.py \
	    | oxford_enclose_crossref \
	    | python3 oxford.py pos \
	    | oxford_enclose_phrase \
	    | oxford_enclose_label \
	    | oxford_remove_elements \
            | oxford_label_senses
}


main() {
    mkdir -p "${DATA_DIR}"

    #setup_files
    #make_db
    #insert_pronunciations
    #insert_parts_of_speech
    #insert_synonyms
    ##insert_parts_of_speech_roget
    ##insert_synonyms_roget
    insert_synonyms_oxford
    #insert_parts_of_speech_oxford
}


main
