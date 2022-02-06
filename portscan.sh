#!/usr/bin/env bash

# VARIÁVEIS

VERSION="1.0"
AUTHOR="Iago Santos Oliveira"

TARGET_SET=0
TARGET_TYPE=
TARGET=
TARGET_FILE="/tmp/hosts-$$.txt"

FIRST_PORT=
LAST_PORT=
PORTS_FILE="/tmp/ports-$$.txt"
PORTS_OPEN_FILE="/tmp/ports-open-$$.txt"

declare -a NETWORK_ARRAY
NETWORK_DOTS=

VERMELHO="\033[31;1m"
YELLOW='\033[33;1m'
BLUE='\033[34;1m'
END='\033[m'

# FUNÇÕES

show_help() {
    echo -e "Uso: $(basename $0) - [OPÇÕES]\n
     -h, --help\t\t\t Exibe este menu de ajuda.
     -v, --version\t\t Versão do programa.
     -H, --host\t\t\t Recebe uma url ou um IP.
     -f, --file\t\t\t Recebe um arquivo contendo uma lista de hosts. URLs ou IPs são aceitos.
     -n, --network\t\t Recebe uma rede.
     -p, --port\t\t\t Recebe uma porta ou um range de portas.

     Exemplo:

     $0 -h
     $0 -v
     $0 -H www.site.com -p 80
     $0 --host 192.168.0.1 -p 22:80 ==> RANGE [FIRST_PORT:LAST_PORT]
     $0 -f hosts.txt -p 23,25,53,80
     $0 -n 192.168.0 -p 443
    "
}

show_version() {

    echo -e "$(basename $0) $VERSION\n\nCriado por $AUTHOR."
}

show_alert_target() {

    echo -e "\n${VERMELHO}Erro! Você deve passar um host, um arquivo contendo vários hosts ou uma rede!\n" && exit 1
}

delete_temp_files() {

    [[ -f "$TARGET_FILE" ]] && rm -rf "$TARGET_FILE"
    [[ -f "$PORTS_FILE" ]] && rm -rf "$PORTS_FILE"
    [[ -f "$PORTS_OPEN_FILE" ]] && rm -rf "$PORTS_OPEN_FILE"
}

ctrl_c() {
    
    delete_temp_files

    echo -e "\n${VERMELHO}Scanning abortado pelo usuário!\n" && exit 1

}

verify_file_exists() {

    if [[ ! -f "$1" ]]
    then
        echo -e "\n${VERMELHO}Erro! Arquivo de hosts não encontrado! Verifique o caminho digitado.\n" && exit 1
    elif [[ ! -r "$1" ]]
    then
        echo -e "\n${VERMELHO}Erro! Arquivo de hosts não possui permissão de leitura.\n" && exit 1
    fi
}

verify_target() {

    if [[ $TARGET_SET -eq 1 ]]
    then
        show_alert_target
    else
        TARGET_SET=1
        TARGET_TYPE="$1"
        TARGET="$2"

        if [[ "$TARGET_TYPE" = "FILE" ]]
        then

            verify_file_exists "$TARGET"

            cp "$TARGET" "$TARGET_FILE"

        elif [[ "$TARGET_TYPE" = "HOST" ]]
        then
            
            echo "$TARGET" >> "$TARGET_FILE"

        elif [[ "$TARGET_TYPE" = "NETWORK" ]]
        then
            NETWORK_ARRAY=($(echo $TARGET | tr . " "))

            NETWORK_DOTS=$(echo $TARGET | tr -cd . | wc -c)

            if [[ ${#NETWORK_ARRAY[@]} -gt 3 || $NETWORK_DOTS -gt 2 ]]
            then
                echo -e "\n${VERMELHO}Erro! Rede inválida!\n" && exit 1
            else
                for host in $(seq 1 254)
                do
                    echo $TARGET.$host >> "$TARGET_FILE"
                done
            fi
        fi

        if [[ $(cat "$TARGET_FILE" | wc -m) -eq 0 ]]
        then
            echo -e "\n${VERMELHO}Erro! Nenhum host para ser escaneado.\n"

            delete_temp_files

            exit 1
        fi
    fi
}

reverse_ports() {

    if [[ $1 -gt $2 ]]
    then
        FIRST_PORT=$2
        LAST_PORT=$1
    fi
}

verify_port_number() {
    
    if [[ $1 -lt 1 || $1 -gt 65535 ]] 
    then
        echo -e "\n${VERMELHO}Erro! Informe uma porta entre 1 e 65535!\n"

        delete_temp_files

        exit 1
    fi
}

verify_port() {

    if [[ $(echo "$1" | grep -c ,) -eq 1 ]]
    then
        
        for port in $(echo "$1" | tr , " ")
        do  
            verify_port_number $port
            echo $port >> "$PORTS_FILE"
        done

    else
        
        FIRST_PORT="$(echo $1 | cut -d : -f 1)" 
        LAST_PORT="$(echo $1 | cut -d : -f 2)"

        verify_port_number $FIRST_PORT
        verify_port_number $LAST_PORT

        reverse_ports $FIRST_PORT $LAST_PORT

        seq $FIRST_PORT $LAST_PORT >> "$PORTS_FILE"
    fi

}

show_ports_open() {

    if [[ -f "$PORTS_OPEN_FILE" ]]
    then
        echo
        echo -e "${YELLOW}######################${END}"
        echo -e "${YELLOW}#  HOST $1${END}"         
        echo -e "${YELLOW}######################${END}"

        for port in $(cat $PORTS_OPEN_FILE)
        do
            echo -e "${YELLOW}#  PORTA $port ABERTA!${END}"
        done

        echo -e "${YELLOW}######################${END}"

        rm -rf "$PORTS_OPEN_FILE"
    fi
}

go_portscan() {

    local RETURN_HPING

    for host in $(cat $TARGET_FILE)
    do
       
        for port in $(cat $PORTS_FILE)
        do
            RETURN_HPING="$(sudo hping3 --syn -c 1 -p $port $host 2> /dev/null | grep "flags=SA" | cut -d " " -f 2 | cut -d "=" -f 2)"
            [[ "$RETURN_HPING" != "" ]] && echo $port >> "$PORTS_OPEN_FILE"
        done
        show_ports_open "$host"
    done
    
    echo
    
    delete_temp_files
}

main() {

    trap ctrl_c 2

    while test -n "$1"
    do
        case "$1" in
            
            "-h"|"--help") show_help && exit 0 ;;

            "-v"|"--version") show_version && exit 0 ;;

            "-H"|"--host") verify_target "HOST" "$2"  ;;

            "-f"|"--file") verify_target "FILE" "$2" ;;

            "-n"|"--network") verify_target "NETWORK" "$2" ;;

            "-p"|"--port") verify_port "$2" ;;

        esac
    shift
    done

    if [[ $TARGET_SET -eq 1 ]]
    then
        go_portscan
    else
        show_alert_target
    fi     
}

# EXECUÇÃO

[[ $# -eq 0 ]] && show_help && exit 0

main "$@"

