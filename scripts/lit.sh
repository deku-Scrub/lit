#!/bin/bash
# Client for the lit server.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

source "${SCRIPT_DIR}"/env

BROWSER=w3m
ENDPOINT=''
QUERY=''
QUERY_TYPE=''
ADDRESS="${HOST}":"${PORT}"


display_help() {
    cat <<HEREDOC
Thesaurus, dictionary, reverse dictionary.

Usage
    lit [options]

Options
    -h show this help
    -k kill the server and exit
    -b BROWSER command or path of a web browser to use (default w3m)

Options related to querying
    If multiple query options are given, whichever appears last
    is the query to run.

    -t QUERY query to search for in the thesaurus
    -d QUERY query to search for in the dictionary
    -r QUERY query to search for in the reverse dictionary
HEREDOC
}


is_server_running() {
    echo "$(ss -Htlop | grep -F "${ADDRESS}")"
}


kill_server() {
    if [ -n "$(is_server_running)" ]
    then
        PID="$(is_server_running | grep -oE 'pid=[0-9]+' | grep -oE '[0-9]+')"
        kill -15 "${PID}"
    fi
}


start_server() {
    if [ -z "$(is_server_running)" ]
    then
        bash "${SCRIPT_DIR}"/run_server.sh &
        J=0
        while [ -z "$(is_server_running)" ]
        do
            echo -n "$(jq -rn '"\rwaiting for server to start" + "   "')"
            echo -n "$(jq -rn '"\rwaiting for server to start" + "."*'"$J")"
            sleep 1
            J="$(((J + 1) % 4))"
        done
    fi
}


main() {
    start_server
    "${BROWSER}" http://"${ADDRESS}"/"${ENDPOINT}"
}


OPT=''
while getopts 'hb:t:d:r:k' OPT
do
    case "${OPT}" in
        h|\?)
          display_help
          exit 0
          ;;
        k)
            kill_server
            exit 0
          ;;
        b) BROWSER="${OPTARG}"
          ;;
        t) QUERY="${OPTARG}"
           QUERY_TYPE=t
          ;;
        d) QUERY="${OPTARG}"
           QUERY_TYPE=d
          ;;
        r) QUERY="${OPTARG}"
           QUERY_TYPE=r
          ;;
    esac
done

if [ -n "${QUERY}" ]
then
    # URL-escape the query.
    QUERY="$(echo "${QUERY}" | jq -rR '. | @uri')"
    ENDPOINT='search?q='"${QUERY}"'&t='"${QUERY_TYPE}"
fi

main
