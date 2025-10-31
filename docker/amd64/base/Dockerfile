FROM joseluisq/docker-osxcross:1.0.0-beta.2

LABEL version="${VERSION}" \
    description="Docker image for cross-compiling Rust programs for Linux (musl libc) & macOS (osxcross)." \
    maintainer="Jose Quintana <joseluisq.net>"

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

# Rust stable toolchain
ARG TOOLCHAIN=1.87.0

RUN set -eux \
    && dpkg --add-architecture arm64 \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
        musl-dev \
        musl-dev:arm64 \
        musl-tools \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

# Static linking for C++ code
RUN set -eux \
    && ln -s "/usr/bin/g++" "/usr/bin/musl-g++" \
    # Create appropriate directories for current user
    && mkdir -p /root/libs /root/src \
    && true

ENV PATH=/root/.cargo/bin:/usr/local/musl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

##### Rust toolchains

# Rust/Cargo related environment variables
ENV TARGET=musl

# pkg-config related environment variables
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_ALL_STATIC=1

RUN set -eux \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain=$TOOLCHAIN \
    && rustup target add \
        aarch64-apple-darwin \
        aarch64-unknown-linux-gnu \
        aarch64-unknown-linux-musl \
        x86_64-apple-darwin \
        x86_64-unknown-linux-musl \
        x86_64-unknown-linux-gnu \
    && true

COPY docker/amd64/base/cargo.toml /root/.cargo/config.toml

RUN set -eux \
    && rustc -vV \
    && cargo -vV \
    && true

WORKDIR /root/src

CMD ["bash"]
