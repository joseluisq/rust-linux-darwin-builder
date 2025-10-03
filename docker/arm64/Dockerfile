FROM joseluisq/docker-osxcross:1.0.0-beta.2

ARG VERSION=0.0.0
ENV VERSION=${VERSION}

LABEL version="${VERSION}" \
    description="Use same Docker image for compiling Rust programs for Linux (musl libc) & macOS (osxcross)." \
    maintainer="Jose Quintana <joseluisq.net>"

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
# Crate-related environment variables
ENV LIBZ_SYS_STATIC=1

# Rust stable toolchain
ARG TOOLCHAIN=1.87.0

RUN set -eux \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain=$TOOLCHAIN \
    && rustup target add \
        aarch64-apple-darwin \
        aarch64-unknown-linux-gnu \
        aarch64-unknown-linux-musl \
        x86_64-apple-darwin \
        x86_64-unknown-linux-musl \
    && true

COPY cargo/config.toml /root/.cargo/config.toml

RUN set -eux \
    && rustc -vV \
    && cargo -vV \
    && true

##### Libraries

# pkg-config related environment variables
ENV PKG_CONFIG_ALLOW_CROSS=true
ENV PKG_CONFIG_ALL_STATIC=true

RUN set -eux \
    && dpkg --add-architecture amd64 \
    && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends --no-install-suggests \
        musl-dev \
        musl-dev:amd64 \
        musl-tools \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && true

# zlib - http://zlib.net/
ARG ZLIB_VERSION=1.3.1

WORKDIR /tmp

RUN set -eux \
    && echo "Downloading zlib ${ZLIB_VERSION}..." \
    && curl -Lo zlib.tar.gz "https://www.zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz" \
    && true
    
# x86_64 glibc
RUN set -eux \
    && mkdir zlib \
    && tar -xvf zlib.tar.gz --strip-components=1 -C ./zlib \
    && cd zlib \
    && make distclean \
    && CC=gcc ./configure --prefix=/usr/local/x86_64-linux-gnu \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf zlib \
    && true

# arm64 glibc
RUN set -eux \
    && mkdir zlib \
    && tar -xvf zlib.tar.gz --strip-components=1 -C ./zlib \
    && cd zlib \
    && make distclean \
    && CC=aarch64-linux-gnu-gcc ./configure --prefix=/usr/local/aarch64-linux-gnu \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf zlib \
    && true

# x86_64 musl
RUN set -eux \
    && mkdir zlib \
    && tar -xvf zlib.tar.gz --strip-components=1 -C ./zlib \
    && cd zlib \
    && make distclean \
    && CC=musl-gcc ./configure --static --prefix=/usr/local/x86_64-linux-musl \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf zlib zlib.tar.gz \
    && true

WORKDIR /tmp

# OpenSSL v3 - https://github.com/openssl/openssl/releases
ARG OPENSSL_VERSION=3.5.4

RUN set -eux \
    && curl -LO "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" \
    && true

RUN set -eux \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && echo "Building OpenSSL ${OPENSSL_VERSION} for x86_64..." \
    && ls /usr/include/linux \
    && mkdir -p /usr/local/x86_64-linux-musl/include \
    && ln -s /usr/include/linux /usr/local/x86_64-linux-musl/include/linux \
    && ln -s "/usr/include/x86_64-linux-gnu/asm" /usr/local/x86_64-linux-musl/include/asm \
    && ln -s /usr/include/asm-generic /usr/local/x86_64-linux-musl/include/asm-generic \
    && env CC=musl-gcc ./Configure no-shared no-zlib \
        -fPIC --prefix=/usr/local/x86_64-linux-musl \
        -DOPENSSL_NO_SECURE_MEMORY "linux-x86_64" \
    && env C_INCLUDE_PATH=/usr/local/x86_64-linux-musl/include/ make depend \
    && env C_INCLUDE_PATH=/usr/local/x86_64-linux-musl/include/ make -j$(nproc) \
    && make -j$(nproc) install_sw \
    && make -j$(nproc) install_ssldirs \
    && openssl version \
    && rm -rf \
        /usr/local/x86_64-linux-musl/include/linux \
        /usr/local/x86_64-linux-musl/include/asm \
        /usr/local/x86_64-linux-musl/include/asm-generic \
    && ls -l /usr/local/x86_64-linux-musl \
    && if ! [ -d /usr/local/x86_64-linux-musl/lib ]; then \
            ln -s /usr/local/x86_64-linux-musl/lib64 /usr/local/x86_64-linux-musl/lib; \
        else \
            mv /usr/local/x86_64-linux-musl/lib /usr/local/x86_64-linux-musl/abc; \
            mv /usr/local/x86_64-linux-musl/lib64 /usr/local/x86_64-linux-musl/lib; \
            cp -rp /usr/local/x86_64-linux-musl/abc/. /usr/local/x86_64-linux-musl/lib/; \
            unlink /usr/local/x86_64-linux-musl/lib/lib64; \
            rm -rf /usr/local/x86_64-linux-musl/abc; \
        fi \
    && cd .. \
    && rm -rf "openssl-${OPENSSL_VERSION}" \
    && true

RUN set -eux \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && echo "Building OpenSSL ${OPENSSL_VERSION} for aarch64..." \
    && ls /usr/include/linux \
    && mkdir -p /usr/local/aarch64-linux-gnu/include \
    && env CC=aarch64-linux-gnu-gcc ./Configure no-shared no-zlib \
        -fPIC --prefix=/usr/local/aarch64-linux-gnu \
        -DOPENSSL_NO_SECURE_MEMORY -mno-outline-atomics "linux-aarch64" \
    && env C_INCLUDE_PATH=/usr/local/aarch64-linux-gnu/include/ make depend \
    && env C_INCLUDE_PATH=/usr/local/aarch64-linux-gnu/include/ make -j$(nproc) \
    && make -j$(nproc) install_sw \
    && make -j$(nproc) install_ssldirs \
    && openssl version \
    && rm -rf \
        /usr/local/aarch64-linux-gnu/include/linux \
        /usr/local/aarch64-linux-gnu/include/asm \
        /usr/local/aarch64-linux-gnu/include/asm-generic \
    && ls -l /usr/local/aarch64-linux-gnu \
    && cd .. \
    && rm -rf "openssl-${OPENSSL_VERSION}" \
    && true

RUN set -eux \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && echo "Building OpenSSL ${OPENSSL_VERSION} for MACOS aarch64..." \
    && mkdir -p /usr/local/aarch64-apple-darwin/include \
    && env CC=oa64-clang \
        ./Configure no-asm no-shared no-zlib no-tests no-fuzz-libfuzzer no-fuzz-afl \
        -fPIC --prefix=/usr/local/aarch64-apple-darwin \
        -DOPENSSL_NO_SECURE_MEMORY "darwin64-arm64-cc" \
    && make -j$(nproc) build_libs \
    && make -j$(nproc) install_dev \
    && rm -rf \
        /usr/local/aarch64-apple-darwin/include/asm \
        /usr/local/aarch64-apple-darwin/include/asm-generic \
    && ls -l /usr/local/aarch64-apple-darwin \
    && cd .. \
    && rm -rf "openssl-${OPENSSL_VERSION}" \
    && true

RUN set -eux \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && echo "Building OpenSSL ${OPENSSL_VERSION} for MACOS x86_64..." \
    && mkdir -p /usr/local/x86_64-apple-darwin/include \
    && env CC=o64-clang \
        ./Configure no-asm no-shared no-zlib no-tests no-fuzz-libfuzzer no-fuzz-afl \
        -fPIC --prefix=/usr/local/x86_64-apple-darwin \
        -DOPENSSL_NO_SECURE_MEMORY "darwin64-x86_64-cc" \
    && make -j$(nproc) build_libs \
    && make -j$(nproc) install_dev \
    && rm -rf \
        /usr/local/x86_64-apple-darwin/include/asm \
        /usr/local/x86_64-apple-darwin/include/asm-generic \
    && ls -l /usr/local/x86_64-apple-darwin \
    && cd .. \
    && rm -rf "openssl-${OPENSSL_VERSION}" \
    && true

RUN set -eux \
    && tar xvzf "openssl-${OPENSSL_VERSION}.tar.gz" \
    && cd "openssl-${OPENSSL_VERSION}" \
    && echo "Building OpenSSL ${OPENSSL_VERSION} for aarch64 musl..." \
    && mkdir -p /usr/local/aarch64-linux-musl/include \
    && env CC=aarch64-linux-musl-gcc \
        ./Configure no-asm no-engine no-shared no-zlib no-tests no-fuzz-libfuzzer no-fuzz-afl \
        -fPIC --prefix=/usr/local/aarch64-linux-musl \
        -DOPENSSL_NO_SECURE_MEMORY -mno-outline-atomics "linux-aarch64" \
    && env C_INCLUDE_PATH=/usr/local/aarch64-linux-musl/include/ make depend \
    && env C_INCLUDE_PATH=/usr/local/aarch64-linux-musl/include/ make -j$(nproc) \
    && make -j$(nproc) install_sw \
    && make -j$(nproc) install_ssldirs \
    && rm -rf \
        /usr/local/aarch64-linux-musl/include/asm \
        /usr/local/aarch64-linux-musl/include/asm-generic \
    && ls -l /usr/local/aarch64-linux-musl \
    && cd .. \
    && rm -rf "openssl-${OPENSSL_VERSION}" \
    && true

RUN set -eux \
    && echo "Testing musl-gcc with OpenSSL..." \
    && openssl version \
    && echo "int main(){return 0;}" | \
        musl-gcc -o test -x c - \
            -I/usr/local/x86_64-linux-musl/include \
            -L/usr/local/x86_64-linux-musl/lib \
            -lssl -lcrypto \
    && true

RUN set -eux \
    && echo "Removing temp files..." \
    && rm -rf *~ taballs *.tar.xz \
    && rm -rf /tmp/* \
    && true

WORKDIR /root

# OpenSSL related environment variables
ENV X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1
ENV X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=/usr/local/x86_64-linux-musl
ENV X86_64_UNKNOWN_LINUX_GNU_OPENSSL_DIR=/usr/local/x86_64-linux-musl
ENV X86_64_APPLE_DARWIN_OPENSSL_DIR=/usr/local/x86_64-apple-darwin

ENV AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1
ENV AARCH64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR=/usr/local/aarch64-linux-musl
ENV AARCH64_UNKNOWN_LINUX_GNU_OPENSSL_DIR=/usr/local/aarch64-linux-gnu
ENV AARCH64_APPLE_DARWIN_OPENSSL_DIR=/usr/local/aarch64-apple-darwin

WORKDIR /root/src

CMD ["bash"]
