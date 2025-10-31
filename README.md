<div>
  <div align="center">
    <img src="https://www.rust-lang.org/logos/rust-logo-blk.svg" height="130" width="130" />
  </div>

  <h1 align="center">Rust Linux / Darwin Builder</h1>

  <h4 align="center">
    Use the same Docker image to cross-compile Rust programs for Linux (musl libc) and macOS (osxcross)
  </h4>

<div align="center">

  [![Build Status](https://api.cirrus-ci.com/github/joseluisq/rust-linux-darwin-builder.svg)](https://cirrus-ci.com/github/joseluisq/rust-linux-darwin-builder) [![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/joseluisq/rust-linux-darwin-builder/1)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/) [![Docker Image Size (tag)](https://img.shields.io/docker/image-size/joseluisq/rust-linux-darwin-builder/1)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/tags) [![Docker Image](https://img.shields.io/docker/pulls/joseluisq/rust-linux-darwin-builder.svg)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/)

</div>

</div>

## Overview

This is a __Linux [multi-arch](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/) Docker image__ based on the latest __Debian [13-slim](https://hub.docker.com/_/debian/tags?page=1&name=13-slim)__ ([Trixie](https://www.debian.org/News/2025/20250809)).

It contains essential tools for cross-compiling [Rust](https://www.rust-lang.org/) projects such as __Linux__ static binaries via [musl-libc / musl-gcc](https://doc.rust-lang.org/edition-guide/rust-2018/platform-and-target-support/musl-support-for-fully-static-binaries.html) (`x86_64-unknown-linux-musl`) and __macOS__ binaries (`x86_64-apple-darwin`) via [osxcross](https://github.com/tpoechtrager/osxcross) just using the same Linux image.

Additionally, Rust programs can cross-compile for different targets, either from the `linux/arm64` or the `linux/amd64` Docker image variant, so users can take advantage of them in native environments.

## Supported targets

__linux/amd64__

- `x86_64-apple-darwin`
- `x86_64-unknown-linux-musl`
- `x86_64-unknown-linux-gnu`

__linux/arm64__

- `aarch64-apple-darwin`
- `aarch64-unknown-linux-gnu`
- `aarch64-unknown-linux-musl`

## Usage

### Compiling an application inside a Docker container

By default, the working directory is `/root/src`.

### x86_64 (amd64)

Below are the default toolchains included in the Docker image.

#### x86_64-unknown-linux-musl

```sh
docker run --rm \
    --volume "${PWD}/sample":/root/src \
    --workdir /root/src \
      joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
        sh -c "cargo build --release --target x86_64-unknown-linux-musl"
```

#### x86_64-unknown-linux-gnu

```sh
docker run --rm \
    --volume "${PWD}/sample":/root/src \
    --workdir /root/src \
      joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
        sh -c "cargo build --release --target x86_64-unknown-linux-gnu"
```

#### x86_64-apple-darwin

```sh
docker run --rm \
    --volume "${PWD}/sample":/root/src \
    --workdir /root/src \
      joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
        sh -c "cargo build --release --target x86_64-apple-darwin"
```

### aarch64 (arm64)

#### aarch64-unknown-linux-gnu

```sh
docker run --rm \
    --volume "${PWD}/sample":/root/src \
    --workdir /root/src \
      joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
        sh -c "cargo build --release --target aarch64-unknown-linux-gnu"
```

#### aarch64-unknown-linux-musl

```sh
docker run --rm \
    --volume "${PWD}/sample":/root/src \
    --workdir /root/src \
      joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
        sh -c "cargo build --release --target aarch64-unknown-linux-musl"
```

#### aarch64-apple-darwin

```sh
docker run --rm \
    --volume "${PWD}/sample":/root/src \
    --workdir /root/src \
      joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
      # or \
      # joseluisq/rust-linux-darwin-builder:2.0.0-beta.1-libs \
        sh -c "cargo build --release --target aarch64-apple-darwin"
```

### Docker Images

You can also use the image as a base for your `Dockerfile`:

#### Rust toolchains (default image)

```Dockerfile
FROM joseluisq/rust-linux-darwin-builder:2.0.0-beta.1
# or
FROM ghcr.io/joseluisq/rust-linux-darwin-builder:2.0.0-beta.1
```

#### Rust toolchains with extra C libraries (optional image)

If you need extra C libraries for your Rust project (e.g., OpenSSL or Zlib), you can use the `-libs` variant.

Built-in C libraries:

- **ZLib** `1.3.1`
- **OpenSSL** `3.5.4`
- **libpq** `15.6` (in progress)

```Dockerfile
FROM joseluisq/rust-linux-darwin-builder:2.0.0-beta.1-libs
# or
FROM ghcr.io/joseluisq/rust-linux-darwin-builder:2.0.0-beta.1-libs
```

### Cross-compilation example

Below is a simple example of using a `Makefile` to cross-compile a Rust app.

Notes:

- A [hello world](./tests/hello-world) app is used.
- A custom directory is used below as a working directory instead of `/root/src`.

Create a Makefile:

```sh
compile:
	@docker run --rm -it \
		-v $(PWD):/app/src \
		-w /app/src \
			joseluisq/rust-linux-darwin-builder:2.0.0-beta.1 \
				make cross-compile
.PHONY: compile

cross-compile:
	@echo
	@echo "1. Cross compiling example..."
	@rustc -vV
	@echo
	@echo "2. Compiling application (linux-musl x86_64)..."
	@cargo build --manifest-path=tests/hello-world/Cargo.toml --release --target x86_64-unknown-linux-musl
	@du -sh tests/hello-world/target/x86_64-unknown-linux-musl/release/helloworld
	@echo
	@echo "3. Compiling application (apple-darwin x86_64)..."
	@cargo build --manifest-path=tests/hello-world/Cargo.toml --release --target x86_64-apple-darwin
	@du -sh tests/hello-world/target/x86_64-apple-darwin/release/helloworld
.PHONY: cross-compile
```

Just run the makefile `compile` target, then you will see two release binaries `x86_64-unknown-linux-musl` and `x86_64-apple-darwin`.

```sh
# make compile
# rustc 1.87.0 (17067e9ac 2025-05-09)
# binary: rustc
# commit-hash: 17067e9ac6d7ecb70e50f92c1944e545188d2359
# commit-date: 2025-05-09
# host: x86_64-unknown-linux-gnu
# release: 1.87.0
# LLVM version: 20.1.1

# 2. Compiling application (linux-musl x86_64)...
#     Finished release [optimized] target(s) in 0.01s
# 1.2M	tests/hello-world/target/x86_64-unknown-linux-musl/release/helloworld

# 3. Compiling application (apple-darwin x86_64)...
#     Finished release [optimized] target(s) in 0.01s
# 240K	tests/hello-world/target/x86_64-apple-darwin/release/helloworld
```

For more examples, take a look at our test suite in [Makefile](./Makefile) and [tests/](./tests/) folder.

### Building *-sys crates

If some of your crates require C bindings and you run into a compilation or linking error, try to use Clang for C/C++ builds.

For example to cross-compile to Macos:

```sh
# Note the environment variables CC and CXX
CC=o64-clang \
CXX=o64-clang++ \
	cargo build --target x86_64-apple-darwin
  # Or
	cargo build --target aarch64-apple-darwin
```

### Cargo Home advice

It's known that the [`CARGO_HOME`](https://doc.rust-lang.org/cargo/guide/cargo-home.html#cargo-home) points to `$HOME/.cargo` by default (`/root/.cargo` in this case). However, if you want to use a custom Cargo home directory then make sure to copy the Cargo `config.toml` file to the particular directory like `cp "$HOME/.cargo/config.toml" "$CARGO_HOME/"` before to cross-compile your program. Otherwise, you could face a linking error when for example you want to cross-compile to an `x86_64-apple-darwin` target.

For more details take a look at [Cross-compiling Rust from Linux to macOS](https://wapl.es/rust/2019/02/17/rust-cross-compile-linux-to-macos.html) by James Waples.

### OSXCross

You can also use o32-clang(++) and o64-clang(++) as a normal compiler.

__Notes:__

- The current *11.3 SDK* does not support i386 anymore. Use <= 10.13 SDK if you rely on i386 support.
- The current *11.3 SDK* does not support libstdc++ anymore. Use <= 10.13 SDK if you rely on libstdc++ support.

Examples:

```sh
Example usage:

Example 1: CC=o32-clang ./configure --host=i386-apple-darwin22.4
Example 2: CC=i386-apple-darwin22.4-clang ./configure --host=i386-apple-darwin22.4
Example 3: o64-clang -Wall test.c -o test
Example 4: x86_64-apple-darwin22.4-strip -x test

!!! Use aarch64-apple-darwin22.4-* instead of arm64-* when dealing with Automake !!!
!!! CC=aarch64-apple-darwin22.4-clang ./configure --host=aarch64-apple-darwin22.4 !!!
!!! CC="aarch64-apple-darwin22.4-clang -arch arm64e" ./configure --host=aarch64-apple-darwin22.4 !!!
```

## Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.

Feel free to send some [Pull request](https://github.com/joseluisq/rust-linux-darwin-builder/pulls) or file an [issue](https://github.com/joseluisq/rust-linux-darwin-builder/issues).

## License

This work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

© 2019-present [Jose Quintana](https://github.com/joseluisq)
