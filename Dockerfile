# NOTE: Most of Dockerfile and related were borrowed from https://hub.docker.com/r/ekidd/rust-musl-builder

FROM debian:12.11-slim

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

LABEL version="${VERSION}" \
    description="Use same Docker image for compiling Rust programs for Linux (musl libc) & macOS (osxcross)." \
    maintainer="Jose Quintana <joseluisq.net>"

# Make sure we have basic dev tools for building C libraries. Our goal
# here is to support the musl-libc builds and Cargo builds needed for a
# large selection of the most popular crates.
RUN set -eux \
    && dpkg --add-architecture armhf \
    && dpkg --add-architecture arm64 \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        curl \
        file \
        gcc-aarch64-linux-gnu \
        gcc-arm-linux-gnueabihf \
        g++-aarch64-linux-gnu \
        git \
        libbz2-dev \
        libgmp-dev \
        libicu-dev \
        libmpc-dev \
        libmpfr-dev \
        libpq-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        libxml2-dev \
        linux-libc-dev \
        llvm-dev \
        lzma-dev \
        musl-dev \
        musl-dev:armhf \
        musl-dev:arm64 \
        musl-tools \
        patch \
        pkgconf \
        python3 \
        xutils-dev \
        yasm \
        xz-utils \
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

# Set up a `git credentials` helper for using GH_USER and GH_TOKEN to access
# private repositories if desired.
COPY scripts/git-credential-ghtoken /usr/local/bin
RUN set -eux \
    && git config --global credential.https://github.com.helper ghtoken \
    && true

# Build a static library version of OpenSSL using musl-libc. This is needed by
# the popular Rust `hyper` crate.

# OpenSSL 1.1.1 - https://github.com/openssl/openssl/releases
ARG OPENSSL_VERSION=1.1.1w

# We point /usr/local/musl/include/linux at some Linux kernel headers (not
# necessarily the right ones) in an effort to compile OpenSSL 1.1's "engine"
# component. It's possible that this will cause bizarre and terrible things to
# happen. There may be "sanitized" header
RUN set -eux \
    && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
        amd64) config='';; \
        arm64) config='-mno-outline-atomics';; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac \
    && echo "Building OpenSSL ${OPENSSL_VERSION}..." \
    && ls /usr/include/linux \
    && mkdir -p /usr/local/musl/include \
    && ln -s /usr/include/linux /usr/local/musl/include/linux \
    && ln -s "/usr/include/$(uname -m)-linux-gnu/asm" /usr/local/musl/include/asm \
    && ln -s /usr/include/asm-generic /usr/local/musl/include/asm-generic \
    && cd /tmp \
    && ver=$(echo $OPENSSL_VERSION | sed -e 's:\.:_:g') \
    && curl -LO "https://github.com/openssl/openssl/releases/download/OpenSSL_${ver}/openssl-${OPENSSL_VERSION}.tar.gz" \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && env CC=musl-gcc ./Configure no-shared no-zlib -fPIC --prefix=/usr/local/musl -DOPENSSL_NO_SECURE_MEMORY ${config} "linux-$(uname -m)" \
    && env C_INCLUDE_PATH=/usr/local/musl/include/ make depend \
    && env C_INCLUDE_PATH=/usr/local/musl/include/ make -j$(nproc) \
    && make -j$(nproc) install_sw \
    && make -j$(nproc) install_ssldirs \
    && rm /usr/local/musl/include/linux /usr/local/musl/include/asm /usr/local/musl/include/asm-generic \
    && openssl version \
    && rm -r /tmp/* \
    && true


# zlib - http://zlib.net/
ARG ZLIB_VERSION=1.3.1

RUN set -eux \
    && echo "Building zlib ${ZLIB_VERSION}..." \
    && cd /tmp \
    && curl -LO "https://www.zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz" \
    && tar xzf "zlib-${ZLIB_VERSION}.tar.gz" \
    && cd "zlib-${ZLIB_VERSION}" \
    && env CC=musl-gcc ./configure --static --prefix=/usr/local/musl \
    && make -j$(nproc) \
    && make -j$(nproc) install \
    && rm -r /tmp/* \
    && true


# libpq - https://ftp.postgresql.org/pub/source/
ARG POSTGRESQL_VERSION=15.9

RUN set -eux \
    && echo "Building libpq ${POSTGRESQL_VERSION}..." \
    && cd /tmp \
    && curl -LO "https://ftp.postgresql.org/pub/source/v${POSTGRESQL_VERSION}/postgresql-${POSTGRESQL_VERSION}.tar.gz" \
    && tar xzf "postgresql-${POSTGRESQL_VERSION}.tar.gz" \
    && cd "postgresql-${POSTGRESQL_VERSION}" \
    && env CC=musl-gcc CPPFLAGS=-I/usr/local/musl/include LDFLAGS=-L/usr/local/musl/lib ./configure --with-openssl --without-readline --prefix=/usr/local/musl \
    && cd src/interfaces/libpq \
    && make -j$(nproc) all-static-lib \
    && make -j$(nproc) install-lib-static \
    && cd ../../bin/pg_config \
    && make -j$(nproc) \
    && make -j$(nproc) install \
    && rm -r /tmp/* \
    && true

ENV X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=/usr/local/musl/ \
    AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=/usr/local/musl/ \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1 \
    AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1 \
    PQ_LIB_STATIC_X86_64_UNKNOWN_LINUX_MUSL=1 \
    PQ_LIB_STATIC_AARCH64_UNKNOWN_LINUX_MUSL=1 \
    PG_CONFIG_X86_64_UNKNOWN_LINUX_GNU=/usr/bin/pg_config \
    PG_CONFIG_AARCH64_UNKNOWN_LINUX_GNU=/usr/bin/pg_config \
    PKG_CONFIG_ALLOW_CROSS=true \
    PKG_CONFIG_ALL_STATIC=true \
    LIBZ_SYS_STATIC=1 \
    TARGET=musl

# (Please feel free to submit pull requests for musl-libc builds of other C
# libraries needed by the most popular and common Rust crates, to avoid
# everybody needing to build them manually.)


# Mac OS X SDK version - https://github.com/joseluisq/macosx-sdks
ARG OSX_SDK_VERSION=13.3
ARG OSX_SDK_SUM=518e35eae6039b3f64e8025f4525c1c43786cc5cf39459d609852faf091e34be
ARG OSX_VERSION_MIN=10.14

# OS X Cross - https://github.com/tpoechtrager/osxcross
ARG OSX_CROSS_COMMIT=f873f534c6cdb0776e457af8c7513da1e02abe59

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
    && true

RUN set -eux \
    && cd /usr/local/osxcross \
    && echo "Building osxcross with compiler-rt..." \
    # compiler-rt can be needed to build code using `__builtin_available()`
    && env DISABLE_PARALLEL_ARCH_BUILD=1 ./build_compiler_rt.sh \
    && true

ENV PATH=$PATH:/usr/local/osxcross/target/bin
ENV MACOSX_DEPLOYMENT_TARGET=${OSX_VERSION_MIN}
ENV OSXCROSS_MACPORTS_MIRROR=https://packages.macports.org

RUN set -eux \
    && echo "Testing osxcross with compiler-rt..." \
    && echo "int main(void){return 0;}" | xcrun clang -xc -o/dev/null -v - 2>&1 | grep "libclang_rt" 1>/dev/null \
    && echo "compiler-rt installed and working successfully!" \
    && true

RUN set -eux \
    && echo "Install dependencies via osxcross tools..." \
    && apt-get update \
    && /usr/local/osxcross/tools/get_dependencies.sh \
    && true

# Rust stable toolchain
ARG TOOLCHAIN=1.86.0

# Install our Rust toolchain and the `musl` target. We patch the
# command-line we pass to the installer so that it won't attempt to
# interact with the user or fool around with TTYs. We also set the default
# `--target` to musl so that our users don't need to keep overriding it manually.
RUN set -eux \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain=$TOOLCHAIN \
    && rustup target add \
        aarch64-apple-darwin \
        aarch64-unknown-linux-gnu \
        aarch64-unknown-linux-musl \
        armv7-unknown-linux-musleabihf \
        x86_64-apple-darwin \
        x86_64-unknown-linux-musl \
    && true
COPY cargo/config.toml /root/.cargo/config

RUN set -eux \
    && echo "Removing temp files..." \
    && rm -rf *~ taballs *.tar.xz \
    && rm -rf /tmp/* \
    && true

WORKDIR /root/src

CMD ["bash"]

# Metadata
LABEL org.opencontainers.image.vendor="Jose Quintana" \
    org.opencontainers.image.url="https://github.com/joseluisq/rust-linux-darwin-builder" \
    org.opencontainers.image.title="Rust Linux / Darwin Builder" \
    org.opencontainers.image.description="Use same Docker image for compiling Rust programs for Linux (musl libc) & macOS (osxcross)." \
    org.opencontainers.image.version="$VERSION" \
    org.opencontainers.image.documentation="https://github.com/joseluisq/rust-linux-darwin-builder"
