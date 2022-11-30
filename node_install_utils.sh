#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128

function join_cluster() {
    local file="${APP}.tar.gz"
    #shellcheck disable=SC2068
    # for node in ${WORKERS[@]}; do
        # if run a command in a here doc way, the limit string(like EOF) can't be quoted.
        # otherwise it cuts no ice with expansion.
        # if run command immediately, use double-quotes but not single-quotes, it worked.
        # user -tt to force as a tty ans exit. some anwered -T, but it not worked.
        # shellcheck disable=SC2087
        # ssh -tto StrictHostKeyChecking=no "${node}" <<EOF
        "${PATH_}/${APP}/${JOIN_CMD_SHELL}"
}

function init_nodes() {
    # mkdir -p ~/.kube
    # touch ~/.kube/config

    # TODO  in the master.
    # scp /etc/kubernetes/admin.conf root@192.168.65.101:~/.kube/config
    # scp /etc/kubernetes/admin.conf root@192.168.65.102:~/.kube/config
    :
}