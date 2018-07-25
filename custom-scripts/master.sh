#!/bin/bash

set -x
set -e

set -o pipefail

function install_pwsh () {
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    sudo curl -o /etc/apt/sources.list.d/microsoft.list https://packages.microsoft.com/config/ubuntu/16.04/prod.list
    sudo apt-get update
    sudo apt-get install powershell -y
}

function collect_logs () {
    local user="$1"; shift
    local pass="$1"; shift
    local output="$1"

    mkdir -p $output

    git clone https://github.com/papagalu/logslurp
    pushd "logslurp"
        git checkout customize_logslurp
        pwsh logslurp.ps1 -WinUser "$user" -WinPass "$pass" -OutputFolder "$output"
    popd
}

function main () {

    TEMP=$(getopt -o u:p:o: --long user:,pass:,output: -n 'master.sh' -- "$@")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    echo $TEMP
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            --user)
                user="$2"; shift 2;;
            --pass)
                pass="$2"; shift 2;;
            --output)
                output="$2"; shift 2;;
            --) shift ; break ;;
        esac
    done

    install_pwsh
    collect_logs "$user" "$pass" "$output"
}

main "$@"
