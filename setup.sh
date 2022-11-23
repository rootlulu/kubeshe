#!/bin/bash
# shellcheck disable=SC1017
# shellcheck disable=SC2034
# shellcheck disable=SC2128

# 1. help, verbose等
# 2. yum等源数据
# 3. helm等安装需求


set -eu
# set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"

chmod -R 700 "${PATH_}/${APP}"

USERNAME=
PASSWD=
declare -a NODES
MASTER=
declare -a WORKERS
YUM_URL=
DOCKER_URL=


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
                NODES=("${nodes_str//:/ }")
                MASTER=${NODES}
                # this is a array.
                WORKERS=("${NODES[@]:1:${#NODES[@]}-1}")
                shift
                ;;
            -v | --verbose)
                set -x
                ;;
            --yum_source)
                YUM_URL=${1-}
                valid_empty_value $param $YUM_URL
                shift
                ;;
            --docker_source)
                # todo supprort yum resource setting in the fut ure.
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
    process_params "$@"
    source ./pre.sh
    # 设置yum源, 具体的安装放在对应的功能下面
}


function main(){
    setup "$@"
}


main "$@"