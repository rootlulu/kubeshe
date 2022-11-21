#!/bin/bash
# shellcheck disable=SC1017

yum install expect openssl openssh-server openssh-clients -y

./core/ssh/ssh-keygen.exp

for node in ${WORKERS}; do 
    ./core/ssh/ssh-copy-id.exp "${node}" "$PASSWD"
done

for node in ${WORKERS}; do
    ssh -o StrictHostKeyChecking=no "${node}" cat <<EOF
    if [[ -e ${PATH_} ]]; then
        rm -rf "${PATH_}"
    mkdir -p "${PATH_}"
    fi
EOF
    scp -o StrictHostKeyChecking=no -r "${PATH_}/${APP}" "${node}:${PATH_}"
    # ./scp.exp "${node}:/var/ysm"
done