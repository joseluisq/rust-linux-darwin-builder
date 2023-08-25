REPOSITORY ?= joseluisq
TAG ?= latest


build:
	docker build \
		-t $(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
		-f Dockerfile .
.PHONY: build


# Use to build both arm64 and amd64 images at the same time.
# WARNING! Will automatically push, since multi-platform images are not available locally.
# Use `REPOSITORY` arg to specify which container repository to push the images to.
buildx:
	docker run --privileged --rm tonistiigi/binfmt --install linux/amd64,linux/arm64
	docker buildx create --name darwin-builder --driver docker-container --bootstrap
	docker buildx use darwin-builder
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--push \
		-t $(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
		-f Dockerfile .

.PHONY: buildx

test:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
				bash -c 'set -eu; make test-ci'
.PHONY: test

test-ci:
	@echo "Checking Debian version..."
	@cat /etc/debian_version
	@echo
	@echo "Testing cross-compiling application..."
	@rustc -vV
	@echo
	@cd tests/hello-world \
\
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			echo "Compiling application (linux-gnu x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-gnu; \
			du -sh target/x86_64-unknown-linux-gnu/release/helloworld; \
			target/x86_64-unknown-linux-gnu/release/helloworld; \
			echo; \
\
			echo "Compiling application (linux-musl x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-musl; \
			du -sh target/x86_64-unknown-linux-musl/release/helloworld; \
			target/x86_64-unknown-linux-musl/release/helloworld; \
			echo; \
		fi \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/helloworld \
		&& echo \
\
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-gnu \
		&& du -sh target/aarch64-unknown-linux-gnu/release/helloworld \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/helloworld; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-musl \
		&& du -sh target/aarch64-unknown-linux-musl/release/helloworld \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/helloworld; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/helloworld
	@echo
	@cd ../..
	@cd tests/flate2-test \
\
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			echo "Compiling application (linux-gnu x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-gnu; \
			du -sh target/x86_64-unknown-linux-gnu/release/flate2-test; \
			target/x86_64-unknown-linux-gnu/release/flate2-test; \
			echo; \
\
			echo "Compiling application (linux-musl x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-musl; \
			du -sh target/x86_64-unknown-linux-musl/release/flate2-test; \
			target/x86_64-unknown-linux-musl/release/flate2-test; \
			echo; \
		fi \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& LIBZ_SYS_STATIC=0 CC=arm64e-apple-darwin22.2-clang CXX=arm64e-apple-darwin22.2-clang++ \
			cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/flate2-test \
		&& echo \
\
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-gnu \
		&& du -sh target/aarch64-unknown-linux-gnu/release/flate2-test \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/flate2-test; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-musl \
		&& du -sh target/aarch64-unknown-linux-musl/release/flate2-test \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/flate2-test; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& LIBZ_SYS_STATIC=0 CC=arm64e-apple-darwin22.2-clang CXX=arm64e-apple-darwin22.2-clang++ \
			cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/flate2-test

.ONESHELL: test-ci
