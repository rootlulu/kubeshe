#!/bin/bash

yum install expect openssl openssh-server openssh-clients -y

password=${1}
nodes=${@:1}
path="/var/ysm"

./ssh-keygen.exp

for node in ${nodes}; do
    ./ssh-copy-id.exp "${node}" "$password"
done

for node in ${nodes}; do
    ssh StrictHostKeyChecking=no "${node}" mkdir ${path}
    scp StrictHostKeyChecking=no /var/ysm/* "${node}:${path}"
    # ./scp.exp "${node}:/var/ysm"
done