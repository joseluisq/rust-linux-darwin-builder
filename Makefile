run:
	docker run --rm \
        -v "${PWD}/sample":/home/rust/sample \
        -w /home/rust/sample \
        rust-linux-darwin-builder:latest \
        cargo build --release --target x86_64-unknown-linux-musl && \
        /home/rust/sample/target/x86_64-unknown-linux-musl/release/helloworld
.PHONY: run

build:
	docker build -t rust-linux-darwin-builder:latest -f Dockerfile .
.PHONY: build
