#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

PLATFORM="linux"

KUBETEST_REPO="http://github.com/adelina-t/test-infra"
KUBETEST_BRANCH="azure_provider"

TEST_INFRA_DIR="$HOME/test-infra"
BAZEL_OUTPUT="${TEST_INFRA_DIR}/bazel-bin/kubetest/${PLATFORM}_amd64_stripped/kubetest"

KUBETEST_STORAGE_CONTAINER="k8s-windows"
KUBETEST_STORAGE_BLOB="testing/kubetest/kubetest_$(date '+%Y-%m-%d-%H-%M-%S')/kubetest"
KUBETEST_STORAGE_BLOB_LATEST="testing/kubetest/kubetest_latest/kubetest"

echo "Cloning test infra"
git clone $KUBETEST_REPO ${TEST_INFRA_DIR}
cd $TEST_INFRA_DIR
git checkout $KUBETEST_BRANCH

echo "Building kubetest"
bazel build //kubetest

function upload_blob() {
	az storage blob upload --container-name $1 --name $2 --file $BAZEL_OUTPUT --account-name $AZ_STORAGE_ACCOUNT --account-key $AZ_STORAGE_KEY

}


echo "Uploading kubetest to storage blob"
upload_blob $KUBETEST_STORAGE_CONTAINER $KUBETEST_STORAGE_BLOB
upload_blob $KUBETEST_STORAGE_CONTAINER $KUBETEST_STORAGE_BLOB_LATEST






