VERSION := $(shell cat VERSION)

# GNU make -j értékének meghatározása.
# make build       -> JOBS=1
# make build -j3   -> JOBS=3
# make build -j20  -> JOBS=20
JOBS := $(shell \
	echo '$(MAKEFLAGS)' | \
	sed -n 's/.*-j\([0-9][0-9]*\).*/\1/p')

ifeq ($(strip $(JOBS)),)
JOBS := 1
endif

.PHONY: source build test sign verify evidence repo release clean

source:
	./scripts/preflight.sh
	./scripts/fetch-source.sh
	./scripts/verify-source.sh

build: source
	JOBS=$(JOBS) ./scripts/build-rpm.sh

test:
	JOBS=$(JOBS) ./scripts/test-rpm.sh

sign:
	./scripts/sign-rpm.sh

verify:
	./scripts/verify-rpm.sh

evidence:
	./scripts/generate-evidence.sh

repo:
	./scripts/create-yum-repo.sh

release: source build test sign verify evidence
	@echo "Release completed."

clean:
	rm -rf work/rpmbuild
	rm -f artifacts/openssl35-*.rpm