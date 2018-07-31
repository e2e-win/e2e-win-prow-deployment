#!/bin/bash

set -o pipefail
set -x
set -e

OUTPUT_DIR="$HOME/output"
mkdir ${OUTPUT_DIR}
OUTPUT_FILE="${OUTPUT_DIR}/build-log.txt"
exec &> >(tee -a ${OUTPUT_FILE})

GS_BUCKET=${GS_BUCKET:-"gs://e2e-win-acs-engine"}
GS_BUCKET_FULL_PATH=${GS_BUCKET}/${REPO_NAME}_${REPO_OWNER}/${PULL_NUMBER}/${JOB_NAME}/${PROW_JOB_ID}/${BUILD_NUMBER}

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')

KUBETEST_REPO="http://github.com/e2e-win/test-infra"
KUBETEST_BRANCH="azure_provider"

TEST_INFRA_DIR="$HOME/test-infra"
BAZEL_OUTPUT="${TEST_INFRA_DIR}/bazel-bin/kubetest/${PLATFORM}_amd64_stripped/kubetest"

KUBETEST_STORAGE_CONTAINER="k8s-windows"
KUBETEST_STORAGE_BLOB="testing/kubetest/kubetest_$(date '+%Y-%m-%d-%H-%M-%S')/kubetest"
KUBETEST_STORAGE_BLOB_LATEST="testing/kubetest/kubetest_latest/kubetest"

GINKGO_PARALLEL=${GINKGO_PARALLEL:-10}
AGENT_NODES=${AGENT_NODES:-4}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"azure"}

AZ_RG_NAME=${JOB_NAME}-${PROW_JOB_ID}
AZ_DEPLOYMENT_NAME=prow-${PROW_JOB_ID}

ACS_API_MODEL_FILES=("kubernetes.json" "apimodel.json")
ACS_API_MODEL_SENSITIVE_KEYS=("secret" "clientId" "keyData" "clientPrivateKey" "caCertificate" "etcdServerPrivateKey" \
                              "apiServerCertificate" "clientCertificate" "etcdClientPrivateKey" "etcdServerCertificate" \
                              "caPrivateKey" "etcdClientCertificate" "etcdPeerCertificates" "etcdPeerPrivateKeys" "kubeConfigPri      vateKey" \
                              "apiServerPrivateKey" "kubeConfigCertificate")

function redact_file {
    # redact sensitive information from the logs ( i.e clientSecret / clientId etc )
    for key in ${ACS_API_MODEL_SENSITIVE_KEYS[@]}; do
          sed -i "/\"${key}\": \[/,+2d" $1
          sed -i "/${key}/d" $1
    done
}

function copy_acs_engine_logs {
    # we use a regex here, not really pretty, but it will work since we know for a fact it's the only dir to match.
    # kubetest generates logs in a tempdir with the form acs[0-9]+
    # we use \+ instead of + because sed type regex
    acs_folders=$(find $HOME -regextype sed -regex "$HOME/acs[0-9]\+")
    for folder in $acs_folders; do
        pushd $folder
        for file in ${ACS_API_MODEL_FILES[@]}; do
                # first redact, then copy. If redating fails for some reason, the logs will end up on the server in clear
                # since pushing logs is automatic on exit
                redact_file $file
                cp $file $OUTPUT_DIR
        done
    done
    popd
}

function upload_results {
    # Uploading results
    echo "Uploading results"
    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
    gsutil cp -r ${OUTPUT_DIR} ${GS_BUCKET_FULL_PATH}
}

function wrapper_upload {
    copy_acs_engine_logs
    upload_results
}

trap wrapper_upload EXIT

function get_random_azure_location {
    AZURE_AVAILABLE_LOCATIONS=("southeastasia" "eastus" "southcentralus" "westeurope" "westus2")
    loc_count=${#AZURE_AVAILABLE_LOCATIONS[@]}
    echo ${AZURE_AVAILABLE_LOCATIONS[$(($RANDOM % $loc_count))]}
}

LOCATION=$(get_random_azure_location)

echo "Cloning test infra"
git clone $KUBETEST_REPO ${TEST_INFRA_DIR}
pushd $TEST_INFRA_DIR
git checkout $KUBETEST_BRANCH

echo "Building kubetest"
bazel build //kubetest
popd

KUBE_REPO=${KUBE_REPO:-"http://github.com/e2e-win/kubernetes"}
KUBE_DIR=${GOPATH}/src/k8s.io/kubernetes
mkdir -p $KUBE_DIR

git clone $KUBE_REPO $KUBE_DIR
pushd $KUBE_DIR

echo "Running kubetest"
export KUBECTL_PATH=$(which kubectl)
$BAZEL_OUTPUT --deployment=acsengine --provider=azure --test=false --up=true --down=true --ginkgo-parallel=${GINKGO_PARALLEL} \
              --acsengine-resource-name=${AZ_DEPLOYMENT_NAME} --acsengine-agentpoolcount=${AGENT_NODES} \
              --acsengine-resourcegroup-name=${AZ_RG_NAME} --acsengine-admin-password=Passw0rdAdmin \
              --acsengine-admin-username=azureuser --acsengine-orchestratorRelease=1.11 \
              --acsengine-hyperkube-url=k8s-gcrio.azureedge.net/hyperkube-amd64:v1.11.0 \
              --acsengine-win-binaries-url=https://acs-mirror.azureedge.net/wink8s/v1.11.0-1int.zip \
              --acsengine-creds=$AZURE_CREDENTIALS --acsengine-public-key=$AZURE_SSH_PUBLIC_KEY_FILE \
              --acsengine-winZipBuildScript=$WIN_BUILD --acsengine-location=${LOCATION} \
              --acsengine-download-url=https://github.com/Azure/acs-engine/releases/download/v0.19.5/acs-engine-v0.19.5-linux-amd64.tar.gz

popd

function upload_blob() {
    az-clean storage blob upload --container-name $1 --name $2 --file $BAZEL_OUTPUT --account-name $AZ_STORAGE_ACCOUNT --account-key $AZ_STORAGE_KEY
}

function upload_blob_wrapper () {
    set +x
    upload_blob "$@"
    set -x
}

echo "Uploading kubetest to storage blob"
upload_blob_wrapper $KUBETEST_STORAGE_CONTAINER $KUBETEST_STORAGE_BLOB
upload_blob_wrapper $KUBETEST_STORAGE_CONTAINER $KUBETEST_STORAGE_BLOB_LATEST
