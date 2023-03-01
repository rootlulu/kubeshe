#!/bin/bash

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
    echo "${cmds}"
    ssh -tto StrictHostKeyChecking=no "${addr}" "${cmds}; exit"
}

function isMaster() {
    if [[ $(ifconfig ens18 | grep 'inet ' | cut -d " " -f 10) == "${MASTER}" ]]; then
        return 0
    else
        return 1
    fi
}
