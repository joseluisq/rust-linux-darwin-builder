build:
	docker build \
		-t joseluisq/rust-linux-darwin-builder:latest \
		-f docker/Dockerfile .
.PHONY: build

test:
	@docker run --rm -it \
		-v $(PWD):/drone/src \
		-w /drone/src \
			joseluisq/rust-linux-darwin-builder:latest \
				make test-ci
.PHONY: test

test-ci:
	@echo "Testing cross-compiling application..."
	@rustc -vV
	@echo
	@cd tests/hello-world \
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& cargo build --release --target x86_64-unknown-linux-musl \
		&& du -sh target/x86_64-unknown-linux-musl/release/helloworld \
		&& ./target/x86_64-unknown-linux-musl/release/helloworld \
		&& echo \
		&& echo "Compiling application (apple-darwin x86_64)..." \
		&& cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/helloworld
.ONESHELL: test-ci

promote:
	@drone build promote joseluisq/rust-linux-darwin-builder $(BUILD) $(ENV)
.PHONY: promote
