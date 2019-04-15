FROM ubuntu:xenial

WORKDIR /root

RUN apt-get update
RUN apt-get -y install curl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/darwin/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

ADD ["update-config.sh", "/root"]
ENTRYPOINT ["update-config.sh"]
