#!/bin/bash

set -x
set -e

set -o pipefail

function update_config () {
    local config="$1"
    kubectl create configmap $config --from-file=${config}.yaml --dry-run -o yaml | kubectl replace configmap $config -f -
}

function validate () {
    local config="$1"
    git clone "https://github.com/e2e-win/test-infra"
    pushd "test-infra"
        bazel run //prow/cmd/config -- --config-path=$config
    popd
}

function main () {
    git clone "https://github.com/e2e-win/e2e-win-prow-deployment"
    validate "/root/e2e-win-prow-deployment/prow-cluster/configmaps/config.yaml"
    pushd "e2e-win-prow-deployment/prow-cluster/configmaps"
        update_config "config"
    popd
}

main "$@"
