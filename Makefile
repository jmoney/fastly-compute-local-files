BINDIR = bin
PACKAGEDIR = pkg
SOURCEDIR = cmd

DIRS = $(shell find $(SOURCEDIR) -maxdepth 1 -mindepth 1 -type d)
OBJECTS = $(patsubst $(SOURCEDIR)/%, $(BINDIR)/%.wasm, $(DIRS))
PACKAGES = $(patsubst $(SOURCEDIR)/%, $(PACKAGEDIR)/%.tar.gz, $(DIRS))
SOURCES = $(shell find $(SOURCEDIR) -name '*.go' -type f)

CARGO_PACKAGE_VERSION = 0.3.5

PACKAGE_VERSION = $(shell date --utc '+%Y%m%d%H%M%S')_$(shell git rev-parse --short HEAD)

RELEASE_PREFIX = release
PRERELEASE_PREFIX = prerelease

PRERELEASE = $(PRERELEASE_PREFIX)-$(PACKAGE_VERSION)
RELEASE = $(RELEASE_PREFIX)-$(PACKAGE_VERSION)

all: clean test build package

mod:
	go mod tidy

deps:
	@cargo install --version $(CARGO_PACKAGE_VERSION) viceroy

test:
	@go test -v ./...

build: mod $(OBJECTS)

package: test build $(PACKAGES)

$(PACKAGEDIR)/%.tar.gz: $(BINDIR)/%.wasm
	@echo "Building package" $@
	@mkdir -p $(PACKAGEDIR)
	@mkdir -p /tmp/$(patsubst $(BINDIR)/%.wasm,%,$<)/bin
	@cp $< /tmp/$(patsubst $(BINDIR)/%.wasm,%,$<)/bin/main.wasm
	@cp $(patsubst $(PACKAGEDIR)/%.tar.gz,%.txt,$@) /tmp/$(patsubst $(BINDIR)/%.wasm,%,$<)/localfiles.txt
	@cp configs/fastly/$(patsubst $(PACKAGEDIR)/%.tar.gz,%.toml,$@) /tmp/$(patsubst $(BINDIR)/%.wasm,%,$<)/fastly.toml
	tar -C /tmp/$(patsubst $(BINDIR)/%.wasm,%,$<)/ -cvzf $@ .

$(BINDIR)/%.wasm: $(SOURCEDIR)/%/main.go
	@mkdir -p $(BINDIR)
	tinygo build -target=wasi -gc=conservative -o $@ $<

clean:
	@rm -rvf bin pkg .terraform.lock.hcl

run-%: $(BINDIR)/%.wasm
	viceroy --config $(patsubst $(BINDIR)/%.wasm,configs/fastly/%.toml,$<) $<