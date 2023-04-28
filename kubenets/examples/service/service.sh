#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function externalPing() {
    local count=0
    while [[ ${count} -lt 3 ]]; do
        count=${count}+1
        if kubectl exec ysm-busybox-pod -- ping -c 1 ysm-nginx-svc-external.default.svc.cluster.local | grep -q "seq=0"; then
            return 0
        fi
    done
    return 1
}

function headlinessPing() {
    local count=0
    while [[ ${count} -lt 3 ]]; do
        count=${count}+1
        if kubectl exec ysm-busybox-pod -- ping -c 1 ysm-nginx-svc-headliness.default.svc.cluster.local | grep -q "seq=0"; then
            return 0
        fi
    done
    return 1
}

function applySvc() {
    local cluster_ip cluster_ip_and_node_port node_ip node_port
    kubectl apply -f "${CURRENT}/service.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create service failed."
        exit 1
    fi
    sleep 20
    # get the cluster_ip and node_port.
    nodeport_name=$(kubectl get svc | awk '{if ($2 == "NodePort") print $1}')
    cluster_ip_and_node_port=$(kubectl get service -owide | awk -v n=${nodeport_name} \
    -F '[/:[:space:]]+' '{if ($1 == n) print $3,$6}')
    cluster_ip=$(echo "${cluster_ip_and_node_port}" | awk '{print $1}')
    node_port=$(echo "${cluster_ip_and_node_port}" | awk '{print $2}')
    node_ip=$(ifconfig ens18 | grep 'inet ' | cut -d " " -f 10)
    echo "The cluster is ${cluster_ip-"cant get the clsuter-ip."}"
    if [[ $(curl -s "${cluster_ip}" -o /dev/null -w "%{http_code}") -eq 200 &&
    $(curl -s "${node_ip}:${node_port}" -o /dev/null -w "%{http_code}") -eq 200 &&
        $(externalPing) -eq 0 && $(headlinessPing) -eq 0 ]]; then
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
    if ! [[ "${array[*]}" =~ "${1-"996die"}" ]]; then
        logger error "The invalid first param. it must be apply, create or delete."
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
