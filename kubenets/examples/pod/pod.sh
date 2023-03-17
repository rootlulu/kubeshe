#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

function applyPod() {
    local cluster_ip
    # kubectl run nginx-pod --image=nginx:1.17.1 --port=80
    kubectl apply -f ./kubenets/examples/pod/pod.yml
    sleep 20
    cluster_ip=$(kubectl get pod -owide | awk '{if ($1 == "ysm-nginx-pod") print $6}')
    echo "${cluster_ip}"
    if [[ $(curl -s "${cluster_ip}" -o /dev/null -w "%{http_code}") -eq 200 ]]; then
        logger info "success"
    else
        logger error "failed"
    fi
}

function main() {
    . ./utils.sh
    applyPod
}

main
