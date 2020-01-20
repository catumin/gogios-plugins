LDFLAGS := -gcflags=all=-trimpath=${PWD} -asmflags=all=-trimpath=${PWD} -ldflags=-extldflags=-zrelro -ldflags=-extldflags=-znow
MOD := -mod=vendor
export G111MODULE=on
PKGS := $(shell go list ./... | grep -v /vendor)
GOPLUGINS := $(shell go list ./... | grep -v /vendor | grep /plugins/ | awk -F'/' '{print $$(NF-1)"/"$$NF}')
PLUGINS := $(shell echo plugins/*)
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

.PHONY: clean
clean:
	rm -r bin/

.PHONY: build
build:
	mkdir -p bin
	for p in ${GOPLUGINS}; do go build -o bin/$$p ./$$p; done
	for f in ${PLUGINS}; do cp "$$f"/* bin/plugins/; done
