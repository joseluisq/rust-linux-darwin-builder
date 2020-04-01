build:
	docker build \
		-t joseluisq/rust-linux-darwin-builder:latest \
		-f docker/Dockerfile .
.PHONY: build

test:
	@sudo chown -R rust:rust ./
	@echo "Testing application..."
	@rustc -vV
	@echo "Compiling application(linux-musl x86_64)..."
	@cargo build --manifest-path=examples/hello-world/Cargo.toml --release --target x86_64-unknown-linux-musl
	@du -sh examples/hello-world/target/x86_64-unknown-linux-musl/release/helloworld
	@echo
	@echo "Compiling application(apple-darwin x86_64)..."
	@cargo build --manifest-path=examples/hello-world/Cargo.toml --release --target x86_64-apple-darwin
	@du -sh examples/hello-world/target/x86_64-apple-darwin/release/helloworld
.ONESHELL: test

release:
	# 2. Update docker files to latest tag
	./docker/version.sh $(TAG)

	# 3. Commit and push to latest tag
	git add docker/Dockerfile
	git commit docker/Dockerfile -m "$(TAG)"
	git tag $(TAG)
	git push origin master
	git push origin $(TAG)
.ONESHELL: release
