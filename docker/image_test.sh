#!/bin/bash

# Make bash fail much more aggressively on errors.
set -euo pipefail

# Make sure we can build our main container.
docker build -t joseluisq/rust-linux-darwin-builder -f docker/Dockerfile .

# Make sure we can build our example derived container.
docker build -t rust-musl-zlib examples/adding-a-library

# Make sure we can build a multi-stage container.
docker build -t rust-linux-darwin-builder-diesel examples/using-diesel
docker run --rm rust-linux-darwin-builder-diesel

echo "==== Verifying static linking"

# Make sure we can build a static executable.
docker run --rm joseluisq/rust-linux-darwin-builder bash -c "
set -euo pipefail
export USER=rust
cargo new --vcs none --bin testme
cd testme

echo -e '--- Test case for x86_64:'
cargo build
echo 'ldd says:'
if ldd target/x86_64-unknown-linux-musl/debug/testme; then
  echo '[FAIL] Executable is not static!' 1>&2
  exit 1
fi
echo -e '[PASS] x86_64 binary is statically linked.\n'

echo -e '--- Test case for ARMhf:'
cargo build --target=armv7-unknown-linux-musleabihf
echo 'ldd says:'
if ldd target/armv7-unknown-linux-musleabihf/debug/testme; then
  echo '[FAIL] Executable is not static!' 1>&2
  exit 1
fi
echo -e '[PASS] ARMhf binary is statically linked.\n'
"

# Make sure we can build a static executable using `git2`.
docker build -t rust-linux-darwin-builder-with-git2 examples/linking-with-git2
docker run --rm rust-linux-darwin-builder-with-git2 bash -c "
set -euo pipefail
cd /home/rust/src

echo -e '--- Test case for libgit2:'
echo 'ldd says:'
if ldd target/x86_64-unknown-linux-musl/debug/linking-with-git2; then
  echo '[FAIL] Executable is not static!' 1>&2
  exit 1
fi
echo -e '[PASS] libgit2 binary is statically linked.\n'
"

# We're good.
echo 'OK. ALL TESTS PASSED.' 1>&2
