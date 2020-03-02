build:
	docker build \
		-t joseluisq/rust-linux-darwin-builder:1 \
		-f Dockerfile .
.PHONY: build

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
