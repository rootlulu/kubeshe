#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applycronjob() {
    local cronjobName
    kubectl apply -f "${CURRENT}/cronjob.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create cronjob failed."
        exit 1
    fi
    # the cronjob will exists in 20s.
    sleep 20

    local count=0
    while [[ ${count} -lt 5 ]]; do
        names=$(kubectl get cj,job,pod -owide | awk '{if ($1 ~ "cronjob") print $1}')
        names_array=(${names})
        logger info "The resource name is ${names-"cant get the resource's name."}"

        # cronjob, job, pod
        if [[ -n ${names_array} && ${#names_array[@]} = 3 ]]; then
            if ! [[ $(echo ${names_array[0]} | grep -q -e "cronjob" -e "ysm") || $(echo ${names_array[1]} | grep -q -e "job" -e "def") || $(echo ${names_array[2]} | grep -q -e "pod" -e "ysm") ]]; then
                logger info "success"
                return
            else
                logger error "failed"
            fi
        else
            count = ${count}+1
            sleep 20
        fi
    done
}

function deletecronjob() {
    kubectl delete -f "${CURRENT}/cronjob.yml"
    if [[ $? -eq 0 ]];then 
        logger info "success"
    else
        logger error "failed"
    fi
}


function main() {
    echo "The execute entry: $(pwd)"
    . ${PATH_}/${APP}/utils.sh
    array=("apply" "create" "delete")
    if ! [[ "${array[*]}" =~ "${1-"996die"}" ]]; then
        logger error "The invalid first param. it must be apply, create or delete."
    fi

    if [[ ${1-} = "apply" || ${1-} = "create" ]]; then
        logger info "create the cronjob"
        applycronjob
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete the cronjob"
        deletecronjob
    fi
}

main "$@"
