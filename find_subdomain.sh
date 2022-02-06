#!/usr/bin/env bash

# VARIÁVEIS

HOSTS_FILE="/tmp/hosts-find-$$.txt"

VERMELHO="\033[31;1m"

# FUNÇÕES

delete_temp_files() {

    [[ -f "$HOSTS_FILE" ]] && rm -rf "$HOSTS_FILE"
}

ctrl_c() {

    delete_temp_files

    echo -e "\n${VERMELHO}Scanning abortado pelo usuário!\n" && exit 1
}

main() {

    trap ctrl_c 2

    for subdomain in $(cat $2)
    do
        host $subdomain.$1 | grep "has address" >> "$HOSTS_FILE"
    done

    if test -f "$HOSTS_FILE"
    then
        cat "$HOSTS_FILE" | sort -u | sed "s/has address/===>/"

        delete_temp_files
    else
        echo "Nenhum subdomínio encontrado!"
    fi
}

# EXECUÇÃO

[[ $# -ne 2 ]] && echo "Forma de uso: $0 site.com wordlist.txt" && exit 0

main "$@"