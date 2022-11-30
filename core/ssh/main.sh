#!/bin/bash

yum install expect openssl openssh-server openssh-clients -y

./core/ssh/ssh-keygen.exp

function copy_id() {
    # shellcheck disable=SC2068
    for node in ${WORKERS[@]}; do
        ./core/ssh/ssh-copy-id.exp "${node}" "$PASSWD"
    done
}

function send_file_and_untar() {
    local file="${APP}.tar.gz"
    # shellcheck disable=SC2164
    cd ..  &&   tar -zvcf "${file}" "${APP}" && cd -
    # shellcheck disable=SC2068
    for node in ${WORKERS[@]}; do
        # shellcheck disable=SC2087
        ssh -o StrictHostKeyChecking=no "${node}" cat <<EOF
        if [[ -e ${PATH_} ]]; then
            rm -rf "${PATH_}"
        mkdir -p "${PATH_}"
        fi
EOF
        scp -o StrictHostKeyChecking=no -r "${PATH_}/${file}" "${node}:${PATH_}"
        # ./core/ssh/scp.exp "${APP}.tar.gz" "${node}:${PATH_}"
    done

    #shellcheck disable=SC2068
    for node in ${WORKERS[@]}; do
        # if run a command in a here doc way, the limit string(like EOF) can't be quoted.
        # otherwise it cuts no ice with expansion.
        # if run command immediately, use double-quotes but not single-quotes, it worked.
        # user -tt to force as a tty ans exit. some anwered -T, but it not worked.
        # shellcheck disable=SC2087
        ssh -tto StrictHostKeyChecking=no "${node}" <<EOF
        cd ${PATH_}
        ls | grep -v ${file} | xargs rm -rf
        # rm -rf !(${file})
        tar -zvxf ${file}
        exit
EOF
    done
}
