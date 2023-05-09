#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applyDs() {
    local node
    kubectl apply -f "${CURRENT}/daemonSet.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create daemonSet failed."
        exit 1
    fi
    sleep 20

    # todo: the script wont stop when awk raise a error.
    if [[ $(kubectl get node | awk '{if ($1 ~ "node") print $1}' | sort) = $(kubectl get pod -owide | awk '{if ($1 ~ "ysm-nginx-daemonset") print $7}' | sort) ]]; then
        logger info "success"
    fi
}

function deleteDs() {
    kubectl delete -f "${CURRENT}/daemonSet.yml"
    if [[ $? -eq 0 ]]; then
        logger info "success"
    else
        logger error "failed"
    fi
}

function main() {
    echo "The execute entry: $(pwd)"
    . ${PATH_}/${APP}/utils.sh
    array=("apply" "create" "delete")
    if ! [[ "${array[*]}" =~ "${1-"996die"}" ]]; then
        logger error "The invalid first param. it must be apply, create or delete."
    fi

    if [[ ${1-} = "apply" || ${1-} = "create" ]]; then
        logger info "create the daemonSet"
        applyDs
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete the daemonSet"
        deleteDs
    fi
}

main "$@"
