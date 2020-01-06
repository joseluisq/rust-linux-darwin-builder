# Rust Linux / Darwin Builder [![Docker Image](https://img.shields.io/docker/pulls/joseluisq/rust-linux-darwin-builder.svg)](https://hub.docker.com/r/joseluisq/rust-linux-darwin-builder/)

> Use same Docker image for compiling [Rust](https://www.rust-lang.org/) programs for Linux ([musl libc](https://doc.rust-lang.org/edition-guide/rust-2018/platform-and-target-support/musl-support-for-fully-static-binaries.html)) & macOS ([osxcross](https://github.com/tpoechtrager/osxcross)).

## Overview

This is a __Linux Docker image__ that extends from [ekidd/rust-musl-builder](https://hub.docker.com/r/ekidd/rust-musl-builder) containing all necessary tools for compile [Rust](https://www.rust-lang.org/) projects such as __Linux__ static binaries via [musl-libc / musl-gcc](https://doc.rust-lang.org/edition-guide/rust-2018/platform-and-target-support/musl-support-for-fully-static-binaries.html) (`x86_64-unknown-linux-musl`) and __macOS__ binaries (`x86_64-apple-darwin`) via [osxcross](https://github.com/tpoechtrager/osxcross) just using the same Linux image.

## Usage

### Compiling an application inside a Docker container

__x86_64-unknown-linux-musl__

```sh
docker run --rm \
    --user rust:rust \
    --volume "${PWD}/sample":/home/rust/sample \
    --workdir /home/rust/sample \
    joseluisq/rust-linux-darwin-builder:1.40.0 \
    sh -c "cargo build --release"
```

__x86_64-apple-darwin__

```sh
docker run --rm \
    --user rust:rust \
    --volume "${PWD}/sample":/home/rust/sample \
    --workdir /home/rust/sample \
    joseluisq/rust-linux-darwin-builder:1.40.0 \
    sh -c "cargo build --release --target x86_64-apple-darwin"
```

*__Note:__ This example is also available under [./sample](./sample) directory.*

### Dockerfile

You can also use the image as a base for your own Dockerfile:

```Dockerfile
FROM joseluisq/rust-linux-darwin-builder:1.40.0
```

## Contributions

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in current work by you, as defined in the Apache-2.0 license, shall be dual licensed as described below, without any additional terms or conditions.

Feel free to send some [Pull request](https://github.com/joseluisq/rust-linux-darwin-builder/pulls) or [issue](https://github.com/joseluisq/rust-linux-darwin-builder/issues).

## License

This work is primarily distributed under the terms of both the [MIT license](LICENSE-MIT) and the [Apache License (Version 2.0)](LICENSE-APACHE).

© 2019 [Jose Quintana](https://git.io/joseluisq)
