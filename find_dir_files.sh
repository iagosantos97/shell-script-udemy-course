#!/usr/bin/env bash

# VARIÁVEIS 

VERSION="1.0"
AUTHOR="Iago Santos Oliveira"

declare -a EXT

HOST=
WORDLIST=

YELLOW="\033[33;1m"

# FUNÇÕES

show_help() {
    echo -e "Uso: $(basename $0) - [OPÇÕES]\n
     -h, --help\t\t\t Exibe este menu de ajuda.
     -v, --version\t\t Versão do programa.
     -e, --extension\t\t Recebe as extensões de arquivos.
     
     Exemplo:

     $0 -h
     $0 -v
     $0 www.site.com wordlist.txt
     $0 www.site.com wordlist.txt -e txt,php,zip
    "
}

show_version() {

    echo -e "$(basename $0) $VERSION\n\nCriado por $AUTHOR."
}

do_request() {

    curl -s -o /dev/null -w "%{http_code}" -L -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0" "$1"
}

find_files() {

    local STATUS

    for extension in "${EXT[@]}"
    do
        STATUS=$(do_request "$HOST/$1.$extension")

        if [[ $STATUS -eq 200 ]]
        then
            echo -e "${YELLOW}ARQUIVO ENCONTRADO: $HOST/$1.$extension"
        fi
    done
}

main() {

    local STATUS

    HOST="$1"
    WORDLIST="$2"

    while test -n "$1"
    do
        case "$1" in

            "-h"|"--help") show_help && exit 0 ;;

            "-v"|"--version") show_version && exit 0 ;;

            "-e"|"--extension") EXT=($(echo $2 | tr , " ")) ;;
        esac
    shift
    done

    [[ ! -f "$WORDLIST" ]] && echo "ARQUIVO $WORDLIST não encontrado! Verifique o nome digitado." && exit 1
    [[ ! -x "$(which curl)" ]] && sudo apt-get install curl

    for dir in $(cat $WORDLIST)
    do
        STATUS=$(do_request "$HOST/$dir/")

        if [[ $STATUS -eq 200 ]]
        then
            echo -e "${YELLOW}DIRETÓRIO ENCONTRADO: $HOST/$dir/"
        fi

        [[ ${#EXT[@]} -gt 0 ]] && find_files "$dir"

    done
}

# EXECUÇÃO

[[ $# -eq 0 ]] && show_help && exit 0

main "$@"