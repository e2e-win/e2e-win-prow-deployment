FROM gcr.io/win-e2e-test/build_kubetest
# Using latest build_kubetest image since it already has all the necessary bits

LABEL maintainer="Adelina Tuvenie <atuvenie@cloudbasesolutions.com>"

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace

ADD ["build_acs.sh","/workspace/"]

ENTRYPOINT ["/workspace/build_acs.sh"]
