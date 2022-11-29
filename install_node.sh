#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128

function init_nodes() {
    mkdir -p ~/.kube
    touch ~/.kube/config

    # TODO  in the master.
    scp /etc/kubernetes/admin.conf root@192.168.65.101:~/.kube/config
    scp /etc/kubernetes/admin.conf root@192.168.65.102:~/.kube/config
    :
}