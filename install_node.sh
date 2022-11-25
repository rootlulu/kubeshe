#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128

function install_nodes() {
    # todo should use the master output
    # kubeadm join 192.168.65.100:6443 --token tluojk.1n43p0wemwehcmmh \
	# --discovery-token-ca-cert-hash sha256:c50b25a5e00e1a06cef46fa5d885265598b51303f1154f4b582e0df21abfa7cb

    mkdir -p ~/.kube
    touch ~/.kube/config

    # TODO  in the master.
    scp /etc/kubernetes/admin.conf root@192.168.65.101:~/.kube/config
    scp /etc/kubernetes/admin.conf root@192.168.65.102:~/.kube/config
    :
}