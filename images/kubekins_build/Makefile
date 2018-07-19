IMG = gcr.io/win-e2e-test/build_kubekins
TAG = latest

all: build

build: 
	docker build -t $(IMG):$(TAG) --build-arg="GO_VERSION=1.10" \
	    --build-arg="BAZEL_VERSION=0.15.0" .
	@echo Built $(IMG):$(TAG)

push: build
	docker push $(IMG):$(TAG)
	docker image rm $(IMG):$(TAG)
	@echo Pushed $(IMG):$(TAG) and removed form local


