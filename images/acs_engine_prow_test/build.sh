#!/bin/bash

set -o pipefail
set -x
set -e

OUTPUT_DIR=$HOME/output
ARTIFACTS_DIR=$OUTPUT_DIR/artifacts
mkdir ${OUTPUT_DIR}
mkdir ${ARTIFACTS_DIR}
OUTPUT_FILE=$HOME/build-log.txt
exec &> >(tee -a ${OUTPUT_FILE})

AZ_RG_NAME=${JOB_NAME}-${PROW_JOB_ID}
AZ_DEPLOYMENT_NAME=prow-${PROW_JOB_ID}

GS_BUCKET=${GS_BUCKET:-"gs://e2e-win-acs-engine"}
GS_BUCKET_FULL_PATH=${GS_BUCKET}/${REPO_NAME}_${REPO_OWNER}/${PULL_NUMBER}/${JOB_NAME}/${PROW_JOB_ID}/${BUILD_NUMBER}

ACS_GENERATE_DIR_REGEX="${HOME}/acs*"
ACS_API_MODEL_FILES=("kubernetes.json" "apimodel.json")
ACS_API_MODEL_SENSITIVE_KEYS=("secret" "clientId" "keyData" "clientPrivateKey" "caCertificate" "etcdServerPrivateKey" \
                              "apiServerCertificate" "clientCertificate" "etcdClientPrivateKey" "etcdServerCertificate" \
                              "caPrivateKey" "etcdClientCertificate" "etcdPeerCertificates" "etcdPeerPrivateKeys" "kubeConfigPrivateKey" \
                              "apiServerPrivateKey" "kubeConfigCertificate")

GINKGO_PARALLEL=${GINKGO_PARALLEL:-10}
AGENT_NODES=${AGENT_NODES:-4}
NETWORK_PLUGIN=${NETWORK_PLUGIN:-"azure"}
OS_TYPE=${OS_TYPE:-"Windows"}

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
    pushd ${ACS_GENERATE_DIR_REGEX}
    for file in ${ACS_API_MODEL_FILES[@]}; do
            # first redact, then copy. If redating fails for some reason, the logs will end up on the server in clear
            # since pushing logs is automatic on exit
            redact_file $file
            cp $file $OUTPUT_DIR
    done
    popd
}

function upload_results {

    # Uploading results
    echo "Uploading results"
    gsutil -m cp -r ${OUTPUT_DIR} ${GS_BUCKET_FULL_PATH}
    echo "Finished uploading results"
    gsutil -m cp ${OUTPUT_FILE} ${GS_BUCKET_FULL_PATH}
    

}

trap "upload_results" EXIT


REPO=${REPO:-"http://github.com/${REPO_OWNER}/${REPO_NAME}"}
BRANCH=${BRANCH:-"master"}

function prepare_repo {

    git config --global user.email "e2e-win@example.com"
    git config --global user.name "Prow Job Bot"
    git clone $REPO $ACS_DIR
    pushd $ACS_DIR
    git checkout $BRANCH
    git show --name-only

    if [ "${JOB_TYPE}" == "presubmit" ]
    then
        # this is a pull request and we should pull the specific ref
        git fetch origin pull/$PULL_NUMBER/head:pr/$PULL_NUMBER
        git merge --no-ff --m "PR to test #${PULL_NUMBER}" pr/$PULL_NUMBER
    fi
    git status
}

# Init gcloud

gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

ACS_DIR=${GOPATH}/src/github.com/Azure/acs-engine
mkdir -p $ACS_DIR
prepare_repo
# install glide
go get github.com/Masterminds/glide

# build acs-engine
echo "Installing dependencies"

# acs-engine PR #3522 intends on replacing glide with godeps.
# Glide will obv not work for this pr, hacking so that it will build
# both this PR and the ones the still use glide
# until this PR gets merged.
glide install || true 
echo "Building acs-engine"
make build
popd

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
pushd $KUBE_DIR

# Building tests, ginkgo and kubectl
# Normally kubetest would build all k8s, but since we only need these components
# it's much faster to build by hand.

make WHAT="test/e2e/e2e.test cmd/kubectl vendor/github.com/onsi/ginkgo/ginkgo"


# Run kubetest
# Note environment variables are set by the prow job
echo "Running kubetest"


# TO DO (atuvenie): hyperkube and zip should be passed as params

AZURE_AVAILABLE_LOCATIONS=("southeastasia" "eastus" "southcentralus" "westeurope" "westus2")

function get_random_azure_location {
    loc_count=${#AZURE_AVAILABLE_LOCATIONS[@]}
    echo ${AZURE_AVAILABLE_LOCATIONS[$(($RANDOM % $loc_count))]}
}

LOCATION=$(get_random_azure_location)

set +e


${KUBETEST} --deployment=acsengine --provider=azure --test=true --up=true --down=true --ginkgo-parallel=${GINKGO_PARALLEL} \
                --acsengine-resource-name=${AZ_DEPLOYMENT_NAME} --acsengine-agentpoolcount=${AGENT_NODES} \
                --acsengine-resourcegroup-name=${AZ_RG_NAME} --acsengine-admin-password=Passw0rdAdmin \
                --acsengine-admin-username=azureuser --acsengine-orchestratorRelease=1.11 \
                --acsengine-hyperkube-url=k8s-gcrio.azureedge.net/hyperkube-amd64:v1.11.2 \
                --acsengine-win-binaries-url=https://acs-mirror.azureedge.net/wink8s/v1.11.2-1int.zip \
                --acsengine-creds=$AZURE_CREDENTIALS --acsengine-public-key=$AZURE_SSH_PUBLIC_KEY_FILE \
                --acsengine-winZipBuildScript=$WIN_BUILD --acsengine-location=${LOCATION} \
                --acsengine-networkPlugin=${NETWORK_PLUGIN} \
                --acsengine-agentOSType=${OS_TYPE} \
                --test_args="--ginkgo.dryRun=false --ginkgo.noColor --ginkgo.flakeAttempts=3 --ginkgo.focus=\\[Conformance\\]|\\[NodeConformance\\] --ginkgo.skip=\\[Serial\\]|\\[sig-storage\\].ConfigMap.should.be.consumable.from.pods.in.volume.as.non-root.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].ConfigMap.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].ConfigMap.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.mode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].ConfigMap.should.be.consumable.from.pods.in.volume.with.mappings.as.non-root.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Secrets.should.be.consumable.from.pods.in.volume.as.non-root.with.defaultMode.and.fsGroup.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Secrets.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Secrets.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.Mode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.as.non-root.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.as.non-root.with.defaultMode.and.fsGroup.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.mode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.Mode.set.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.be.consumable.from.pods.in.volume.with.mappings.as.non-root.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.set.DefaultMode.on.files.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Projected.should.set.mode.on.item.file.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Downward.API.volume.should.set.DefaultMode.on.files.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].Downward.API.volume.should.set.mode.on.item.file.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(non-root,0644,default\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(non-root,0644,tmpfs\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(non-root,0666,default\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(non-root,0666,tmpfs\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(non-root,0777,default\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(non-root,0777,tmpfs\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(root,0644,default\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(root,0644,tmpfs\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(root,0666,default\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(root,0666,tmpfs\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(root,0777,default\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.should.support.\\(root,0777,tmpfs\\).\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.volume.on.default.medium.should.have.the.correct.mode.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].EmptyDir.volumes.volume.on.tmpfs.should.have.the.correct.mode.\\[NodeConformance\\].\\[Conformance\\]|\\[sig-storage\\].HostPath.should.give.a.volume.the.correct.mode.\\[NodeConformance\\].\\[Conformance\\]" \
                --dump=$ARTIFACTS_DIR
set -e
popd
#./check_tests.py "$ARTIFACTS_DIR/junit_runner.xml"

if [ -f $ARTIFACTS_DIR/junit_runner.xml ]; then
   echo "File $ARTIFACTS_DIR/junit_runner.xml exists."
else
   echo "File $ARTIFACTS_DIR/junit_runner.xml does not exist."
fi

echo "ls $ARTIFACTS_DIR"
ls $ARTIFACTS_DIR


copy_acs_engine_logs
