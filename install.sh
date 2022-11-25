#!/bin/bash

function set_dns() {
    # set the hosts
    cat >> /etc/hosts <<EOF
    10.251.1.79    etcd_bj.com
    10.251.1.79    etcd_sh.com
    10.251.1.79    etcd_gz.com
EOF
}

function time_synchronization() {
    yum install ntpdate -y
    ntpdate time.windows.com
}

function colse_selinux_and_swap() {
    # close the current session's selinux
    setenforce 0
    # reboot will work.
    sed -i 's/enforcing/disabled/' /etc/selinux/config
    # close the current session's swap
    swapoff -a
    # reboot will work.
    sed -ri 's/.*swap.*/#&/' /etc/fstab
}

function ipv4_2_iptables() {
    # shellcheck disable=SC2129
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf

    # append the br_netfilter module and make it worked forever.
    modprobe br_netfilter
    sysctl -p
}

function open_ipvs() {
    yum -y install ipset ipvsadm
    cat > /etc/sysconfig/modules/ipvs.modules <<EOF
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
    sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum makecache fast
    yum -y install docker-ce-3:20.10.8-3.el7.x86_64 docker-ce-cli-1:20.10.8-3.el7.x86_64 containerd.io

    systemctl start docker
    systemctl enable docker
    docker version
    if ! $?;then
        exit 2
    fi

    # aliyun repo speeded-up

    sudo mkdir -p /etc/docker
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
    cat > /etc/yum.repos.d/kubernetes.repo << EOF
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
    # KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
    # KUBE_PROXY_MODE="ipvs"
    :
}

function _install_k8s() {
    yum install -y kubelet-1.21.10 kubeadm-1.21.10 kubectl-1.21.10 -y
    systemctl enable kubelet
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.21.10
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.21.10
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.21.10
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.21.10
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.4.1
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.13-0
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.0

    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.0 registry.cn-hangzhou.aliyuncs.com/google_containers/coredns/coredns:v1.8.0
}


function install_main() {
    set_dns
}