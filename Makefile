SRCFILES := $(shell find . -iname *.go -type f -print)
PREFIX := /usr/local

.PHONY: all
all: mncam_api

mncam_api: $(SRCFILES) Makefile
	@printf 'GO\t%s\n' '$@'
	@go build -o mncam_api ./cmd/mncam_api

.PHONY: install
install: all
	install -Dm755 mncam_api $(DESTDIR)$(PREFIX)/bin/mncam_api