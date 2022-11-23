#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128


function install_master() {
    # apiserver-advertise-address must be the ip address but not domain name
    # apiserver-advertise-address, service-cidr and pod-network-cidr can't in
    # one network. And don't use 172.17.0.1/16 which retained to docker.
    kubeadm init \
    --apiserver-advertise-address=192.168.65.100 \
    --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
    --kubernetes-version=v1.21.10 \
    --service-cidr=10.96.0.0/16 \
    --pod-network-cidr=10.244.0.0/16

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown "$(id -u):$(id -g)" $HOME/.kube/config

    # if you are in the root policy.
    export KUBECONFIG=/etc/kubernetes/admin.conf

    # 生成一个永不过期的token
    kubeadm token create --ttl 0 --print-join-command > "${PATH_}/token"

    # deploy the network plugin. can use  flannel, calico, cana and so on.
    kubectl apply -f" ${PATH_}/${APP}/kubenets/plugins/calico.yml"

    # todo, change the mode to "ipvs"
    kubectl edit cm kube-proxy -n kube-system
    kubectl delete pod -l k8s-app=kube-proxy -n kube-system
}