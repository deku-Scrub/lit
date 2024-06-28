#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source scripts/env

THESAURUS_BASENAME='The Oxford Thesaurus.pdf'
THESAURUS_PDF="${THESAURUS_DIR}"/"${THESAURUS_BASENAME}"


get_synonyms() {
    preprocess | python3 scripts/oxford_group.py | cut -f1,2
}


get_parts_of_speech() {
    preprocess | python3 scripts/oxford_group.py | cut -f1,3
}


enclose_crossref() {
    sed -r 's/(See [0-9]+)\.(\(.\))/\1 \2,/g' \
        | sed -r 's/([0-9]+)\.([0-9]+)/\1*\2/g' \
        | sed -r 's/(See [a-z-]+\.)|(See[^.:]+((above)|(below))[.:])|(\(See also[^)]+\))|(See [a-z]+[, 0-9]+\.)|(See +[0-9]+(\(.\))?\.)|(See ineffectual and ineffective\.)|(See access,)/{&}/g'
}


label_senses() {
    sed -r \
        -e 's/ [0-9]+ /SENSE/g' \
        -e 's/ +/ /g' \
        | sed -r \
            -e 's/(a cappella)/,DUMMY\1/' \
            -e 's/, (a lot)/, DUMMY\1/' \
        | sed -r 's/\W ([a-z] )+/. SUBGROUP /g' \
    | sed -r 's/DUMMY//g'
}


remove_elements() {
    sed -r \
        -e 's/\([^)]+\)//g' \
        -e 's/<[^>]+>/ /g' \
        -e 's/\{[^}]+\}/ /g' \
        -e 's/\[[^]]+\]/ /g'
}


enclose_label() {
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


enclose_phrase() {
    sed -r 's/:\s*(['"'"'A-Z-][^.!?]*[.!?]+\s*)+/<&>/g' \
        | sed -r 's/<:/</g' \
        | sed -r 's/:\s*([0-9][^.!?]+[.!?]+\s*)/<&>/g' \
        | sed -r 's/<:/</g' \
        | sed -r 's/\s*>/>/g'
}


preprocess() {
    pdftotext -layout "${THESAURUS_PDF}" - \
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
        | python3 scripts/oxford_join.py \
        | enclose_crossref \
        | python3 scripts/oxford.py pos \
        | enclose_phrase \
        | enclose_label \
        | remove_elements \
        | label_senses
}


main() {
    get_synonyms
    get_parts_of_speech
}


main
