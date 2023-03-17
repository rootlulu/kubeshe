#!/bin/bash

# function teardown() {
#     yum -y install bash-completion
#     echo 'source <(kubectl completion bash)' >>~/.bashrc
#     kubectl completion bash >/etc/bash_completion.d/kubectl
#     kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
#     . /usr/share/bash-completion/bash_completion
# }

function post_main() {
    :
}

function successInstalled() {
    local svc_ip
    kubectl create deployment nginx --image=nginx:1.14-alpine
    kubectl expose deployment nginx --port=80 --type=NodePort
    svc_ip=$(kubectl get svc | awk '{if ($1 == "nginx") print $3}')
    # to wait the service started.
    sleep 20
    if [[ $(curl -s "${svc_ip}" -o /dev/null -w "%{http_code}") -eq 200 ]]; then
        kubectl delete svc,deploy nginx
        return 0
    else
        return 1
    fi
}
