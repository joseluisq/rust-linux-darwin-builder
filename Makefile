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
				make ci-test
.PHONY: test

ci-test:
	@echo "Testing application..."
	@rustc -vV
	@echo
	@echo "Compiling application(linux-musl x86_64)..."
	@cargo build --manifest-path=tests/hello-world/Cargo.toml --release --target x86_64-unknown-linux-musl
	@du -sh tests/hello-world/target/x86_64-unknown-linux-musl/release/helloworld
	@echo
	@echo "Compiling application(apple-darwin x86_64)..."
	@cargo build --manifest-path=tests/hello-world/Cargo.toml --release --target x86_64-apple-darwin
	@du -sh tests/hello-world/target/x86_64-apple-darwin/release/helloworld
.ONESHELL: ci-test

release:
	# 1. Update docker files to latest tag
	./docker/version.sh $(TAG)

	# 2. Commit and push to latest tag
	git add docker/Dockerfile
	git commit docker/Dockerfile -m "$(TAG)"
	git tag $(TAG)
	git push origin master
	git push origin $(TAG)
.ONESHELL: release

promote:
	@drone build promote joseluisq/rust-linux-darwin-builder $(BUILD) $(ENV)
.PHONY: promote
