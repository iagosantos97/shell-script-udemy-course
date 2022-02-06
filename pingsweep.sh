#!/usr/bin/env bash

# VARIÁVEIS

# FUNÇÕES

ping_sweep() {

    for host in $(seq 1 254)
    do
        ping -c 1 $1.$host | grep "64 bytes" | cut -d " " -f 4 | sed "s/://" >> vivos.txt
    done
}

# EXECUÇÃO

[[ $# -ne 1 ]] && echo "Forma de uso: $0 192.168.0" && exit 0

ping_sweep "$1"