REPOSITORY ?= joseluisq/rust-linux-darwin-builder
TAG ?= devel

# AMD64 Tasks

amd64-build:
	docker build \
		-t $(REPOSITORY):$(TAG)-amd64 \
		--network=host \
		-f docker/amd64/base/Dockerfile .
.PHONY: amd64-build

amd64-run:
	@docker run --rm -it \
		-v $(PWD):/root/src \
		-v $(PWD)/docker/amd64/base/cargo.toml:/root/.cargo/config.toml \
		-w /root/src \
			$(REPOSITORY):$(TAG)-amd64 \
				bash
.PHONY: amd64-run

amd64-test:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY):$(TAG)-amd64 \
				bash -c 'set -eu; test-app'
.PHONY: amd64-test

amd64-build-libs:
	docker build \
		-t $(REPOSITORY):$(TAG)-amd64-libs \
		--network=host \
		-f docker/amd64/libs/Dockerfile .
.PHONY: amd64-build-libs

amd64-run-libs:
	@docker run --rm -it \
		-v $(PWD):/root/src \
		-v $(PWD)/docker/amd64/base/cargo.toml:/root/.cargo/config.toml \
		-w /root/src \
			$(REPOSITORY):$(TAG)-amd64-libs \
				bash
.PHONY: amd64-run-libs

amd64-test-libs:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY):$(TAG)-amd64-libs \
				bash -c 'set -eu; test-all'
.PHONY: amd64-test-libs


# ARM64 Tasks

arm64-build:
	docker build \
		-t $(REPOSITORY):$(TAG)-arm64 \
		--network=host \
		-f docker/arm64/base/Dockerfile .
.PHONY: arm64-build

arm64-test:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY):$(TAG)-arm64 \
				bash -c 'set -eu; test-app'
.PHONY: arm64-test

arm64-build-libs:
	docker build \
		-t $(REPOSITORY):$(TAG)-arm64-libs \
		--network=host \
		-f docker/arm64/libs/Dockerfile .
.PHONY: arm64-build-libs

arm64-run-libs:
	@docker run --rm -it \
		-v $(PWD):/root/src \
		-v $(PWD)/docker/arm64/libs/cargo.toml:/root/.cargo/config.toml \
		-w /root/src \
			$(REPOSITORY):$(TAG)-arm64-libs \
				bash
.PHONY: arm64-run-libs

arm64-test-libs:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY):$(TAG)-arm64-libs \
				bash -c 'set -eu; test-all'
.PHONY: arm64-test-libs


# Testing Tasks (inside the container)

test-all: test-app test-zlib test-openssl
.PHONY: test-all

test-app:
	@echo "Checking Debian version..."
	@cat /etc/debian_version
	@echo
	@echo "Testing cross-compiling application..."
	@rustc -vV
	@echo
	@cd tests/app \
\
		&& echo "Compiling application (linux-gnu x86_64)..." \
		&& cargo build -v --release --target x86_64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-gnu/release/app-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-gnu/release/app-test \
		&& file target/x86_64-unknown-linux-gnu/release/app-test \
		&& echo \
\
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& cargo build -v --release --target x86_64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-musl/release/app-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-musl/release/app-test \
		&& file target/x86_64-unknown-linux-musl/release/app-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& cargo build -v --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/app-test \
		&& file target/x86_64-apple-darwin/release/app-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& cargo build -v --release --target aarch64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/app-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-gnu/release/app-test \
		&& file target/aarch64-unknown-linux-gnu/release/app-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build -v --release --target aarch64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/app-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-musl/release/app-test \
		&& file target/aarch64-unknown-linux-musl/release/app-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& cargo build -v --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/app-test \
		&& file target/aarch64-apple-darwin/release/app-test \
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
		&& cargo build -v --release --target x86_64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "x86_64" ]; then
			target/x86_64-unknown-linux-gnu/release/zlib-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-gnu/release/zlib-test \
		&& file target/x86_64-unknown-linux-gnu/release/zlib-test \
		&& echo \
\
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& cargo build -v --release --target x86_64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "x86_64" ]; then
			target/x86_64-unknown-linux-musl/release/zlib-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-musl/release/zlib-test \
		&& file target/x86_64-unknown-linux-musl/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& CC=o64-clang CXX=o64-clang++ \
			cargo build -v --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/zlib-test \
		&& file target/x86_64-apple-darwin/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& CC=aarch64-linux-gnu-gcc \
			cargo build -v --release --target aarch64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/zlib-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-gnu/release/zlib-test \
		&& file target/aarch64-unknown-linux-gnu/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build -v --release --target aarch64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/zlib-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-musl/release/zlib-test \
		&& file target/aarch64-unknown-linux-musl/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& CC=oa64-clang CXX=oa64-clang++ \
			cargo build -v --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/zlib-test \
		&& file target/aarch64-apple-darwin/release/zlib-test \
		&& echo
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
		&& cargo build -v --release --target x86_64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-gnu/release/openssl-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-gnu/release/openssl-test \
		&& file target/x86_64-unknown-linux-gnu/release/openssl-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& CC=aarch64-linux-gnu-gcc \
			cargo build -v --release --target aarch64-unknown-linux-gnu \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/openssl-test; \
		fi \
		&& du -sh target/aarch64-unknown-linux-gnu/release/openssl-test \
		&& file target/aarch64-unknown-linux-gnu/release/openssl-test \
		&& echo \
\
		&& echo "Compiling application (linux-musl x86_64)..." \
		&& OPENSSL_STATIC=1 \
			cargo build -v --release --target x86_64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			target/x86_64-unknown-linux-musl/release/openssl-test; \
		fi \
		&& du -sh target/x86_64-unknown-linux-musl/release/openssl-test \
		&& file target/x86_64-unknown-linux-musl/release/openssl-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& OPENSSL_STATIC=1 \
			CC=o64-clang CXX=o64-clang++ \
				cargo build -v --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/openssl-test \
		&& file target/x86_64-apple-darwin/release/openssl-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& OPENSSL_STATIC=1 \
			cargo build -v --release --target aarch64-unknown-linux-musl \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/openssl-test;
		fi \
		&& du -sh target/aarch64-unknown-linux-musl/release/openssl-test \
		&& file target/aarch64-unknown-linux-musl/release/openssl-test \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& OPENSSL_STATIC=1 \
			CC=oa64-clang CXX=oa64-clang++ \
				cargo build -v --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/openssl-test \
		&& file target/aarch64-apple-darwin/release/openssl-test \
		&& echo
.ONESHELL: test-openssl

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
		-t $(REPOSITORY):$(TAG) \
		-f Dockerfile .
.PHONY: buildx
