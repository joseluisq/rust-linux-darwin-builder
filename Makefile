build:
	docker build -t joseluisq/rust-linux-darwin-builder:1.40.0 -f Dockerfile .
.PHONY: build
