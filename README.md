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

## NOTE:

Either using kubetes, hack/e2e.go or e2e.test the same parameter list applies to all 3.

### Short parameter description

```
--provider : you should use local for testing against existing clusters
--ginkgo-parallel : number of parallel ginkgo nodes to use for running tests.
--test_args : ginkgo specific arguments like ginkgo.focus, ginkgo.skip , ginkgo.dryRun
```

### Repo list for windows clusters:

For windows clusters running windows 1803 nodes, use the following repo list ( KUBE_TEST_REPO_LIST ):

```
dockerLibraryRegistry: e2eteam
e2eRegistry: e2eteam
gcRegistry: e2eteam
hazelcastRegistry: e2eteam
PrivateRegistry: e2eteam
sampleRegistry: e2eteam
stormRegistry: e2eteam
zookeeperRegistry: e2eteam
```

### Windows skipped tests:

Not all e2e tests can be run on windows clusters. An example of running test with kubetest command ( arguments apply to every alternative for running tests ), in parallel against an existing cluster with skipped tests for windows.

Skipped tests list is maintained here: https://github.com/e2e-win/e2e-win-prow-deployment/blob/master/exclude_conformance_test.txt and gets more regularly updated than this doc.

```
kubetest --provider=local --test=true --ginkgo-parallel=6 "--test_args=--ginkgo.dryRun=false --ginkgo.noColor --ginkgo.focus=\[Conformance\]|\[NodeConformance\] --ginkgo.skip=\[Serial\]|\[k8s.io\].KubeletManagedEtcHosts.should.test.kubelet.managed./etc/hosts.file.\[NodeConformance\].\[Conformance\]|\[k8s.io\].PrivilegedPod.\[NodeConformance\].should.enable.privileged.commands|\[sig-storage\].ConfigMap.should.be.consumable.from.pods.in.volume.as.non-root.\[NodeConformance\].\[Conformance\]|\[sig-storage\].ConfigMap.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].ConfigMap.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.mode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].ConfigMap.should.be.consumable.from.pods.in.volume.with.mappings.as.non-root.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Secrets.should.be.consumable.from.pods.in.volume.as.non-root.with.defaultMode.and.fsGroup.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Secrets.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Secrets.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.Mode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.as.non-root.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.as.non-root.with.defaultMode.and.fsGroup.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.with.defaultMode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.mode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.with.mappings.and.Item.Mode.set.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.be.consumable.from.pods.in.volume.with.mappings.as.non-root.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.set.DefaultMode.on.files.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Projected.should.set.mode.on.item.file.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Downward.API.volume.should.set.DefaultMode.on.files.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Downward.API.volume.should.set.mode.on.item.file.\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(non-root,0644,default\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(non-root,0644,tmpfs\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(non-root,0666,default\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(non-root,0666,tmpfs\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(non-root,0777,default\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(non-root,0777,tmpfs\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(root,0644,default\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(root,0644,tmpfs\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(root,0666,default\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(root,0666,tmpfs\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(root,0777,default\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.should.support.\(root,0777,tmpfs\).\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.volume.on.default.medium.should.have.the.correct.mode.\[NodeConformance\].\[Conformance\]|\[sig-storage\].EmptyDir.volumes.volume.on.tmpfs.should.have.the.correct.mode.\[NodeConformance\].\[Conformance\]|\[sig-storage\].HostPath.should.give.a.volume.the.correct.mode.\[NodeConformance\].\[Conformance\]|\[sig-storage\].Subpath.Atomic.writer.volumes.should.support.subpaths.with.configmap.pod.with.mountPath.of.existing.file.\[Conformance\]|\[sig-storage\].Subpath.Atomic.writer.volumes.should.support.subpaths.with.projected.pod.\[Conformance\]|\[sig-storage\].Subpath.Atomic.writer.volumes.should.support.subpaths.with.secret.pod.\[Conformance\]|\[sig-storage\].Subpath.Atomic.writer.volumes.should.support.subpaths.with.configmap.pod.\[Conformance\]|\[sig-storage\].Subpath.Atomic.writer.volumes.should.support.subpaths.with.downward.pod.\[Conformance\]|\[k8s.io\].Container.Lifecycle.Hook.when.create.a.pod.with.lifecycle.hook.should.execute.poststart.exec.hook.properly.\[NodeConformance\].\[Conformance\]|\[k8s.io\].Container.Lifecycle.Hook.when.create.a.pod.with.lifecycle.hook.should.execute.poststart.http.hook.properly.\[NodeConformance\].\[Conformance\]|\[k8s.io\].Container.Lifecycle.Hook.when.create.a.pod.with.lifecycle.hook.should.execute.prestop.exec.hook.properly.\[NodeConformance\].\[Conformance\]|\[k8s.io\].Container.Lifecycle.Hook.when.create.a.pod.with.lifecycle.hook.should.execute.prestop.http.hook.properly.\[NodeConformance\].\[Conformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.running.a.container.with.a.new.image.should.be.able.to.pull.from.private.registry.with.secret.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.running.a.container.with.a.new.image.should.be.able.to.pull.image.from.docker.hub.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.running.a.container.with.a.new.image.should.be.able.to.pull.image.from.gcr.io.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.running.a.container.with.a.new.image.should.not.be.able.to.pull.from.private.registry.without.secret.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.running.a.container.with.a.new.image.should.not.be.able.to.pull.image.from.invalid.registry.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.running.a.container.with.a.new.image.should.not.be.able.to.pull.non-existing.image.from.gcr.io.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.starting.a.container.that.exits.should.report.termination.message.as.empty.when.pod.succeeds.and.TerminationMessagePolicy.FallbackToLogOnError.is.set.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.starting.a.container.that.exits.should.report.termination.message.from.file.when.pod.succeeds.and.TerminationMessagePolicy.FallbackToLogOnError.is.set.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.starting.a.container.that.exits.should.report.termination.message.from.log.output.if.TerminationMessagePolicy.FallbackToLogOnError.is.set.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.starting.a.container.that.exits.should.report.termination.message.if.TerminationMessagePath.is.set.as.non-root.user.and.at.a.non-default.path.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.starting.a.container.that.exits.should.report.termination.message.if.TerminationMessagePath.is.set.\[NodeConformance\]|\[k8s.io\].Container.Runtime.blackbox.test.when.starting.a.container.that.exits.should.run.with.the.expected.status.\[NodeConformance\]|\[k8s.io\].Security.Context.When.creating.a.container.with.runAsUser.should.run.the.container.with.uid.0.\[NodeConformance\]|\[k8s.io\].Security.Context.When.creating.a.container.with.runAsUser.should.run.the.container.with.uid.65534.\[NodeConformance\]|\[k8s.io\].Security.Context.When.creating.a.pod.with.privileged.should.run.the.container.as.unprivileged.when.false.\[NodeConformance\]|\[k8s.io\].Security.Context.When.creating.a.pod.with.readOnlyRootFilesystem.should.run.the.container.with.readonly.rootfs.when.readOnlyRootFilesystem=true.\[NodeConformance\]|\[k8s.io\].Security.Context.When.creating.a.pod.with.readOnlyRootFilesystem.should.run.the.container.with.writable.rootfs.when.readOnlyRootFilesystem=false.\[NodeConformance\]|\[k8s.io\].Security.Context.when.creating.containers.with.AllowPrivilegeEscalation.should.allow.privilege.escalation.when.not.explicitly.set.and.uid.!=.0.\[NodeConformance\]|\[k8s.io\].Security.Context.when.creating.containers.with.AllowPrivilegeEscalation.should.allow.privilege.escalation.when.true.\[NodeConformance\]|\[k8s.io\].Security.Context.when.creating.containers.with.AllowPrivilegeEscalation.should.not.allow.privilege.escalation.when.false.\[NodeConformance\]"
```

