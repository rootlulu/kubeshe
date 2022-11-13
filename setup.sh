#!/bin/bash

# 1. help, verbose等
# 2. yum等源数据
# 3. helm等安装需求


set -eu
# set -o pipefail


function help() {
    cat <<EOF
    Usage: ${BASH_SOURCE[0]} {-v|verbose} --ssh <username> <password>
            <--k8s_nodes> <master:node1:node2:...>
            [--yum_source <yum_url>] [--docker_source <docker_url>]

        -h | --help                     show help message

    Required:
        --ssh <username>
              <passwd>                  set the shh connection
    
    Optional:
        -v | -verbose                   verbose output
        --yum_source yum_url            the customized yum image source
        --docker_source docker_url      the customized docker image source

    Exit status:
        0  if OK,
        1  if required params is not provided,
        2  if other errors raised.
EOF
}

function valid_empty_value() {
    local k=${1}
    shift 
    if [[ $# -le 0 ]]; then
        echo "the $k's value is empty"
        exit 1
    else
        while [[ $# -gt 0 ]]; do
            if [[ -z ${1-} ]]; then
                echo "the $k's value is empty"
                exit 1
            fi
        shift
        done
    fi
}


function process_params() {
    local ssh_provided=false
    local nodes_provided=false
    local param
    while [[ $# -gt 0 ]]; do
        param=$1
        shift
        case $param in 
            -h | --help)
                help
                exit 0
                ;;
            --ssh)
                if [[ -n $param ]]; then
                    ssh_provided=true
                fi
                USERNAME=${1-}
                PASSWD=${2-}
                valid_empty_value $param $USERNAME "$PASSWD"
                shift
                shift
                :
                ;;
            --k8s_nodes)
                if [[ -n $param ]]; then
                    nodes_provided=true
                fi
                nodes_str=${1-}
                valid_empty_value $param $nodes_str
                nodes_array=(${nodes_str//:/ })
                MASTER=$nodes_array[0]
                WORKERS=${nodes_array[@]:1:${#nodes_array[@]}-1}
                shift
                ;;
            -v | --verbose)
                set -x
                ;;
            --yum_source)
                # todo support yum resource setting in the future.
                # todo default is aliyun.
                YUM_URL=${1-}
                valid_empty_value $param $YUM_URL
                shift
                ;;
            --docker_source)
                # todo supprort yum resource setting in the future.
                # todo default is aliyun.
                DOCKER_URL=${1-}
                valid_empty_value $param $DOCKER_URL
                shift
                ;;
            *)
                echo -e "No valid pararms provided. \n"
                help
                exit 1
                ;;
        esac
    done

    # if [[ $ssh_provided && $nodes_provided ]]; then
    if ! $ssh_provided; then
        echo "The required param is not provided!: --ssh!"
        exit 1
    elif ! $nodes_provided; then
        echo "The required param is not provided!: --k8s_nodes!"
        exit 1
    fi

}

function setup() {
    process_params $@
    ./core/main.sh pre_install
    # 设置yum源, 具体的安装放在对应的功能下面
}

function install_k8s() {
    ./core/main.sh install
    yum install libffi-devel openssl-devel expect ipset ipvsadm ntpdate tree vim netstat -y
    ntpdate time.windows.com
    # 配置master  worker和免密登录
    # 区分需要三台机器安装的脚本。发送过去并远程执行
    # 关闭防火墙
    systemctl stop firewalld
    systemctl disable firewalld
    # 关闭selinux
    setenforce 0
    sed -i 's/enforcing/disabled/' /etc/selinux/config
    # 关闭swap分区
    sed -ri 's/.*swap.*/#&/' /etc/fstab
    swapoff -a

    cat > /etc/sysctl.d/k8s.conf << EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    vm.swappiness = 0
EOF
    # 加载br_netfilter模块
    modprobe br_netfilter
    sysctl --system

    cat > /etc/sysconfig/modules/ipvs.modules <<EOF
    #!/bin/bash
    modprobe -- ip_vs
    modprobe -- ip_vs_rr
    modprobe -- ip_vs_wrr
    modprobe -- ip_vs_sh
    modprobe -- nf_conntrack_ipv4
EOF
    chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

    # docker配置
    wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
    yum -y install docker-ce-18.06.3.ce-3.el7
    systemctl enable docker && systemctl start docker
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
    {
    "exec-opts": ["native.cgroupdriver=systemd"],	
    "registry-mirrors": ["https://du3ia00u.mirror.aliyuncs.com"],	
    "live-restore": true,
    "log-driver":"json-file",
    "log-opts": {"max-size":"500m", "max-file":"3"},
    "storage-driver": "overlay2"
    }
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    cat > /etc/yum.repos.d/kubernetes.repo << EOF
    [kubernetes]
    name=Kubernetes
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=0
    repo_gpgcheck=0
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

    yum install -y kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0
    vim /etc/sysconfig/kubelet
    # 单独修改这两行
    KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
    KUBE_PROXY_MODE="ipvs"
    systemctl enable kubelet

    hostnamectl set-hostname k8s-master
    hostnamectl set-hostname k8s-worker1
    hostnamectl set-hostname k8s-worker2

    cat >> /etc/hosts << EOF
    ip1 k8s-master
    ip2 k8s-worker1
    ip3 k8s-worker2
EOF

    # master节点执行
    kubeadm init \
    --apiserver-advertise-address=192.168.18.100 \
    --image-repository registry.aliyuncs.com/google_containers \
    --kubernetes-version v1.18.0 \
    --service-cidr=10.96.0.0/12 \
    --pod-network-cidr=10.244.0.0/16
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # worker节点
    kubeadm join 192.168.18.100:6443 --token jv039y.bh8yetcpo6zeqfyj \
    --discovery-token-ca-cert-hash sha256:3c81e535fd4f8ff1752617d7a2d56c3b23779cf9545e530828c0ff6b507e0e26
    # 生成一个永不过期的token
    kubeadm token create --ttl 0 --print-join-command

    # 部署网络插件
    wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    
}
function install_others() {
    # 其它插件安装，如helm等
    :
} 
function teardown() {
    # 部署一个nginx服务，测试集群是否工作正常
    ./core/main.sh post_install
    :
}


function main(){
    setup $@
    install_k8s
    install_others
    teardown
}


main $@