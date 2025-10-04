REPOSITORY ?= joseluisq
TAG ?= latest


build-amd64:
	docker build \
		-t $(REPOSITORY)/rust-linux-darwin-builder:$(TAG)-amd64 \
		--network=host \
		-f docker/amd64/Dockerfile .
.PHONY: build-amd64

build-arm64:
	docker buildx build \
		-t $(REPOSITORY)/rust-linux-darwin-builder:$(TAG)-arm64 \
		--network=host \
		--platform linux/arm64 \
		-f docker/arm64/Dockerfile .
.PHONY: build-arm64

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

run:
	@docker run --rm -it \
		-v $(PWD):/root/src \
		-v $(PWD)/cargo/config.toml:/root/.cargo/config.toml \
		-w /root/src \
			$(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
				bash
.PHONY: run

test:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
				bash -c 'set -eu; make test-app; make test-zlib; make test-openssl'
.PHONY: test

test-app:
	@echo "Checking Debian version..."
	@cat /etc/debian_version
	@echo
	@echo "Testing cross-compiling application..."
	@rustc -vV
	@echo
	@cd tests/hello-world \
\
		&& echo "Compiling application (linux-gnu x86_64)..." \
		&& cargo build --release --target x86_64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-gnu/release/hello-world-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-gnu/release/hello-world-test \
		&& file target/x86_64-unknown-linux-gnu/release/hello-world-test \
		&& echo \
\
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& cargo build --release --target x86_64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-musl/release/hello-world-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-musl/release/hello-world-test \
		&& file target/x86_64-unknown-linux-musl/release/hello-world-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/hello-world-test \
		&& file target/x86_64-apple-darwin/release/hello-world-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/hello-world-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-gnu/release/hello-world-test \
		&& file target/aarch64-unknown-linux-gnu/release/hello-world-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/hello-world-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-musl/release/hello-world-test \
		&& file target/aarch64-unknown-linux-musl/release/hello-world-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/hello-world-test \
		&& file target/aarch64-apple-darwin/release/hello-world-test \
		&& echo
.ONESHELL: test-app

test-zlib:
	@echo "Checking Debian version..."
	@cat /etc/debian_version
	@echo
	@echo "Testing cross-compiling zlib application..."
	@rustc -vV
	@echo
	@cd tests/zlib \
\
		&& echo "Compiling application (linux-gnu x86_64)..." \
		&& cargo build --release --target x86_64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "x86_64" ]; then
			target/x86_64-unknown-linux-gnu/release/zlib-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-gnu/release/zlib-test \
		&& file target/x86_64-unknown-linux-gnu/release/zlib-test \
		&& echo \
\
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& cargo build --release --target x86_64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "x86_64" ]; then
			target/x86_64-unknown-linux-musl/release/zlib-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-musl/release/zlib-test \
		&& file target/x86_64-unknown-linux-musl/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& CC=o64-clang CXX=o64-clang++ \
			cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/zlib-test \
		&& file target/x86_64-apple-darwin/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& CC=aarch64-linux-gnu-gcc \
			cargo build --release --target aarch64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/zlib-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-gnu/release/zlib-test \
		&& file target/aarch64-unknown-linux-gnu/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/zlib-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-musl/release/zlib-test \
		&& file target/aarch64-unknown-linux-musl/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& CC=oa64-clang CXX=oa64-clang++ \
			cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/zlib-test \
		&& file target/aarch64-apple-darwin/release/zlib-test \
		&& echo \

.ONESHELL: test-zlib

test-openssl:
	@echo "Checking Debian version..."
	@cat /etc/debian_version
	@echo
	@echo "Testing cross-compiling openssl application..."
	@rustc -vV
	@echo
	@cd tests/openssl \
\
		&& echo "Compiling application (linux-gnu x86_64)..." \
		&& cargo build --release --target x86_64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-gnu/release/openssl; \
		fi \
		&& du -sh target/x86_64-unknown-linux-gnu/release/openssl \
		&& file target/x86_64-unknown-linux-gnu/release/openssl \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& CC=aarch64-linux-gnu-gcc \
			cargo build --release --target aarch64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/openssl; \
		fi \
		&& du -sh target/aarch64-unknown-linux-gnu/release/openssl \
		&& file target/aarch64-unknown-linux-gnu/release/openssl \
		&& echo \
\
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& OPENSSL_STATIC=1 \
			cargo build --release --target x86_64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-musl/release/openssl; \
		fi \
		&& du -sh target/x86_64-unknown-linux-musl/release/openssl \
		&& file target/x86_64-unknown-linux-musl/release/openssl \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& OPENSSL_STATIC=1 \
			CC=o64-clang CXX=o64-clang++ \
				cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/openssl \
		&& file target/x86_64-apple-darwin/release/openssl \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& OPENSSL_STATIC=1 \
			cargo build --release --target aarch64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/openssl;
		fi \
		&& du -sh target/aarch64-unknown-linux-musl/release/openssl \
		&& file target/aarch64-unknown-linux-musl/release/openssl \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& OPENSSL_STATIC=1 \
			CC=oa64-clang CXX=oa64-clang++ \
				cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/openssl \
		&& file target/aarch64-apple-darwin/release/openssl \
		&& echo

.ONESHELL: test-openssl
