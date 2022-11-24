#!/bin/bash

yum install expect openssl openssh-server openssh-clients -y

./core/ssh/ssh-keygen.exp

# shellcheck disable=SC2068
for node in ${WORKERS[@]}; do
    ./core/ssh/ssh-copy-id.exp "${node}" "$PASSWD"
done

# shellcheck disable=SC2068
for node in ${WORKERS[@]}; do
    # shellcheck disable=SC2087
    ssh -o StrictHostKeyChecking=no "${node}" cat <<EOF
    if [[ -e ${PATH_} ]]; then
        rm -rf "${PATH_}"
    mkdir -p "${PATH_}"
    fi
EOF
    scp -o StrictHostKeyChecking=no -r "${PATH_}/${APP}" "${node}:${PATH_}"
    ./core/ssh/scp.exp "${node}:${PATH_}"
done