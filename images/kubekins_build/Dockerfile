FROM gcr.io/win-e2e-test/bootstrap:latest
# Using latest bootstrap image since it already has all the necessary bits for
# using docker in docker inside of prow

LABEL maintainer="Adelina Tuvenie <atuvenie@cloudbasesolutions.com>"

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace

ADD ["build_kubekins_e2e.sh","/workspace/"]

ENTRYPOINT ["/workspace/build_kubekins_e2e.sh"]


