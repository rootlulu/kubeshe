#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applySts() {
    local cluster_pod
    kubectl apply -f "${CURRENT}/statefulSet.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create statefulSet failed."
        exit 1
    fi
    sleep 20

    # todo: the script wont stop when awk raise a error.
    for cluster_pod in $(kubectl get pod -owide | awk '{if ($1 ~ "ysm-nginx") print $1}')
    do 
        logger info "The cluster ${cluster_pod-"cant get the pod name."}"
        if [[ $(kubectl exec -it ysm-test-pod -- curl -s "${cluster_pod}.ysm-nginx-svc" -o /dev/null -w "%{http_code}") -ne 200 ]]; then
            logger error "failed"
            exit 1
        fi
    done
    logger info "success"
}

function deleteSts() {
    kubectl delete -f "${CURRENT}/statefulSet.yml"
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
    if ! [[ "${array[*]}" =~ "${1-"996die"}" ]]; then
        logger error "The invalid first param. it must be apply, create or delete."
    fi

    if [[ ${1-} = "apply" || ${1-} = "create" ]]; then
        logger info "create the statefulset"
        applySts
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete the statefulset"
        deleteSts
    fi
}

main "$@"
