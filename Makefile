SHELL=/bin/bash -o pipefail

REGISTRY   ?= ghcr.io/appscode-images
BIN        ?=
IMAGE      := $(REGISTRY)/cert-manager-$(BIN)
VERSION    ?= $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")
TAG        := $(VERSION)-ubi
RH_COMP_ID ?=

component_id.acmesolver =
component_id.cainjector =
component_id.controller =
component_id.webhook    =

.PHONY: all-build
all-build: build-acmesolver build-cainjector build-controller build-webhook

.PHONY: all-certify
all-certify: certify-acmesolver certify-cainjector certify-controller certify-webhook

build-%:
	@$(MAKE) build           \
	    --no-print-directory \
	    BIN=$*

certify-%:
	@$(MAKE) docker-certify-redhat \
	    --no-print-directory \
	    BIN=$*               \
	    RH_COMP_ID=$(call get_component_id,$*)

.PHONY: build
build: builder
	@docker build --push --builder container --platform linux/amd64,linux/arm64 --build-arg VERSION=$(VERSION) --label version=$(VERSION) -t $(IMAGE):$(TAG) -f Dockerfile.$(BIN) .

.PHONY: builder
builder:
	@docker buildx create --name container --driver=docker-container || true

.PHONY: docker-certify-redhat
docker-certify-redhat:
	@preflight check container $(IMAGE):$(TAG) \
		--submit \
		--certification-component-id=$(RH_COMP_ID)

define get_component_id
$(component_id.$(1))
endef
