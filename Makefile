SRCFILES := $(shell find . -iname *.go -type f -print)
PREFIX := /usr/local

.PHONY: all
all: overlays driver

.PHONY: overlays
overlays: overlay/c2audio.dtbo

.PHONY: driver
driver:
	$(MAKE) -C driver

%.dtbo: %.dts
	@printf 'DTC\t%s\n' '$@'
	@dtc -@ -I dts -O dtb -o '$@' $<

.PHONY: install-overlays
install-overlays: overlays
	cp -v overlay/c2audio.dtbo /boot/firmware/overlays/

.PHONY: install-driver
install-driver: driver
	@cp -v driver/c2audio.ko /lib/modules/$(shell uname -r)/kernel/sound/soc/bcm
	depmod -a