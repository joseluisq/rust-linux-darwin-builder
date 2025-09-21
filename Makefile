REPOSITORY ?= joseluisq
TAG ?= latest


build:
	docker build \
		-t $(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
		--network=host \
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

run:
	@docker run --rm -it \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
				bash
.PHONY: run

test:
	@docker run --rm \
		-v $(PWD):/root/src \
		-w /root/src \
			$(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
				bash -c 'set -eu; make test-ci; make test-openssl'
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
			du -sh target/x86_64-unknown-linux-gnu/release/hello-world-test; \
			target/x86_64-unknown-linux-gnu/release/hello-world-test; \
			echo; \
\
			echo "Compiling application (linux-musl x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-musl; \
			du -sh target/x86_64-unknown-linux-musl/release/hello-world-test; \
			target/x86_64-unknown-linux-musl/release/hello-world-test; \
			echo; \
		fi \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/hello-world-test \
		&& echo \
\
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-gnu \
		&& du -sh target/aarch64-unknown-linux-gnu/release/hello-world-test \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/hello-world-test; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-musl \
		&& du -sh target/aarch64-unknown-linux-musl/release/hello-world-test \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/hello-world-test; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/hello-world-test
	@echo
	@cd ../..
	@echo "Compiling zlib app..."
	@cd tests/zlib \
\
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			echo "Compiling application (linux-gnu x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-gnu; \
			du -sh target/x86_64-unknown-linux-gnu/release/zlib-test; \
			target/x86_64-unknown-linux-gnu/release/zlib-test; \
			echo; \
\
			echo "Compiling application (linux-musl x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-musl; \
			du -sh target/x86_64-unknown-linux-musl/release/zlib-test; \
			target/x86_64-unknown-linux-musl/release/zlib-test; \
			echo; \
		fi \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& LIBZ_SYS_STATIC=0 CC=o64-clang CXX=o64-clang++ \
			cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/zlib-test \
		&& echo \
\
		&& echo "Cross-compiling application (linux-gnu aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-gnu \
		&& du -sh target/aarch64-unknown-linux-gnu/release/zlib-test \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-gnu/release/zlib-test; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (linux-musl aarch64)..." \
		&& cargo build --release --target aarch64-unknown-linux-musl \
		&& du -sh target/aarch64-unknown-linux-musl/release/zlib-test \
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			target/aarch64-unknown-linux-musl/release/zlib-test; \
		fi \
		&& echo \
\
		&& echo "Cross-compiling application (apple-darwin aarch64)..." \
		&& LIBZ_SYS_STATIC=0 CC=o64-clang CXX=o64-clang++ \
			cargo build --release --target aarch64-apple-darwin \
		&& du -sh target/aarch64-apple-darwin/release/zlib-test

.ONESHELL: test-ci

test-openssl:
	@echo "Checking Debian version..."
	@cat /etc/debian_version
	@echo
	@echo "Testing cross-compiling openssl application..."
	@rustc -vV
	@echo
	@cd tests/openssl \
\
		&& if [ "$$(uname -m)" = "x86_64" ]; then \
			echo "Compiling application (linux-gnu x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-gnu; \
			du -sh target/x86_64-unknown-linux-gnu/release/openssl; \
			target/x86_64-unknown-linux-gnu/release/openssl; \
			echo; \
\
			echo "Compiling application (linux-musl x86_64)..."; \
			cargo build --release --target x86_64-unknown-linux-musl; \
			du -sh target/x86_64-unknown-linux-musl/release/openssl; \
			target/x86_64-unknown-linux-musl/release/openssl; \
			echo; \
		fi \
\
		&& echo "Cross-compiling application (apple-darwin x86_64)..." \
		&& export OSXCROSS_MACPORTS_LIBEXEC=/usr/local/osxcross/target/macports/pkgs/opt/local/libexec \
		&& OPENSSL_STATIC=1 \
			OPENSSL_DIR=$$(echo $$OSXCROSS_MACPORTS_LIBEXEC)/openssl3/include/openssl \
			OPENSSL_LIB_DIR=$$(echo $$OSXCROSS_MACPORTS_LIBEXEC)/openssl3/lib \
			OPENSSL_INCLUDE_DIR=$$(echo $$OSXCROSS_MACPORTS_LIBEXEC)/openssl3/include \
			CC=o64-clang CXX=o64-clang++ \
				cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/openssl \
		&& echo \
\
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			echo "Cross-compiling application (linux-musl aarch64)..."; \
			cargo build --release --target aarch64-unknown-linux-musl; \
			du -sh target/aarch64-unknown-linux-musl/release/openssl; \
			target/aarch64-unknown-linux-musl/release/openssl; \
		fi \
		&& echo \
\
		&& if [ "$$(uname -m)" = "aarch64" ]; then \
			echo "Cross-compiling application (apple-darwin aarch64)..."; \
			OPENSSL_STATIC=1 \
				OPENSSL_DIR=$$(echo $$OSXCROSS_MACPORTS_LIBEXEC)/openssl3/include/openssl \
				OPENSSL_LIB_DIR=$$(echo $$OSXCROSS_MACPORTS_LIBEXEC)/openssl3/lib \
				OPENSSL_INCLUDE_DIR=$$(echo $$OSXCROSS_MACPORTS_LIBEXEC)/openssl3/include \
				CC=o64-clang CXX=o64-clang++ \
					cargo build --release --target aarch64-apple-darwin; \
				du -sh target/aarch64-apple-darwin/release/openssl; \
		fi \

.ONESHELL: test-openssl
