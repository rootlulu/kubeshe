#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applyPod() {
    local cluster_ip
    # kubectl run nginx-pod --image=nginx:1.17.1 --port=80
    kubectl apply -f "${CURRENT}/pod.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create pod failed."
        exit 1
    fi
    sleep 20
    cluster_ip=$(kubectl get pod -owide | awk '{if ($1 == "ysm-nginx-pod") print $6}')
    echo "${cluster_ip}"
    if [[ $(curl -s "${cluster_ip}" -o /dev/null -w "%{http_code}") -eq 200 ]]; then
        logger info "success"
    else
        logger error "failed"
    fi
}

function deletePod() {
    kubectl delete -f "${CURRENT}/pod.yml"
    if [[ $? -eq 0 ]];then 
        logger info "success"
    else
        logger error "failed"
    fi
}


function main() {
    echo "The execute entry: $(pwd)"
    . ${PATH_}/${APP}/utils.sh
    array=("apply" "create" "delete")
    if ! [[ "${array[*]}" =~ "${1-}" ]]; then
        logger error "The invalid params. it must be apply, create or delete."
    fi

    if [[ ${1-} = "apply" || ${1-} = "create" ]]; then
        logger info "create a pod"
        applyPod
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete a pod"
        deletePod
    fi
}

main "$@"
