ARG BASE=debian:trixie-slim

# Build stage
FROM ${BASE} AS builder

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /build
COPY . /build

RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    build-essential \
    yasm \
    autoconf \
    automake \
    libtool \
    pkgconf \
    libzmq3-dev \
  && rm -rf /var/lib/apt/lists/*

# Disable cpu based optimisations for more portable builds.
RUN sed -i "s/host_cpu = 'x86_64'/host_cpu = 'x86_64-disabled'/" configure.ac \
  && sed -i "s/host_cpu = 'aarch64'/host_cpu = 'aarch64-disabled'/" configure.ac

RUN ./autogen.sh \
  && ./configure \
  && make -j"$(nproc)"

# Final image
FROM ${BASE}

ARG DEBIAN_FRONTEND=noninteractive

# Install zmq runtime dep
RUN apt-get update \
  && apt-get install --yes --no-install-recommends libzmq3-dev \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/src/ckpool /bin/ckpool

EXPOSE 3333

ENTRYPOINT ["ckpool"]

