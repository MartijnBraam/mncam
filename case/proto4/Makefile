.PHONY: all
all: box case mounts panels

case.tar.gz: all
	tar -cvzf $@ *.stl **/*.stl

.PHONY: mounts
mounts: mounts/p4_imx290.stl mounts/p4_mft.stl mounts/p4_cmount.stl mounts/p4_pi_hq.stl

.PHONY: box
box: box_frame_bottom.stl box_frame_top.stl

.PHONY: panels
panels: panels/blank.stl panels/blank_short.stl panels/waveshare_5inch.stl panels/rear_io_6d.stl panels/sensor.stl panels/cheese.stl

.PHONY: case
case: case_front.stl case_rear.stl

box_frame_bottom.stl: case_box.scad
	openscad -m make -o $@ -d $@.deps -D "render_bottom=true"  $<

box_frame_top.stl: case_box.scad
	openscad -m make -o $@ -d $@.deps -D "render_bottom=false"  $<

include $(wildcard *.deps)

%.stl: %.scad
	openscad -m make -o $@ -d $@.deps $<

.PHONY: clean
clean:
	rm -f *.stl
	rm -f *.deps
	rm -f mounts/*.stl
	rm -f mounts/*.deps
	rm -f panels/*.stl
	rm -f panels/*.deps
	rm -f case.tar.gz
