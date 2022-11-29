#!/bin/bash

# function teardown() {
#     yum -y install bash-completion
#     echo 'source <(kubectl completion bash)' >>~/.bashrc 
#     kubectl completion bash >/etc/bash_completion.d/kubectl
#     kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
#     . /usr/share/bash-completion/bash_completion
# }


function tar_and_run() {
    local file="${APP}.tar.gz"
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
        # cp the join_cmd to nodes.
        scp -r "${PATH_}/${APP}/_join_cmd.sh" "${node}:${PATH_}/${APP}"
    done
}

function post_main() {
    tar_and_run
}