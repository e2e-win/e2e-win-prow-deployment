FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
	ca-certificates \
	curl \
	git \
	nano \
	gnupg \
	software-properties-common

ENV HOME "/root"

# install azure cli
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main"|tee /etc/apt/sources.list.d/azure-cli.list 
RUN curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 
RUN apt-get install apt-transport-https
RUN apt-get update && apt-get install -y azure-cli

# install golang
ENV GO_VERSION "1.10"
RUN add-apt-repository --yes ppa:gophers/archive
RUN apt-get update && apt-get install -y golang-$GO_VERSION-go


RUN mkdir $HOME/go $HOME/go/src $HOME/go/bin $HOME/go/pkg $HOME/required

ENV GOROOT "/usr/lib/go-$GO_VERSION"
ENV GOPATH "$HOME/go"
ENV GOBIN "$GOROOT/bin"
ENV PATH "$GOROOT/bin:$PATH:GOPATH/bin"

WORKDIR /root
COPY build.sh .
ENTRYPOINT ["./build.sh"]
