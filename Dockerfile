FROM ekidd/rust-musl-builder:1.40.0

LABEL maintainer="Jose Quintana <joseluisq.net>"

USER root

# Install build tools
RUN apt-get update && \
    apt-get install -y \
        clang \
        gcc \
        g++ \
        zlib1g-dev \
        libmpc-dev \
        libmpfr-dev \
        libgmp-dev \
        libxml2-dev \
        nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    chmod g+s /home/rust

USER rust

WORKDIR /home/rust/src

ADD cargo-config.toml /home/rust/.cargo/config

RUN rustup target add x86_64-apple-darwin

# Install osxcross
ENV OSXCROSS_SDK_VERSION 10.11

RUN cd /home/rust && \
    git clone --depth 1 https://github.com/tpoechtrager/osxcross && \
    cd osxcross && \
    curl -L -o ./tarballs/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz \
    https://s3.amazonaws.com/andrew-osx-sdks/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz && \
    env UNATTENDED=yes OSX_VERSION_MIN=10.7 ./build.sh && \
    rm -rf ./tarballs/MacOSX${OSXCROSS_SDK_VERSION}.sdk.tar.xz && \
    rm -rf /tmp/*

ENV PATH $PATH:/home/rust/osxcross/target/bin

CMD /usr/bin/bash

# Metadata
LABEL org.opencontainers.image.vendor="Jose Quintana" \
    org.opencontainers.image.url="https://github.com/joseluisq/rust-linux-musl-darwin-builder" \
    org.opencontainers.image.title="Rust Linux Musl / Darwin Builder" \
    org.opencontainers.image.description="Docker images for compiling Rust binaries for Linux (static binaries via musl-libc / musl-gcc) and macOS (via osxcross)." \
    org.opencontainers.image.version="v0.0.0" \
    org.opencontainers.image.documentation="https://github.com/joseluisq/rust-linux-musl-darwin-builder"
