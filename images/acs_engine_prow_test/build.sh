#!/bin/bash

set -o pipefail
set -x
set -e

REPO=${REPO:-"http://github.com/Azure/acs-engine"}
BRANCH=${BRANCH:-"master"}

OUTPUT_DIR=$HOME/output
ACS_DIR=${GOPATH}/src/github.com/Azure/acs-engine
mkdir ${OUTPUT_DIR}
mkdir -p $ACS_DIR

git clone $REPO $ACS_DIR
cd $ACS_DIR
git checkout master

# install glide
go get github.com/Masterminds/glide

# build acs-engine
echo "Installing dependencies"
glide install
echo "Building acs-engine"
make build

# Add acs-engine build dir to path

PATH=$PATH:${ACS_DIR}/bin

acs-engine version

# Download kubetest from latest win-e2e-build

KUBETEST_URL="https://k8swin.blob.core.windows.net/k8s-windows/testing/kubetest/kubetest_latest/kubetest"
wget https://k8swin.blob.core.windows.net/k8s-windows/testing/kubetest/kubetest_latest/kubetest -P $HOME
KUBETEST=${HOME}/kubetest
chmod +x ${KUBETEST}

# Clone kubernetes

KUBE_REPO=${KUBE_REPO:-"http://github.com/e2e-win/kubernetes"}
KUBE_DIR=${GOPATH}/src/k8s.io/kubernetes
mkdir -p $KUBE_DIR

git clone $KUBE_REPO $KUBE_DIR
cd $KUBE_DIR

# Run kubetest
# Note environment variables are set by the prow job
echo "Running kubetest"

${KUBETEST} --deployment=acsengine --provider=azure --test=true --up=true --down=false --build=bazel --ginkgo-parallel=10 --acsengine-admin-password=Passw0rdAdmin --acsengine-admin-username=azureuser --acsengine-orchestratorRelease=1.11 --acsengine-creds=$AZURE_CREDENTIALS --acsengine-public-key=$AZURE_SSH_PUBLIC_KEY_FILE --acsengine-winZipBuildScript=$WIN_BUILD --acsengine-location=westus2 --test_args="--ginkgo.dryRun=false --ginkgo.focus=\\[Conformance\\]|\\[NodeConformance\\]" 
