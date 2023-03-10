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
    if [[ ${USER} == "root" ]]; then
        export KUBECONFIG=/etc/kubernetes/admin.conf
    fi

    # generate a forever token and output the join cluster sentence to shell script.
    kubeadm token create --ttl 0 --print-join-command >"${PATH_}/${APP}/${JOIN_CMD_SHELL}"
    chmod 700 "${PATH_}/${APP}/${JOIN_CMD_SHELL}"

    for node in "${WORKERS[@]}"; do
        scp "${PATH_}/${APP}/${JOIN_CMD_SHELL}" "${node}:${PATH_}/${APP}"
        remote_ssh "${node}" "mkdir -p ~/.kube"
        scp /etc/kubernetes/admin.conf "${node}:~/.kube/config"
    done

    # deploy the network plugin. can use  flannel, calico, cana and so on.
    kubectl apply -f "${PATH_}/${APP}/kubenets/plugins/calico.yml"

    # set the ipvs mode.
    kubectl get cm kube-proxy -n kube-system -o yaml | sed 's/mode:.*/mode: "ipvs"/g' | kubectl apply -f -
    kubectl delete pod -l k8s-app=kube-proxy -n kube-system
}
