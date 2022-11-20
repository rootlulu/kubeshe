#!/bin/bash
# shellcheck disable=SC1017


_get_distribution() {
    local lsb_dist=
    if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    # perform some very rudimentary platform detection
    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

    # Returning an empty string here should be alright since the
    # case statements don't act unless you provide an actual value
    echo "$lsb_dist"
}

function set_yum() {
    if [[ -z ${YUM_URL} ]]; then
        YUM_URL="http://mirrors.aliyun.com"
    fi
    local dist
    dist=$(_get_distribution)
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
    for node in ${WORKERS}; do
        tar -zvcf "${APP}.tar.gz" "${PATH_}"
        scp "${PATH_}/${APP}.tar.gz": "${node}:${PATH_}"
        ssh "${node}:${PATH_}" <<"EOF"
        tar -zvxf "${PATH_}/${APP}.tar.gz"
        "${PATH_}/${APP}.setup.sh --ssh" ${USERNAME} ${PASSWD} --yum_source ${YUM_URL} \
        --docker_source ${DOCKER_URL}
EOF
    done
}

function untar_and_run() {
    :
}

function set_no_passwd() {
    # shellcheck source=/dev/null
    . ./core/ssh/main.sh
}

function pre_main() {
    set_yum
    set_docker

    yum install net-tools -y
    if [[ $(ifconfig ens18 | grep 'inet ' | cut -d " " -f 10) == "${MASTER}" ]]; then
        set_no_passwd
        tar_send_and_run
        # ssh
    fi

}

# Invoke main with args if not sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2>/dev/null); then
    echo "ERROR: Must run this shell in current process."
fi

pre_main