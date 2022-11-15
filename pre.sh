#!/bin/bash

YUM_URL=$1
DOCKER_URL=$2

function set_yum() {
    dist=$(get_distribution)
    case "$dist" in
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