# Rust Linux / Darwin Builder [![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/joseluisq/rust-linux-darwin-builder/1)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/) [![Build Status](https://travis-ci.com/joseluisq/rust-linux-darwin-builder.svg?branch=master)](https://travis-ci.com/joseluisq/rust-linux-darwin-builder) [![Docker Image Size (tag)](https://img.shields.io/docker/image-size/joseluisq/rust-linux-darwin-builder/1)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/tags) [![Docker Image](https://img.shields.io/docker/pulls/joseluisq/rust-linux-darwin-builder.svg)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/)

> Use same Docker image for compiling [Rust](https://www.rust-lang.org/) programs for Linux ([musl libc](https://doc.rust-lang.org/edition-guide/rust-2018/platform-and-target-support/musl-support-for-fully-static-binaries.html)) & macOS ([osxcross](https://github.com/tpoechtrager/osxcross)).

## Overview

This is a __Linux Docker image__ based on [ekidd/rust-musl-builder](https://hub.docker.com/r/ekidd/rust-musl-builder) but using [debian:buster-slim](https://hub.docker.com/_/debian?tab=tags&page=1&name=buster-slim). It contains essential tools for compile [Rust](https://www.rust-lang.org/) projects such as __Linux__ static binaries via [musl-libc / musl-gcc](https://doc.rust-lang.org/edition-guide/rust-2018/platform-and-target-support/musl-support-for-fully-static-binaries.html) (`x86_64-unknown-linux-musl`) and __macOS__ binaries (`x86_64-apple-darwin`) via [osxcross](https://github.com/tpoechtrager/osxcross) just using the same Linux image.

## Usage

### Compiling an application inside a Docker container

__x86_64-unknown-linux-musl__

```sh
docker run --rm \
    --user rust:rust \
    --volume "${PWD}/sample":/home/rust/sample \
    --workdir /home/rust/sample \
    joseluisq/rust-linux-darwin-builder:1.42.0 \
    sh -c "cargo build --release"
```

__x86_64-apple-darwin__

```sh
docker run --rm \
    --user rust:rust \
    --volume "${PWD}/sample":/home/rust/sample \
    --workdir /home/rust/sample \
    joseluisq/rust-linux-darwin-builder:1.42.0 \
    sh -c "cargo build --release --target x86_64-apple-darwin"
```

### Dockerfile

You can also use the image as a base for your own Dockerfile:

```Dockerfile
FROM joseluisq/rust-linux-darwin-builder:1.42.0
```

### Custom directories

By default this image uses a `rust` user and the default working directory is `/home/rust`.
If you want to use a different directory, change the corresponding owner and group as well.

```sh
sudo chown -R rust:rust /custom/directory
```

#### Cross-compilation example

Below a simple example using a `Makefile` for cross-compiling a Rust app.

Notes:

- A [hello world](./tests/hello-world) app is used.
- A custom directory is used below as working directory (instead of `/home/rust`).
- If you want to use the default `/home/rust` as working directory, owner and group change is not necessary.

Create a Makefile:

```sh
compile:
	@docker run --rm -it \
		-v $(PWD):/drone/src \
		-w /drone/src \
			joseluisq/rust-linux-darwin-builder:1.42.0 \
				make cross-compile
.PHONY: compile

cross-compile:
	@sudo chown -R rust:rust ./
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

Just run the makefile `compile` target, then you will see two release binaries `x86_64-unknown-linux-musl` and `x86_64-apple-darwin`).

```sh
make compile
# 1. Cross compiling example...

# rustc 1.42.0 (b8cedc004 2020-03-09)
# binary: rustc
# commit-hash: b8cedc00407a4c56a3bda1ed605c6fc166655447
# commit-date: 2020-03-09
# host: x86_64-unknown-linux-gnu
# release: 1.42.0
# LLVM version: 9.0

# 2. Compiling application (linux-musl x86_64)...
#     Finished release [optimized] target(s) in 0.01s
# 1.2M	tests/hello-world/target/x86_64-unknown-linux-musl/release/helloworld

# 3. Compiling application (apple-darwin x86_64)...
#     Finished release [optimized] target(s) in 0.01s
# 240K	tests/hello-world/target/x86_64-apple-darwin/release/helloworld
```

## Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.

Feel free to send some [Pull request](https://github.com/joseluisq/rust-linux-darwin-builder/pulls) or [issue](https://github.com/joseluisq/rust-linux-darwin-builder/issues).

## License

This work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

© 2019-present [Jose Quintana](https://git.io/joseluisq)
