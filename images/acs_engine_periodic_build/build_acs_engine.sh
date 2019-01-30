#!/bin/bash

set -o pipefail
set -x
set -e

OUTPUT_DIR="$HOME/output"
mkdir ${OUTPUT_DIR}
OUTPUT_FILE="${OUTPUT_DIR}/build-log.txt"
exec &> >(tee -a ${OUTPUT_FILE})

GS_BUCKET=${GS_BUCKET:-"gs://e2e-win-acs-engine"}
REPO_NAME=${REPO_NAME:-"e2e-win-prow-deployment"}
REPO_OWNER=${REPO_OWNER:-"e2e-win"}
GS_BUCKET_FULL_PATH=${GS_BUCKET}/${REPO_NAME}_${REPO_OWNER}/${JOB_NAME}/${PROW_JOB_ID}/${BUILD_NUMBER}

ACS_ENGINE_ORG=${ACS_ENGINE_ORG:-"Azure"}
ACS_ENGINE_REPO="http://github.com/${ACS_ENGINE_ORG}/acs-engine.git"
ACS_ENGINE_BRANCH=${ACS_ENGINE_BRANCH:-"master"}

ACS_ENGINE_DIR="$GOPATH/src/github.com/Azure/acs-engine"
ACS_ENGINE_TAR="$ACS_ENGINE_DIR/bin/acs-engine.tar.gz"

ACS_ENGINE_STORAGE_CONTAINER="k8s-windows"
ACS_ENGINE_STORAGE_BLOB="testing/acs-engine/acs-engine_latest/acs-engine-latest.tar.gz"

function upload_results {
    # Uploading results
    echo "Uploading results"
    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
    gsutil cp -r ${OUTPUT_DIR} ${GS_BUCKET_FULL_PATH}
}

function wrapper_upload {
    upload_results
}

trap wrapper_upload EXIT

echo "Cloning acs-engine"
git clone $ACS_ENGINE_REPO ${ACS_ENGINE_DIR}

pushd $ACS_ENGINE_DIR

git checkout $ACS_ENGINE_BRANCH

echo "Building acs-engine"
make build
popd

pushd $ACS_ENGINE_DIR/bin

./acs-engine version

mkdir acs_dir
mv acs-engine acs_dir

tar -zcf acs-engine.tar.gz acs_dir

popd

function upload_blob() {
    az storage blob upload --container-name $1 --name $2 --file $ACS_ENGINE_TAR --account-name $AZ_STORAGE_ACCOUNT --account-key $AZ_STORAGE_KEY
}

function upload_blob_wrapper () {
    set +x
    upload_blob "$@"
    set -x
}

echo "Uploading acs-engine to storage blob"
upload_blob_wrapper $ACS_ENGINE_STORAGE_CONTAINER $ACS_ENGINE_STORAGE_BLOB
