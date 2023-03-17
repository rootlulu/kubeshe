#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128

function testK8s() {
    local svc_ip
    kubectl create deployment nginx --image=nginx:1.14-alpine
    kubectl expose deployment nginx --port=80 --type=NodePort
    svc_ip=$(kubectl get svc | awk '{if ($1 == "nginx") print $3}')
    # to wait the service started.
    sleep 20
    if [[ $(curl -s "${svc_ip}" -o /dev/null -w "%{http_code}") -eq 200 ]]; then
        kubectl delete svc,deploy nginx
        logger info "success"
    else
        logger error "failed"
    fi
}

function main() {
    # shellcheck source=/dev/null
    . ./utils.sh
    testK8s
}

main