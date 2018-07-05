FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
	ca-certificates \
	curl \
	git \
	nano \
	gnupg \
	software-properties-common \
	wget

ENV HOME "/root"

# install azure cli
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main"|tee /etc/apt/sources.list.d/azure-cli.list 
RUN curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 
RUN apt-get install apt-transport-https
RUN apt-get update && apt-get install -y azure-cli

# install golang
ENV GO_VERSION "1.10.2"
ENV GO_DOWNLOAD_URL=https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz

RUN mkdir $HOME/go $HOME/go/src $HOME/go/bin $HOME/go/pkg $HOME/required

ENV GOROOT "/usr/lib/go"
ENV GOPATH "$HOME/go"
ENV GOBIN "$GOROOT/bin"
ENV PATH "$GOROOT/bin:$PATH:GOPATH/bin"

RUN apt-get update --fix-missing && apt upgrade -y
RUN apt-get install --no-install-recommends -y gcc

WORKDIR /tmp
RUN wget "$GO_DOWNLOAD_URL" -O golang.tar.gz
RUN tar -zxvf golang.tar.gz
RUN mv go $GOROOT
WORKDIR $HOME

RUN go version

# Install gcloud
RUN apt-get update && apt-get install -y \
        tar

ENV PATH=/google-cloud-sdk/bin:$HOME:${PATH} \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1
RUN wget -q https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.tar.gz && \
    tar xzf google-cloud-sdk.tar.gz -C / && \
    rm google-cloud-sdk.tar.gz && \
    /google-cloud-sdk/install.sh \
        --disable-installation-options \
        --bash-completion=false \
        --path-update=false \
        --usage-reporting=false && \
    gcloud components install alpha beta kubectl && \
    gcloud info | tee $HOME/gcloud-info.txt


# install bazel
RUN apt-get update && apt-get install -y \
	pkg-config \
	zip \
	g++ \
	zlib1g-dev \
	unzip \
	python

WORKDIR /root
COPY build.sh .
ENTRYPOINT ["./build.sh"]
