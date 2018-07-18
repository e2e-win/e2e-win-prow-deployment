#!/bin/bash

set -x
set -o errexit
set -o nounset
set -o pipefail

function cleanup_binfmt_misc () {
    if [ ! -f /proc/sys/fs/binfmt_misc/status ]; then
        mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
    fi
    echo -1 >/proc/sys/fs/binfmt_misc/status
    ls -al /proc/sys/fs/binfmt_misc
}

function cleanup_dind () {
    barnacle || true
    echo "Remaining docker images and volumes are:"
    docker images --all || true
    docker volume ls || true
    echo "Cleaning up binfmt_misc ..."
    (set -x; cleanup_binfmt_misc || true)
}

function start_dockerd () {
    export DOCKER_IN_DOCKER_ENABLED=${DOCKER_IN_DOCKER_ENABLED:-false}
    if [[ "${DOCKER_IN_DOCKER_ENABLED}" == "true" ]]; then
        echo "Docker in Docker enabled, initializing..."
        printf '=%.0s' {1..80}; echo
        service docker start
        WAIT_N=0
        MAX_WAIT=5
        while true; do
            # docker ps -q should only work if the daemon is ready
            docker ps -q > /dev/null 2>&1 && break
            if [[ ${WAIT_N} -lt ${MAX_WAIT} ]]; then
                WAIT_N=$((WAIT_N+1))
                echo "Waiting for docker to be ready, sleeping for ${WAIT_N} seconds."
                sleep ${WAIT_N}
            else
                echo "Reached maximum attempts, not waiting any longer..."
                break
            fi
        done
        cleanup_dind
        printf '=%.0s' {1..80}; echo
        echo "Done setting up docker in docker."
    fi
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function clone () {
    local repo="$1"; shift
    local clone_target="$1"

    folder_name=${repo##*/}
    folder_name=${folder_name%.*}

    git clone "$repo" "$clone_target"
    pushd "$clone_target"
        git config --global user.email "e2e-win@xample.com"
        git config --global user.name  "Prow Job Bot"
    popd
    echo "$clone_target"
}

function merge_pr () {
    local pull_base_ref="$1"; shift
    local pull_base_sha="$1"; shift
    local pull_number="$1";   shift
    local pull_pull_sha="$1"

    git fetch origin pull/"$pull_number"/head:"temp_branch"

    git checkout "$pull_base_ref"
    git merge --no-ff -m "PR to test #$pull_number" "temp_branch"
}

function build_target () {
    local target_folder="$1"; shift
    local is_pull_request="$1"

    if [ $is_pull_request == "true" ]; then
        local target="build"
    else
        local target="push"
        gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
        gcloud auth configure-docker
    fi

    source /root/.bashrc
    pushd "$target_folder"
        make $target
    popd
}

function main () {

    PULL_NUMBER=${PULL_NUMBER:-}
    PULL_BASE_SHA=${PULL_BASE_SHA:-}
    PULL_BASE_REF=${PULL_BASE_REF:-}

    if [ -z $PULL_NUMBER ] && [ $JOB_TYPE != "presubmit" ]; then
        echo "env var PULL_NUMBER is empty"
        local IS_PULL_REQUEST="false"
    else
        local IS_PULL_REQUEST="true"
    fi
    if [ -z $PULL_BASE_SHA ]; then  echo "env var PULL_BASE_SHA is empty" ; exit 1; fi
    if [ -z $PULL_BASE_REF ]; then  echo "env var PULL_BASE_REF is empty" ; exit 1; fi

    local REPO="http://github.com/e2e-win/e2e-win-prow-deployment"

    local IMAGE_DIR="images/acs_engine_prow_test"

    local clone_target="e2e-win-prow-deployment"

    start_dockerd

    folder=$(clone "$REPO" "$clone_target")
    pushd "$folder"
        if [ -z $IS_PULL_REQUEST ]; then
            merge_pr "$PULL_BASE_REF" "$PULL_BASE_SHA" "$PULL_NUMBER" "$PULL_PULL_SHA"
        fi
        echo "IS_PULL_REQUEST is $IS_PULL_REQUEST"
        build_target "$IMAGE_DIR" "$IS_PULL_REQUEST"
    popd

    if [[ "${DOCKER_IN_DOCKER_ENABLED}" == "true" ]]; then
        echo "Cleaning up after docker in docker."
        cleanup_dind
        echo "Done cleaning up after docker in docker."
    fi
}

main "$@"
