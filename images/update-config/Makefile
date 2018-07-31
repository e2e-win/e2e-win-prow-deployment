IMG = gcr.io/win-e2e-test/update-config
TAG = latest

all: build

build:
	docker build -t $(IMG):$(TAG) .
	@echo Built $(IMG):$(TAG)

test: build
	docker run $(IMG):$(TAG) .

push: build
	docker push $(IMG):$(TAG)
	docker image rm $(IMG):$(TAG)
	@echo Pushed $(IMG):$(TAG) and removed form local


