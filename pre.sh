#!/bin/bash
# shellcheck disable=SC1017

APP=$1
YUM_URL=$2
DOCKER_URL=$3
PATH=$4
PASSWD=$5
NODES=${@:5}

function set_yum() {
    local dist
    dist=$(get_distribution)
    case "${dist}" in
    centos)
        # https://stackoverflow.com/questions/6363441/check-if-a-file-exists-with-a-wildcard-in-a-shell-script
        # if [[ $(compgen -G "/etc/yum.repos.d/CentOS-*.repo.bak") ]]; then
        if compgen -G "/etc/yum.repos.d/CentOS-*.repo.bak"; then
            rm -f /etc/yum.repos.d/CentOS-*.repo
            rename '.bak' '' /etc/yum.repos.d/CentOS-*.bak
        else
            sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                -e "s|^#baseurl=http://mirror.centos.org|baseurl=${YUM_URL}|g" \
                -i.bak \
                /etc/yum.repos.d/CentOS-*.repo
            yum makecache
        fi
        ;;
    *)
        echo "Unsupported distribution '$dist'"
        exit 1
        ;;
    esac
}

function set_docker() {
    :
}

function tar_send_and_send() {
    local node
    for node in ${NODES}; do
        tar -zvcf "${APP}.tar.gz" "${PATH}"
        scp "${PATH}/${APP}.tar.gz": "${node}:${PATH}"
        ssh "${node}:${PATH}" <<"EOF"
        tar -zvxf "${PATH}/${APP}.tar.gz"
        "${PATH}/${APP}.setup.sh --ssh" ${USERNAME} ${PASSWD} --yum_source ${YUM_URL} \
        --docker_source ${DOCKER_URL}
EOF
    done
}

function untar_and_run() {
    :
}

function set_no_passwd() {
    ./core/ssh/main.sh "${PATH}" "${PASSWD}" "${NODES}"
}

function mian() {
    set_yum
    set_docker

    yum install ifconfig -y
    if [[ $(ifconfig ens18 | grep 'inet ' | cut -d " " -f 10) == "${MASTER}" ]]; then
        set_no_passwd
        tar_send_and_run
        ssh
    fi

}
