#!/bin/bash

# shellcheck disable=SC2068
for node_name in ${!NAME_NODE_MAP[@]}; do
    if [[ ${node_name} != "${MASTER_HOSTNAME}" ]]; then
        # shellcheck disable=SC2087
        ssh -o StrictHostKeyChecking=no "${NAME_NODE_MAP[${node_name}]}" \
        hostnamectl set-hostname "${node_name}"
    fi
done

