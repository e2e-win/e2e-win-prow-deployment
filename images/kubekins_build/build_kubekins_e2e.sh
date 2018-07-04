#!/bin/bash

TEST_INFRA_REPO="http://github.com/e2e-win/test-infra"
TEST_INFRA_BRANCH="test_images_private_repo"

TEST_INFRA_BASEDIR=${WORKDIR}/test-infra

KUBEKINS_IMAGE_DIR=${TEST_INFRA_BASEDIR}/images/kubekins-e2e
BOOTSTRAP_IMAGE_DIR=${TEST_INFRA_BASEDIR}/images/bootstrap

# We need to make sure we can push before using docker

gcloud auth configure-docker

git clone $TEST_INFRA_REPO $WORKDIR
cd $TEST_INFRA_BASEDIR
git checkout $TEST_INFRA_BRANCH

echo "building bootstrap image"
cd $BOOTSTRAP_IMAGE_DIR
make push

echo "building kubekins image"
cd $KUBEKINS_IMAGE_DIR
make push

