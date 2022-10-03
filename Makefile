REPOSITORY ?= joseluisq
TAG ?= latest


build:
	docker build \
		-t $(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
		-f docker/Dockerfile .
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
		-f docker/Dockerfile .

.PHONY: buildx

test:
	@docker run --rm -it \
		-v $(PWD):/drone/src \
		-w /drone/src \
			$(REPOSITORY)/rust-linux-darwin-builder:$(TAG) \
				make test-ci
.PHONY: test

test-ci:
	@echo "Testing cross-compiling application..."
	@rustc -vV
	@echo
	@cd tests/hello-world \
		&& echo "Compiling application (linux-musl $$(uname -m))..." \
		&& cargo build --release --target "$$(uname -m)-unknown-linux-musl" \
		&& du -sh target/$$(uname -m)-unknown-linux-musl/release/helloworld \
		&& ./target/$$(uname -m)-unknown-linux-musl/release/helloworld \
		&& echo \
\
		&& echo "Compiling application (apple-darwin x86_64)..." \
		&& cargo build --release --target x86_64-apple-darwin \
		&& du -sh target/x86_64-apple-darwin/release/helloworld \
		&& echo \
\
		&& echo "Compiling application (apple-darwin aarch64)..." \
                && cargo build --release --target aarch64-apple-darwin \
                && du -sh target/aarch64-apple-darwin/release/helloworld

.ONESHELL: test-ci

promote:
	@drone build promote joseluisq/rust-linux-darwin-builder $(BUILD) $(ENV)
.PHONY: promote
