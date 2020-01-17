BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT := $(shell git rev-parse --short HEAD)

LDFLAGS := -gcflags=all=-trimpath=${PWD} -asmflags=all=-trimpath=${PWD} -ldflags=-extldflags=-zrelro -ldflags=-extldflags=-znow
ifdef VERSION
	LDFLAGS += -ldflags '-s -w -X main.commit=$(COMMIT) -X main.branch=$(BRANCH) -X main.version=$(VERSION)'
else
	VERSION := $(BRANCH)-$(COMMIT)
	LDFLAGS += -ldflags '-s -w -X main.commit=$(COMMIT) -X main.branch=$(BRANCH)'
endif
MOD := -mod=vendor
export G111MODULE=on
PKGS := $(shell go list ./... | grep -v /vendor)
GOPLUGINS := $(shell go list ./... | grep -v /vendor | awk -F'/' '{print $$NF}')
PLUGINS := $(shell echo ./*)
PLUGINS := $(shell echo ${GOPLUGINS} ${PLUGINS} | tr ' ' '\n' | sort | uniq -u)
GOCC := $(shell go version)

ifdef GOBIN
PATH := $(GOBIN):$(PATH)
else
PATH := $(subst :,/bin:,$(shell go env GOPATH))/bin:$(PATH)
endif

ifneq (,$(findstring gccgo,$(GOCC)))
	export GOPATH=$(shell pwd)/.go
	LDFLAGS := -gccgoflags '-s -w'
	MOD :=
endif

default: build

.PHONY: all
all: lint test build

.PHONY: test
test:
	go test $(PKGS)

.PHONY: lint
lint:
	for p in ${GOPLUGINS}; do golangci-lint run $$p; done

.PHONY: install
install:
	install -d -m 775 $(DESTDIR)/usr/lib/gogios/plugins
	install -m 775 bin/plugins/* $(DESTDIR)/usr/lib/gogios/plugins

.PHONY: build
build:
	mkdir -p bin/plugins
	for p in ${GOPLUGINS}; do go build -o bin/$$p ./$$p; done
	for f in ${PLUGINS}; do cp "$$f"/* bin/plugins; done
