SHELL := /bin/bash

.PHONY: preflight source build test evidence sign verify-rpm repo release dev-release clean

preflight:
	./scripts/preflight.sh

source: preflight
	./scripts/fetch-source.sh
	./scripts/verify-source.sh

build: source
	./scripts/build-rpm.sh

test: build
	./scripts/test-rpm.sh

evidence:
	./scripts/generate-evidence.sh

sign:
	./scripts/sign-rpm.sh

verify-rpm:
	./scripts/verify-rpm.sh

repo:
	./scripts/create-yum-repo.sh

release: clean preflight source build test sign verify-rpm evidence repo
	./scripts/assemble-release.sh

dev-release: clean preflight source build test evidence
	ALLOW_UNSIGNED=1 ./scripts/assemble-release.sh

clean:
	rm -rf work artifacts release
