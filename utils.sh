#!/bin/bash

function logger() {
    local TIMESTAMP
    TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
    case "$1" in
    debug)
        echo -e "[$TIMESTAMP][\033[36mDEBUG:  \033[0m] $2"
        ;;
    info)
        echo -e "[$TIMESTAMP][\033[32mINFO:  \033[0m] $2"
        ;;
    warn)
        echo -e "[$TIMESTAMP][\033[33mWARN:  \033[0m] $2"
        ;;
    error)
        echo -e "[$TIMESTAMP][\033[31mERROR:  \033[0m] $2"
        ;;
    *) ;;
    esac
}

function remote_ssh() {
    local EMPTY="empty"
    local addr=${1-${EMPTY}}
    local cmds=""

    if [[ ${addr} = "${EMPTY}" ]]; then
        exit 1
    fi

    while [[ $# -gt 1 ]]; do
        # comparing with 1 targets to jump the $1
        cmd=$2
        # if [[ ! "${cmds}" ]]; then
        if [[ "${cmds}" = "" ]]; then
            cmds="${cmd}"
        else
            cmds="${cmds}; ${cmd}"
        fi
        shift
    done
    logger info "${cmds}"
    ssh -tto StrictHostKeyChecking=no "${addr}" "${cmds}; exit"
}

function isMaster() {
    if [[ $(ifconfig ens18 | grep 'inet ' | cut -d " " -f 10) == "${MASTER}" ]]; then
        return 0
    else
        return 1
    fi
}
