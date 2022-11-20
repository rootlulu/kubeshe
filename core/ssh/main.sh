#!/bin/bash
# shellcheck disable=SC1017

yum install expect openssl openssh-server openssh-clients -y

./core/ssh/ssh-keygen.exp

for node in ${WORKERS}; do 
    ./core/ssh/ssh-copy-id.exp "${node}" "$PASSWD"
done

for node in ${WORKERS}; do
    ssh -o StrictHostKeyChecking=no "${node}" cat <<EOF
    if ! [[ -e ${PATH_}/${APP} ]]; then
        echo "666666666666666666666"
        mkdir -p "${PATH_}/${APP}"
    else
        echo "777777777777777777777"
        rm -rf "${PATH_}/${APP}"
    fi
EOF
    scp -o StrictHostKeyChecking=no -r "${PATH_}/${APP}" "${node}:${PATH_}"
    # ./scp.exp "${node}:/var/ysm"
done