#!/usr/bin/env bash

# VARIÁVEIS

# FUNÇÕES

main() {

    [[ ! -x "$(which lynx)" ]] && sudo apt-get install lynx

    lynx -source "$1" | sed 's/ /\n/g;' \
    | egrep "href=|action=" \
    | egrep -oh "\"[^\"]*\"|\'[^\']'" \
    | sed "s/\"//g;s/'//g;s/^\/\///" \
    | grep "\." \
    | egrep -v ".css|.png|.jpg|.gif|.jpeg|.woff|.ico|.svg"

}

# EXECUÇÃO

[[ $# -ne 1 ]] && echo "Forma de uso: $0 www.site.com" && exit 0

main "$@"