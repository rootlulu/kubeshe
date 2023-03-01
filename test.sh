#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128

function test_nginx() {
    kubectl create deployment nginx --image=nginx:1.14-alpine
    kubectl expose deployment nginx --port=80 --type=NodePort
    # todo curl
}
