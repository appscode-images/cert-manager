SHELL=/bin/bash -o pipefail

REGISTRY   ?= ghcr.io/appscode-images
BIN        ?=
IMAGE      := $(REGISTRY)/cert-manager-$(BIN)
VERSION    ?= $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")
TAG        := $(VERSION)-ubi
RH_COMP_ID ?=

component_id.acmesolver = 6969cd96bc52598aba893c76
component_id.cainjector = 6969cdb1d4e6b45bb1b329e0
component_id.controller = 6969cdc6bc52598aba893cfb
component_id.webhook    = 6969cde1a53084e80dd4647d

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
