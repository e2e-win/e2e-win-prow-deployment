IMG = gcr.io/win-e2e-test/build_acs_engine
TAG = latest

all: build

build: build.sh Dockerfile
	docker build -t $(IMG):$(TAG) .
	@echo Built $(IMG):$(TAG)

test: build
	docker run $(IMG):$(TAG) .

push: build
	docker push $(IMG):$(TAG)
	docker image rm $(IMG):$(TAG)
	@echo Pushed $(IMG):$(TAG) and removed form local


