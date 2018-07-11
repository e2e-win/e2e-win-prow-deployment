FROM gcr.io/win-e2e-test/bootstrap:latest
# Using latest bootstrap image since it already has all the necessary bits for
# using docker in docker inside of prow

LABEL maintainer="Adelina Tuvenie <atuvenie@cloudbasesolutions.com>"

# install go
ARG GO_VERSION
ENV GO_TARBALL "go${GO_VERSION}.linux-amd64.tar.gz"
RUN wget -q "https://storage.googleapis.com/golang/${GO_TARBALL}" && \
    tar xzf "${GO_TARBALL}" -C /usr/local && \
    rm "${GO_TARBALL}"

# install bazel
ARG BAZEL_VERSION
RUN INSTALLER="bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"; \
    wget -q "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${INSTALLER}" && \
    chmod +x "${INSTALLER}" && "./${INSTALLER}" && rm "${INSTALLER}"

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace

ADD ["build_kubekins_e2e.sh","/workspace/"]

ENTRYPOINT ["/workspace/build_kubekins_e2e.sh"]
