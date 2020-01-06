linux:
	@docker run --rm \
				--name rust_builder_linux \
				--user rust:rust \
				--volume "${PWD}/sample":/home/rust/sample \
				--workdir /home/rust/sample \
				joseluisq/rust-linux-darwin-builder:1.40.0 \
				sh -c "cargo build --release"
.PHONY: linux

darwin:
	@docker run --rm \
				--name rust_builder_darwin \
				--user rust:rust \
				--volume "${PWD}/sample":/home/rust/sample \
				--workdir /home/rust/sample \
				joseluisq/rust-linux-darwin-builder:1.40.0 \
				sh -c "cargo build --release --target x86_64-apple-darwin"
.PHONY: darwin
