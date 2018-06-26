# Prow jobs, configuration and deployment scripts for K8s win-e2e testing


### [Kubetest binaries](./KUBETEST_BUILDS.md) 

### K8s Windown E2E Prow

#### http://k8s-win-prow.eastus.cloudapp.azure.com

### PRs to this repo will automatically start e2e conformance tests

### Running E2E tests manually

1. Using kubetest to create new cluster on Azure via acs-engine

Get latest kubetest binary form [here](./KUBETEST_BUILDS.md)

```
cd $GOPATH/src/k8s/kubernetes

kubetest --provider=azure --deployment=azure --test=true --up=true --down=true --extract=ci/latest --acsengine-admin-password=password --acsengine-admin-username=username --acs-engine-download-url=https://stable.acs.tar.gz --acsengine-creds=/azure/credentials/file --acsengine-location=location --acsengine-orchestratorRelease=1.11 --test_args=--ginkgo.dryRun=true --ginkgo.focus=\\[Conformance\\]\\[NodeConformance\\]
```

Credentials for azure will be read from a file with the following format:

```
[Creds]
  ClientID = ""
  ClientSecret = ""
  SubscriptionId = ""
  TenantID = ""
  StorageAccountName = ""
  StorageAccountKey = ""

  ```
NOTE: kubetest builds a zip containing binaries for windows and a hyperkube image that will be used by acs-engine to deploy the cluster. Storage account in Azure is needed for this.

2. Run tests on already existing cluster using kubetest

```
export KUBE_MASTER=local
export KUBE_MASTER_IP=#masterIP
export KUBE_MASTER_URL=https://#masterIP
export KUBECONFIG=/path/to/kubeconfig
export KUBE_TEST_REPO_LIST=/path/to/repo/repo_list.yaml
```

```
cd $GOPATH/src/kubernetes

make WHAT=test/e2e/e2e.test

go run hack/e2e.go -- --provider=local -v --test --test_args=--ginkgo.focus="focus_regex --ginkgo.skip=skip_regex" 

```
