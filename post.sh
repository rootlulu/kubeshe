#!/bin/bash

function teardown() {
    yum -y install bash-completion
    echo 'source <(kubectl completion bash)' >>~/.bashrc 
    kubectl completion bash >/etc/bash_completion.d/kubectl
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    . /usr/share/bash-completion/bash_completion
}