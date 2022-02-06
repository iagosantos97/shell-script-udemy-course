#!/usr/bin/env bash

# VARIÁVEIS

VERSION="1.0"
AUTHOR="Iago Santos Oliveira"

HASH_SET=0
HASH=

ALGO_SET=0
ALGO=

WORDLIST_SET=0
WORDLIST=

VERMELHO="\033[31;1m"
YELLOW="\033[33;1m"

# FUNÇÕES

show_help() {
    echo -e "Uso: $(basename $0) - [OPÇÕES]\n
     -h, --help\t\t\t Exibe este menu de ajuda.
     -v, --version\t\t Versão do programa.
     -H, --hash\t\t\t Hash a ser quebrado.
     -a, --alg\t\t\t Recebe o nome do algoritmo de criptografia.
     -w, --wordlist\t\t Recebe um arquivo contendo uma lista de senhas.

     Exemplo:

     $0 -h
     $0 -v
     $0 -a base64 -h hash ===> HASHs no formato BASE64 não precisam de Wordlist.
     $0 -a md5 -H hash -w wordlist.txt
     $0 -a sha1 -H hash -w wordlist.txt
     
     Algoritmos aceitos: base64, md5, sha1, sha256, sha512.
    "
}

show_version() {
    echo -e "$(basename $0) $VERSION\n\nCriado por $AUTHOR."
}

show_alert_algo() {
    echo -e "\n${VERMELHO}Erro! Você deve especificar apenas um tipo de algoritmo!\n" && exit 1
}

show_alert_wordlist() {
    echo -e "\n${VERMELHO}Erro! Você deve especificar apenas uma wordlist!\n" && exit 1
}

show_alert_hash() {
    echo -e "\n${VERMELHO}Erro! Você deve especificar apenas um hash!\n" && exit 1
}

define_algo_hash_wordlist() {

    if [[ "$1" = "ALGO" && $ALGO_SET -eq 1 ]]
    then
        show_alert_algo
    fi

    case "$1" in

        "ALGO")

            if [[ $ALGO_SET -eq 1 ]]
            then
                show_alert_algo
            else
                case "$2" in
                    "base64"|"md5"|"sha1"|"sha256"|"sha512")
                        ALGO_SET=1
                        ALGO="$2"
                ;;
                    *)
                        echo -e "\n${VERMELHO}Erro! Algoritmos aceitos: base64, md5, sha1, sha256, sha512." && exit 1
                ;;
                esac
            fi
        ;;

        "WORDLIST")

            if [[ $WORDLIST_SET -eq 1 ]]
            then
                show_alert_wordlist
            else
                WORDLIST_SET=1
                WORDLIST="$2"
            fi
        ;;

        "HASH")

            if [[ $HASH_SET -eq 1 ]]
            then
                show_alert_hash
            else
                HASH_SET=1
                HASH="$2"
            fi
        ;;

    esac

}

go_crack() {

    local ACTUAL_HASH

    if [[ "$ALGO" = "base64" ]]
    then
        echo -e "${YELLOW} Senha encontrada ===> $(echo -n "$HASH" | base64 -d -i)"
    else

        [[ ! -f "$WORDLIST" ]] && echo -e "\n${VERMELHO}Erro! Wordlist não encontrada.\n" && exit 1
        [[ ! -r "$WORDLIST" ]] && echo -e "\n${VERMELHO}Erro! Wordlist sem permissão de leitura.\n" && exit 1

        for PASSWORD in $(cat "$WORDLIST")
        do
            ACTUAL_HASH="$(echo -n $PASSWORD | ${ALGO}sum | tr -d " "-)"

            if [[ "$ACTUAL_HASH" = "$HASH" ]]
            then
                echo -e "${YELLOW} Senha encontrada ===> $PASSWORD"
                break
            fi
        done

    fi

}

main() {

    while test -n "$1"
    do
        case "$1" in

            "-h"|"--help") show_help && exit 0 ;;

            "-v"|"--version") show_version && exit 0 ;;

            "-a"|"--alg") define_algo_hash_wordlist "ALGO" "$(echo $2 | tr [A-Z] [a-z])" ;;

            "-w"|"--wordlist") define_algo_hash_wordlist "WORDLIST" "$2" ;;

            "-H"|"--hash") define_algo_hash_wordlist "HASH" "$2" ;;

        esac
    shift
    done

    if [[ $ALGO_SET -eq 1 && $HASH_SET -eq 1 ]]
    then
        go_crack
    else
        show_help
    fi

}

# EXECUÇÃO

[[ $# -eq 0 ]] && show_help && exit 0

main "$@"