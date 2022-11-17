#!/bin/bash
# shellcheck disable=SC1017

PATH=${1}
PASSWD=${2}
nodes="${@:2}"

yum install expect openssl openssh-server openssh-clients -y

path="/var/ysm"

./ssh-keygen.exp

for node in ${nodes}; do
    ./ssh-copy-id.exp "${node}" "$PASSWD"
done

for node in ${nodes}; do
    ssh StrictHostKeyChecking=no "${node}" mkdir ${path}
    scp StrictHostKeyChecking=no /var/ysm/* "${node}:${path}"
    # ./scp.exp "${node}:/var/ysm"
done