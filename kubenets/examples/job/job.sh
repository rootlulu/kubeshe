#!/bin/bash
# shellcheck source=/dev/null

set -eu
set -o pipefail

PATH_="/var/ysm"
APP="kubeshe"
CURRENT=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

function applyjob() {
    local jobName
    kubectl apply -f "${CURRENT}/job.yml"
    if [[ $? -ne 0 ]]; then
        logger error "create job failed."
        exit 1
    fi
    # the job will exists in 30s.
    sleep 20
    jobName=$(kubectl get job -owide | awk '{if ($1 == "busybox-ysm-job") print $1}')
    logger info "The job_name is ${jobName-"cant get the job_name."}"
    if [[ -n ${jobName} ]]; then
        logger info "success"
    else
        logger error "failed"
    fi
}

function deletejob() {
    kubectl delete -f "${CURRENT}/job.yml"
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
        logger info "create the job"
        applyjob
    elif [[ ${1-} = "delete" ]]; then
        logger info "delete the job"
        deletejob
    fi
}

main "$@"
