#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applyDeploy() {
    local cluster_ip
    kubectl apply -f "${CURRENT}/deployment.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create deployment failed."
        exit 1
    fi
    sleep 20

    # todo: the script wont stop when awk raise a error.
    for cluster_ip in $(kubectl get pod -owide | awk '{if ($1 ~ "ysm-nginx-deployment") print $6}')
    do 
        logger info "The cluster ip ${cluster_ip-"cant get the ip."}"
        if [[ $(curl -s "${cluster_ip}" -o /dev/null -w "%{http_code}") -ne 200 ]]; then
            logger error "failed"
            exit 1
        fi
    done
    logger info "success"
}

function deleteDeploy() {
    kubectl delete -f "${CURRENT}/deployment.yml"
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
        logger info "create the deplyment"
        applyDeploy
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete the deployment"
        deleteDeploy
    fi
}

main "$@"
