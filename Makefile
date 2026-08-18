SRCFILES := $(shell find . -iname *.go -type f -print)
PREFIX := /usr/local

.PHONY: all
all: overlays driver

.PHONY: overlays
overlays: overlay/mncam-proto3.dtbo

.PHONY: driver
driver:
	$(MAKE) -C driver

%.dtbo: %.dts
	@printf 'DTC\t%s\n' '$@'
	@dtc -@ -I dts -O dtb -o '$@' $<

.PHONY: install-overlays
install-overlays: overlays
	cp -v overlay/mncam-proto3.dtbo /boot/firmware/overlays/

.PHONY: install-driver
install-driver: driver
	@cp -v driver/mncamaudio.ko /lib/modules/$(shell uname -r)/kernel/sound/soc/bcm
	depmod -a