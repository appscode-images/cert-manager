SHELL=/bin/bash -o pipefail

REGISTRY   ?= ghcr.io/appscode-images
BIN        ?=
IMAGE      := $(REGISTRY)/cert-manager-$(BIN)
VERSION    ?= $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")
TAG        := $(VERSION)-ubi

.PHONY: all-build
all-build: build-acmesolver build-cainjector build-controller build-webhook

.PHONY: builder
builder:
	docker buildx create --name container --driver=docker-container || true

.PHONY: build
build: builder
	docker build --push --builder container --platform linux/amd64,linux/arm64 --build-arg VERSION=$(VERSION) --label version=$(VERSION) -t $(IMAGE):$(TAG) -f Dockerfile.$(BIN) .

build-%:
	@$(MAKE) build           \
	    --no-print-directory \
	    BIN=$*
