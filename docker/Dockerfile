# NOTE: Most of Dockerfile and related were borrowed from
#       https://hub.docker.com/r/ekidd/rust-musl-builder

FROM debian:buster-slim

LABEL maintainer="Jose Quintana <git.io/joseluisq>"

# The Rust toolchain to use when building our image. Set by `hooks/build`.
ARG TOOLCHAIN=stable


# Dependencies

# OpenSSL v1.1.1
# https://www.openssl.org/source/old/1.1.1/
ARG OPENSSL_VERSION=1.1.1h

# zlib - http://zlib.net/
ARG ZLIB_VERSION=1.2.11

# libpq - https://ftp.postgresql.org/pub/source/
ARG POSTGRESQL_VERSION=13.2

# Mac OS X SDK version
ARG OSX_SDK_VERSION=11.1
ARG OSX_SDK_SUM=97a916b0b68aae9dcd32b7d12422ede3e5f34db8e169fa63bfb18ec410b8f5d9

# OS X Cross
ARG OSX_CROSS_COMMIT=4287300a5c96397a2ee9ab3942e66578a1982031
ARG OSX_VERSION_MIN=10.14

# Make sure we have basic dev tools for building C libraries. Our goal
# here is to support the musl-libc builds and Cargo builds needed for a
# large selection of the most popular crates.
RUN set -eux \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        curl \
        file \
        gcc-arm-linux-gnueabihf \
        git \
        libgmp-dev \
        libmpc-dev \
        libmpfr-dev \
        libpq-dev \
        libsqlite-dev \
        libssl-dev \
        libxml2-dev \
        linux-libc-dev \
        lzma-dev \
        musl-dev \
        musl-tools \
        patch \
        pkgconf \
        python \
        xutils-dev \
        zlib1g-dev \
    # Clean up local repository of retrieved packages and remove the package lists
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

# Static linking for C++ code
RUN set -eux \
    && ln -s "/usr/bin/g++" "/usr/bin/musl-g++" \
    # Create appropriate directories for current user
    && mkdir -p /root/libs /root/src \
    && true

# Set up our path with all our binary directories, including those for the
# musl-gcc toolchain and for our Rust toolchain.
ENV PATH=/root/.cargo/bin:/usr/local/musl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Install our Rust toolchain and the `musl` target. We patch the
# command-line we pass to the installer so that it won't attempt to
# interact with the user or fool around with TTYs. We also set the default
# `--target` to musl so that our users don't need to keep overriding it manually.
RUN set -eux \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain $TOOLCHAIN \
    && rustup target add x86_64-unknown-linux-musl \
    && rustup target add armv7-unknown-linux-musleabihf \
    && rustup target add x86_64-apple-darwin \
    && true
ADD docker/cargo-config.toml /root/.cargo/config

# Set up a `git credentials` helper for using GH_USER and GH_TOKEN to access
# private repositories if desired.
ADD docker/git-credential-ghtoken /usr/local/bin
RUN set -eux \
    && git config --global credential.https://github.com.helper ghtoken \
    && true

# Build a static library version of OpenSSL using musl-libc. This is needed by
# the popular Rust `hyper` crate.
#
# We point /usr/local/musl/include/linux at some Linux kernel headers (not
# necessarily the right ones) in an effort to compile OpenSSL 1.1's "engine"
# component. It's possible that this will cause bizarre and terrible things to
# happen. There may be "sanitized" header
RUN set -eux \
    && echo "Building OpenSSL ${OPENSSL_VERSION}..." \
    && ls /usr/include/linux \
    && mkdir -p /usr/local/musl/include \
    && ln -s /usr/include/linux /usr/local/musl/include/linux \
    && ln -s /usr/include/x86_64-linux-gnu/asm /usr/local/musl/include/asm \
    && ln -s /usr/include/asm-generic /usr/local/musl/include/asm-generic \
    && cd /tmp \
    && curl -LO "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && env CC=musl-gcc ./Configure no-shared no-zlib -fPIC --prefix=/usr/local/musl -DOPENSSL_NO_SECURE_MEMORY linux-x86_64 \
    && env C_INCLUDE_PATH=/usr/local/musl/include/ make depend \
    && env C_INCLUDE_PATH=/usr/local/musl/include/ make \
    && make install \
    && rm /usr/local/musl/include/linux /usr/local/musl/include/asm /usr/local/musl/include/asm-generic \
    && openssl version \
    && rm -r /tmp/* \
    && true

RUN set -eux \
    && echo "Building zlib ${ZLIB_VERSION}..." \
    && cd /tmp \
    && curl -LO "http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz" \
    && tar xzf "zlib-${ZLIB_VERSION}.tar.gz" \
    && cd "zlib-${ZLIB_VERSION}" \
    && env CC=musl-gcc ./configure --static --prefix=/usr/local/musl \
    && make \
    && make install_sw \
    && make install_ssldirs \
    && rm -r /tmp/* \
    && true

RUN set -eux \
    && echo "Building libpq ${POSTGRESQL_VERSION}..." \
    && cd /tmp \
    && curl -LO "https://ftp.postgresql.org/pub/source/v${POSTGRESQL_VERSION}/postgresql-${POSTGRESQL_VERSION}.tar.gz" \
    && tar xzf "postgresql-${POSTGRESQL_VERSION}.tar.gz" \
    && cd "postgresql-${POSTGRESQL_VERSION}" \
    && env CC=musl-gcc CPPFLAGS=-I/usr/local/musl/include LDFLAGS=-L/usr/local/musl/lib ./configure --with-openssl --without-readline --prefix=/usr/local/musl \
    && cd src/interfaces/libpq \
    && make all-static-lib \
    && make install-lib-static \
    && cd ../../bin/pg_config \
    && make \
    && make install \
    && rm -r /tmp/* \
    && true

ENV X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=/usr/local/musl/ \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1 \
    PQ_LIB_STATIC_X86_64_UNKNOWN_LINUX_MUSL=1 \
    PG_CONFIG_X86_64_UNKNOWN_LINUX_GNU=/usr/bin/pg_config \
    PKG_CONFIG_ALLOW_CROSS=true \
    PKG_CONFIG_ALL_STATIC=true \
    LIBZ_SYS_STATIC=1 \
    TARGET=musl

# (Please feel free to submit pull requests for musl-libc builds of other C
# libraries needed by the most popular and common Rust crates, to avoid
# everybody needing to build them manually.)


# Install OS X Cross
# A Mac OS X cross toolchain for Linux, FreeBSD, OpenBSD and Android

RUN set -eux \
    && echo "Cloning osxcross..." \
    && git clone https://github.com/tpoechtrager/osxcross.git /usr/local/osxcross \
    && cd /usr/local/osxcross \
    && git checkout -q "${OSX_CROSS_COMMIT}" \
    && rm -rf ./.git \
    && true

RUN set -eux \
    && echo "Building osxcross with ${OSX_SDK_VERSION}..." \
    && cd /usr/local/osxcross \
    && curl -Lo "./tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" \
        "https://github.com/joseluisq/macosx-sdks/releases/download/${OSX_SDK_VERSION}/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" \
    && echo "${OSX_SDK_SUM}  ./tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" \
        | sha256sum -c - \
    && env UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh \
    && rm -rf *~ taballs *.tar.xz \
    && rm -rf /tmp/* \
    && true

ENV PATH $PATH:/usr/local/osxcross/target/bin

WORKDIR /root/src

CMD ["bash"]

# Metadata
LABEL org.opencontainers.image.vendor="Jose Quintana" \
    org.opencontainers.image.url="https://github.com/joseluisq/rust-linux-darwin-builder" \
    org.opencontainers.image.title="Rust Linux / Darwin Builder" \
    org.opencontainers.image.description="Use same Docker image for compiling Rust programs for Linux (musl libc) & macOS (osxcross)." \
    org.opencontainers.image.version="v1.50.0" \
    org.opencontainers.image.documentation="https://github.com/joseluisq/rust-linux-darwin-builder"
