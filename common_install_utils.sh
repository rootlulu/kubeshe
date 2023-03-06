#!/bin/bash

# all common installer in all nodes.

function set_dns() {
    # set the hosts
    for node_name in "${!NAME_NODE_MAP[@]}"; do
        cat >>/etc/hosts <<EOF
${NAME_NODE_MAP[${node_name}]} ${node_name}
EOF
    done
}

function set_time_synchronization() {
    yum install ntpdate -y
    ntpdate time.windows.com
}

function colse_selinux_and_swap() {
    systemctl stop firewalld
    systemctl disable firewalld
    # close the current session's selinux. there may be a error. so set +e.
    set +e
    setenforce 0
    set -e
    # worker after rebooting.
    sed -i 's/enforcing/disabled/' /etc/selinux/config
    # close the current session's swap
    swapoff -a
    # worked after rebooting.
    sed -ri 's/.*swap.*/#&/' /etc/fstab
}

function ipv4_2_iptables() {
    # shellcheck disable=SC2129
    cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.all.forwarding = 1
EOF
    # echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
    # echo "net.bridge.bridge-nf-call-ip6tables = 1" >>/etc/sysctl.conf
    # echo "net.bridge.bridge-nf-call-iptables = 1" >>/etc/sysctl.conf
    # echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.conf
    # echo "net.ipv6.conf.default.disable_ipv6 = 1" >>/etc/sysctl.conf
    # echo "net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.conf
    # echo "net.ipv6.conf.all.forwarding = 1" >>/etc/sysctl.conf

    # append the br_netfilter module and make it worked forever.
    modprobe br_netfilter
    sysctl -p
}

function open_ipvs() {
    yum -y install ipset ipvsadm
    cat >/etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
EOF
    chmod 755 /etc/sysconfig/modules/ipvs.modules
    bash /etc/sysconfig/modules/ipvs.modules
    lsmod | grep -e ip_vs -e nf_conntrack_ipv4
}

function install_docker() {
    # uninstall the old version.
    set +e
    systemctl stop docker.socket
    systemctl stop docker
    systemctl disable docker
    # yum remove all docker service.
    yum list installed | grep docker | xargs -I {} echo {} | cut -d " " -f 1 | xargs -I {} yum remove -y {}
    set -e

    # install another version.
    yum -y install yum-utils
    # todo: to be configured.
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum makecache fast
    # todo: to be configured.
    yum -y install docker-ce-3:20.10.8-3.el7.x86_64 docker-ce-cli-1:20.10.8-3.el7.x86_64 containerd.io

    systemctl start docker
    systemctl enable docker
    docker version

    # aliyun repo speeded-up
    sudo mkdir -p /etc/docker
    # todo: to be configured.
    sudo tee /etc/docker/daemon.json <<-'EOF'
        {
        "exec-opts": ["native.cgroupdriver=systemd"],	
        "registry-mirrors": [
            "https://du3ia00u.mirror.aliyuncs.com",
            "https://hub-mirror.c.163.com",
            "https://mirror.baidubce.com"
        ],
        "live-restore": true,
        "log-driver":"json-file",
        "log-opts": {"max-size":"500m", "max-file":"3"},
        "max-concurrent-downloads": 10,
        "max-concurrent-uploads": 5,
        "storage-driver": "overlay2"
        }
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
}

function set_k8s_resource() {
    # todo: be configured.
    cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
}

function change_cgroup() {
    # vim /etc/sysconfig/kubelet
    # change the follow.
    sed -i  's/KUBELET_EXTRA_ARGS=.*/KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"/g' /etc/sysconfig/kubelet
    # KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
    # todo with the postpone.
    # KUBE_PROXY_MODE="ipvs"
    :
}

function install_k8s() {
    # todo: be configured.
    local wait_installeds
    local resource="registry.cn-hangzhou.aliyuncs.com/google_containers/"

    yum install -y "${KUBELET}" "${KUBEADM}" "${KUBECTL}" -y
    systemctl enable kubelet

    wait_installeds=$(kubeadm config images list)
    # echo "$wait_installeds" | xargs -n1 | sed "s/k8s.gcr.io\///"
    for wait_installed in ${wait_installeds}; do
        echo "The pull url: ${resource}${wait_installed##*/}"
        # docker pull "${resource}${wait_installed/k8s.gcr.io\//}"
        docker pull "${resource}${wait_installed##*/}"
        if [[ ${wait_installed} =~ "coredns" ]]; then
            docker tag "${resource}${wait_installed##*/}" "${resource}${wait_installed#*/}"
        fi
    done
}

function install_common() {
    set_dns
    set_time_synchronization
    colse_selinux_and_swap
    ipv4_2_iptables
    open_ipvs
    install_docker
    set_k8s_resource
    change_cgroup
    install_k8s
}
