SRCFILES := $(shell find . -iname *.go -type f -print)
PREFIX := /usr/local

.PHONY: all
all: mncam_api

.PHONY: overlays
overlays: overlay/mncam-proto3.dtbo

mncam_api: $(SRCFILES) Makefile
	@printf 'GO\t%s\n' '$@'
	@go build -o mncam_api ./cmd/mncam_api

.PHONY: install
install: all
	install -Dm755 mncam_api $(DESTDIR)$(PREFIX)/bin/mncam_api

%.dtbo: %.dts
	@printf 'DTC\t%s\n' '$@'
	@dtc -@ -I dts -O dtb -o '$@' $<

.PHONY: install-overlays
install-overlays: overlays
	cp -v overlay/mncam-proto3.dtbo /boot/firmware/overlays/