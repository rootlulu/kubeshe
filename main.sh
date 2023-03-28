#!/bin/bash
# shellcheck disable=SC2034
# shellcheck source=/dev/null
# 1. help, verbose等
# 2. yum等源数据
# 3. helm等安装需求

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"

chmod -R 700 "${PATH_}/${APP}"

USERNAME=
PASSWD=
declare -a NODES
MASTER=
MASTER_HOSTNAME="k8s-master"
declare -a WORKERS
WORKER_HOSTNAME_PREFIX="k8s-node"
declare -A NAME_NODE_MAP
YUM_URL=
DOCKER_URL=

# Generate the join sentence in master, then scp to workers and run it.
JOIN_CMD_SHELL="_join_cmd.sh"

# deploy kube config
KUBE_VERSION=v1.21.10
SERVICE_CIDR="10.96.0.0/16"
POD_NETWORK_CIDR="10.244.0.0/16"

# the k8s exact version.
KUBELET="kubelet-1.21.10"
KUBEADM="kubeadm-1.21.10"
KUBECTL="kubectl-1.21.10"

function help() {
    cat <<EOF
    Support: Only validated in CentOs7 and its kernel is lastest: 5.16.12. And you
            have stopped the firewalld.

    Usage: ${BASH_SOURCE[0]} {-v|verbose} --ssh <username> <password>
            --k8s_nodes <master:node1:node2:...>
            [--yum_source <yum_url>] [--docker_source <docker_url>]

        -h | --help                     show help message

    Required:
        --ssh <username>
                <passwd>                  set the shh connection
        --k8s_nodes <master:node1:node2:...>    the master and the nodes separated by :

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
        logger error "the $k's value is empty"
        exit 1
    else
        while [[ $# -gt 0 ]]; do
            if [[ -z ${1-} ]]; then
                logger error "the $k's value is empty"
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
        case ${param} in
        -h | --help)
            help
            exit 0
            ;;
        --ssh)
            if [[ -n ${param} ]]; then
                ssh_provided=true
            fi
            USERNAME=${1-}
            PASSWD=${2-}
            valid_empty_value "${param}" "${USERNAME}" "$PASSWD"
            shift
            shift
            :
            ;;
        --k8s_nodes)
            if [[ -n ${param} ]]; then
                nodes_provided=true
            fi
            local nodes_str=${1-}
            valid_empty_value "${param}" "${nodes_str}"
            # shellcheck disable=SC2206
            # NODES=(${nodes_str//:/ })
            local true_ifs=${IFS}
            IFS=":"
            # shellcheck disable=SC2206
            NODES=(${nodes_str})
            IFS=${true_ifs}
            for num in $(seq 1 $((${#NODES[@]}))); do
                if [[ ${num} = 1 ]]; then
                    MASTER=${NODES[${num} - 1]}
                    NAME_NODE_MAP[${MASTER_HOSTNAME}]=${MASTER}
                else
                    WORKERS+=("${NODES[${num} - 1]}")
                    NAME_NODE_MAP[${WORKER_HOSTNAME_PREFIX}$((num - 1))]=${NODES[${num} - 1]}
                fi
            done
            shift
            ;;
        -v | --verbose)
            set -x
            ;;
        --yum_source)
            YUM_URL=${1-}
            valid_empty_value "${param}" "${YUM_URL}"
            shift
            ;;
        --docker_source)
            # todo supprort yum resource setting in the future. default is aliyun.
            DOCKER_URL=${1-}
            valid_empty_value "${param}" "${DOCKER_URL}"
            shift
            ;;
        *)
            logger error "No valid pararms provided. \n"
            help
            exit 1
            ;;
        esac
    done

    # if [[ $ssh_provided && $nodes_provided ]]; then
    if ! $ssh_provided; then
        logger error "The required param is not provided!: --ssh!"
        exit 1
    elif ! $nodes_provided; then
        logger error "The required param is not provided!: --k8s_nodes!"
        exit 1
    fi

}

function setup() {
    logger info "$(beauty "setUp starting.")"
    process_params "$@"
    # set yum docker and others. then tar the install package to other nodes and
    # set all nodes' hostname.
    pre_main
    logger info "$(beauty "setUp finished.")"
}

function run() {
    logger info "$(beauty "Install k8s starting.")"
    install_common
    if isMaster; then
        logger info "$(beauty "Install master starting." 60)"
        init_master
        send_file_and_untar
        for node in "${WORKERS[@]}"; do
            logger info "$(beauty "Install node starting." 60)"
            remote_ssh "${node}" \
                "cd "${PATH_}/${APP}"" \
                "./main.sh --ssh ${USERNAME} ${PASSWD} --k8s_nodes $(
                    IFS=:
                    echo "${NODES[*]}"
                ) -v"
        done
    else
        # running only in the workers.
        logger info "$(beauty "join in cluster." 60)"
        join_cluster
    fi
    logger info "$(beauty "Install k8s finished.")"
}

function teardown() {
    if isMaster; then
        if successInstalled; then
            logger info "Installation test passed"
        else
            logger error "Installation test failed. please check it."
        fi
    fi
}

function main() {
    logger info "$(beauty "loading all utils...")"
    # source all scripts.
    . ./utils.sh
    . ./common_install_utils.sh
    . ./master_install_utils.sh
    . ./node_install_utils.sh
    . ./pre.sh
    . ./post.sh
    logger info "$(beauty "loaded all utils...")"

    setup "$@"
    run
    teardown
}

startTime=$(date +%Y%m%d-%H:%M:%S)
startTime_s=$(date +%s)

main "$@"

endTime=$(date +%Y%m%d-%H:%M:%S)
endTime_s=$(date +%s)
sumTime=$((endTime_s - startTime_s))
printf "%s ---> %s \n Total:%s seconds" "$startTime" "$endTime" "$sumTime"
