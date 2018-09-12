FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
        ca-certificates \
        curl \
        wget \
        git \
        nano \
        gnupg \
        unzip \
        python \
        python3 \
        software-properties-common


ENV GO_VERSION "1.10"

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ xenial main"|tee /etc/apt/sources.list.d/azure-cli.list
RUN curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN apt-get install -y \
        apt-transport-https
RUN apt-get update && apt-get install -y \
        azure-cli


RUN add-apt-repository --yes ppa:gophers/archive
RUN apt-get update && apt-get install -y \
        golang-$GO_VERSION-go

RUN mkdir $ROOT_HOME/go $ROOT_HOME/go/src $ROOT_HOME/go/bin $ROOT_HOME/go/pkg $ROOT_HOME/required

ENV GOROOT "/usr/lib/go-$GO_VERSION"
ENV GOPATH "$ROOT_HOME/go"
ENV GOBIN "$GOROOT/bin"
ENV PATH "$GOROOT/bin:$PATH:GOPATH/bin"

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

ENV HOME /root

COPY ./build_acs_engine.sh .
ENTRYPOINT ["./build_acs_engine.sh"]
