#!/bin/bash

set -x
set -e

set -o pipefail

# Global vars
REPO=${REPO:-"http://github.com/Azure/acs-engine"}
BRANCH=${BRANCH:-"master"}

ACS_DIR=${GOPATH}/src/github.com/Azure/acs-engine
ACS_BIN="$ACS_DIR/bin/acs-engine"

OUTPUT_DIR=$HOME/output
OUTPUT_FILE=${OUTPUT_DIR}/build-log.txt

GS_BUCKET=${GS_BUCKET:-"gs://e2e-win-acs-engine"}
GS_BUCKET_FULL_PATH=${GS_BUCKET}/${REPO_NAME}_${REPO_OWNER}/${PULL_NUMBER}/${JOB_NAME}/${PROW_JOB_ID}/${BUILD_NUMBER}

mkdir -p ${OUTPUT_DIR}

exec &> >(tee -a ${OUTPUT_FILE})

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function upload_results {
    echo "Uploading results"
    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
    gsutil cp -r ${OUTPUT_DIR} ${GS_BUCKET_FULL_PATH}
}
trap upload_results EXIT

function build_acs_engine () {
    git clone $REPO $ACS_DIR
    pushd $ACS_DIR
        git checkout $BRANCH
        if [[ "${JOB_TYPE}" == "presubmit" ]]; then
            # this is a pull request and we should pull the specific ref
            git fetch origin pull/$PULL_NUMBER/head:pr/$PULL_NUMBER
            git merge --no-ff --m "PR to test #${PULL_NUMBER}" pr/$PULL_NUMBER
        fi

        go get github.com/Masterminds/glide

        # build acs-engine
        echo "Installing dependencies"
        glide install || true
        echo "Building acs-engine"
        make build
    popd
}

function upload_blob() {
    tar czf acs-engine-dirty.tar.gz $ACS_BIN
    az-clean storage blob upload --container-name k8s-windows --name acs-engine-dirty.tar.gz --file acs-engine-dirty.tar.gz --account-name $AZ_STORAGE_ACCOUNT --account-key $AZ_STORAGE_KEY
}

function upload_blob_wrapper () {
    set +x
    upload_blob "$@"
    set -x
}

function main () {
    build_acs_engine

    echo "Uploading kubetest to storage blob"
    upload_blob_wrapper
}

main "$@"
