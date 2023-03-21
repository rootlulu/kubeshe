#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applySvc() {
    local cluster_ip cluster_ip_and_node_port node_ip node_port
    kubectl apply -f "${CURRENT}/service.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create service failed."
        exit 1
    fi
    sleep 20
    # get the cluster_ip and node_port.
    cluster_ip_and_node_port=$(kubectl get service -owide | awk -F '[/:[:space:]]+' \
    '{if ($1 == "ysm-nginx-svc-node-port") print $3,$6}') # todo the name is hardcoding.
    cluster_ip=$(echo "${cluster_ip_and_node_port}" | awk '{print $1}')
    node_port=$(echo "${cluster_ip_and_node_port}" | awk '{print $2}')
    node_ip=$(ifconfig ens18 | grep 'inet ' | cut -d " " -f 10)
    echo "${cluster_ip-"There is not a cluster-ip"}"
    # todo test the externalName, i'm lazy to write the code.
    # && $(kubectl exec ysm-busybox-pod -- ping ysm-nginx-svc.default.svc.cluster.local)
    if [[ $(curl -s "${cluster_ip}" -o /dev/null -w "%{http_code}") -eq 200 &&
    $(curl -s "${node_ip}:${node_port}" -o /dev/null -w "%{http_code}") -eq 200 ]]; then

        logger info "success"
    else
        logger error "failed"
    fi
}

function deleteSvc() {
    kubectl delete -f "${CURRENT}/service.yml"
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
    if ! [[ "${array[*]}" =~ "${1-}" ]]; then
        logger error "The invalid params. it must be apply, create or delete."
    fi

    if [[ ${1-} = "apply" || ${1-} = "create" ]]; then
        logger info "create the service."
        applySvc
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete the service."
        deleteSvc
    fi
}

main "$@"
