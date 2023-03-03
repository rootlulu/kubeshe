#!/bin/bash

function init_master() {
    # apiserver-advertise-address must be the ip address but not domain name
    # apiserver-advertise-address, service-cidr and pod-network-cidr can't in
    # one network. And don't use 172.17.0.1/16 which retained to docker.
    kubeadm init \
        --apiserver-advertise-address="${MASTER}" \
        --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
        --kubernetes-version="${KUBE_VERSION}" \
        --service-cidr="${SERVICE_CIDR}" \
        --pod-network-cidr="${POD_NETWORK_CIDR}"

    mkdir -p "$HOME/.kube"
    sudo cp -r /etc/kubernetes/admin.conf "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

    # if you are in the root policy.
    export KUBECONFIG=/etc/kubernetes/admin.conf

    # 生成一个永不过期的token
    kubeadm token create --ttl 0 --print-join-command >"${PATH_}/${APP}/${JOIN_CMD_SHELL}"
    chmod 700 "${PATH_}/${APP}/${JOIN_CMD_SHELL}"

    # todo in the master.
    scp "${PATH_}/${APP}/${JOIN_CMD_SHELL}" 10.128.170.32:/var/ysm/kubeshe/
    scp "${PATH_}/${APP}/${JOIN_CMD_SHELL}" 10.128.170.33:/var/ysm/kubeshe/

    mkdir -p ~/.kube
    touch ~/.kube/config

    # TODO  in the master.
    remote_ssh 10.128.170.32 "mkdir -p ~/.kube"
    remote_ssh 10.128.170.33 "mkdir -p ~/.kube"
    scp /etc/kubernetes/admin.conf 10.128.170.32:~/.kube/config
    scp /etc/kubernetes/admin.conf 10.128.170.33:~/.kube/config

    # deploy the network plugin. can use  flannel, calico, cana and so on.
    kubectl apply -f "${PATH_}/${APP}/kubenets/plugins/calico.yml"

    # todo, change the mode to "ipvs"
    # kubectl edit cm kube-proxy -n kube-system
    # kubectl delete pod -l k8s-app=kube-proxy -n kube-system
}
