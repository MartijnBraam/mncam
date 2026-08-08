#import "@preview/colorful-boxes:1.4.3": colorbox
#set document(title: [ConfCam manual])
#set page(
  paper: "a4",
  header: align(right+horizon, context [#document.title - #datetime.today().display()]),
  numbering: "1.",
)

#show title: set text(size: 30pt)
#show title: set align(center)
#title()

#align(center)[
#image("c2.png")
]

THIS

#let todo(c) = {
  text(red)[TODO: #c]
}

#let note(c) = {
  colorbox(
    title: "Note",
    color: (
      fill: rgb("#fff"),
      stroke: rgb("#ccc"),
      title: rgb("#000"),
    ),
    radius: 6pt,
    width: auto,
  )[#c]
}

#show heading.where(level: 1): set align(center)
#show heading.where(level: 1): set text(size: 22pt)
#show heading.where(level: 1, outlined: true): it => {
  pagebreak()
  it
  v(-0.7cm)
  line(length: 100%, stroke: gray)
  v(0.2cm)
}
#show link: underline

= The Conference Camera

The goal of ConfCam is to provide a relatively cheap camera to do live streaming of talks at conferences.

It is a device build around a Raspberry Pi and a camera module that produces a low latency video stream on
the HDMI output to be captured by a HDMI capture solution like the Fazantix streaming box. It also
provides remote control over the camera configuration over the network so the room live streaming can
be administred remotely.

#outline()

= Building the camera

There are two variations of the camera that can be built from roughly the same parts. There's the Proto4 case
that has a DSLR style body and the BoxCam case that is more similar to a modern cinema camera style body.

== Common parts

All current versions of the camera are build around the same Raspberry Pi and display. The Raspberry Pi 4 is
used because the newer versions no longer have the DSI output for the display connected to the SoC so they
don't allow the zero copy video output directly from the camera on it.

- Raspberry Pi 4 Model B
- SD card for the Raspberry Pi
- Waveshare 5inch 1024x600 DSI touch display (#link("https://www.waveshare.com/5inch-dsi-lcd-c.htm")[5inch-dsi-lcd-c])
- Threaded metal inserts for putting bolts in the 3D prints. Most of the design uses M2.5x4x4 inserts.
- M2.5 bolts. For the Proto4 design the Waveshare display comes with enough of them. For the Boxcam design more need to be ordered.

#note[
  Sizes of threaded metal heat-inserts are specified in #text(gray)[size]x#text(gray)[depth]x#text(gray)[outer-diameter] format. For example
  an M2.5x5x4 is an insert for an M2.5 sized bolt that fits in a hole that's 5mm deep and 4mm in diameter.
]

== Sensors and lenses

The cases are designed to have a modular lens and sensor mounting system, allowing to build a camera with any combination of the
supported sensors and lens mounts. This is done by printing the sensor mount for the sensor you need and mounting that to one
of the lens mounts to make a complete sensor assembly.

=== Raspberry Pi HQ sensor (IMX477)

This is the easiest sensor to get and combines well with C-mount lenses.

- Raspberry Pi HQ sensor (#link("https://www.raspberrypi.com/products/raspberry-pi-high-quality-camera/")[at raspberrypi.com])

This sensor has a pretty nice metal C-mount attached to it so for this specific case there's a seperate mount that integrates
the sensor and lens mount. For this print `p4_pi_hq.stl` and order 4x M2.5x4x4 inserts and 4 M2.5 bolts.

=== Waveshare IMX290/IMX462

This sensor has better light sensitivity but slightly higher base noise than the Raspberry Pi HQ sensor.
The IMX462 is a slightly newer version of the sensor with better noise performance but otherwise identical.

These sensors come on a slightly smaller board than the official Raspberry Pi sensors and always come with
a pre-mounted lens that first has to be removed. Waveshare also has slightly different versions available
with slightly adjusted mounting points. ConfCam uses the version that has the mounting points to the side
of the connector instead of behind it.

- #link("https://www.waveshare.com/imx290-83-ir-cut-camera.htm")[Waveshare IMX290-83 IR-CUT]
- #link("https://www.waveshare.com/imx462-ir-cut-camera-a.htm")[Waveshare IMX462 IR-CUT Camera (A)]

For these sensors print the `p4_imx290.stl` file and order 4x M2.5x4x4 inserts and 4 M2.5 bolts.

=== C-mount lenses

The easiest and cheapest option for lenses are the C-mount security camera lenses. These are widely available and match
pretty well with the small sensors used in the ConfCam. The most flexible option is the 8-50mm lens that can be found
rebranded from many manufacturers.

- 8-50mm C-mount lens (#link("https://www.waveshare.com/product/raspberry-pi/cameras/10mp-pixels/8-50mm-zoom-lens-for-pi.htm")[available at Waveshare])

For this lens mount you need to print `p4_cmount.stl` and this print takes 4 M2.5x4x4 inserts. 4 M2.5 bolts are needed
to mount the sensor to the lens mount.

=== MFT lenses

For better image quality MFT lenses can be used, but due to the small sensor sizes the effective zoom will be
massively increased.

The MFT mount is a spring loaded bayonet mount and needs some parts scavenged from an existing MFT extension
tube to work properly.

- #link("aliexpress.com/item/1005012641252086.html")[MCoplus autofocus MFT extension tube]

This extension set comes with 3 adapters that each have the machined metal parts that are needed. Remove
the lens side of these adapters and keep the metal ring that holds the ring, the metal spring ring that
is below it and the 4 screws that mounts them to the case.

For this lens mount you need to print `p4_mft.stl` and mount the MFT extension tube parts to that. Then 4
M2.5x4x4 inserts and M2.5 bolts are used for mounting the sensor to the lens mount.

== The BoxCam
#align(center)[#image("box-exploded.png")]

This case is designed to be a modular box that mounts on top of a tripod. The bottom of the box frame is
always a tripod mounting plate with 3 holes for tripod thread inserts. The other 5 sides are modular
and can be used to reconfigure the design of the camera.


=== The frame
The base frame for this design is `box_frame_top.stl` and `box_frame_bottom.stl` which together form the
mounting frame for the camera. The bottom has 3 holes for the tripod mounting inserts which need an UNC
insert to match up with the tripod threads.

- 24x M2.5x4x4 theaded metal insert
- 24x M2.5 bolt
- 3x 3/8-16x7mmx8mm threaded metal insert

The frame itself also needs 24 metal inserts and 4 bolts. 4 inserts for every panel that can be mounted
and 4 to keep the top and bottom half of the frame together.

=== Sensor/lens mount
For mounting the lens and sensor to the box camera print the `panels/sensor.stl` panel. This screws into
one of the short sides of the box frame with four of the M2.5 screws in the part list of the frame.

The lens adapter itself mounts to this panel using 4 M2.5 inserts and screws:

- 4x M2.5x4x4 theaded metal insert
- 4x M2.5 bolt

=== Display
One of the two long sides of the case are for the 5" display. For this print `panel/waveshare_5inch.scad`

To mount the display the M2.5 bolts that are included with the display itself can be used.

The panel is not completely symmetrical. The two mounting posts that are two-sided are supposed to be on
the bottom and the Waveshare display has a tiny flex going from the touchscreen to the display PCB that
sticks out slightly, this should also be on the bottom side.

=== Rear I/O panel
For connectivity the rear panel has space for 6 Neutrik d-series connectors. A good minimal set is
bringing out one HDMI, the ethernet and USB-B for power and stereo XLRs for audio input.

For this panel print `panel/rear_io_6d.stl` and order these parts:

- 1x Neutrik NAUSB-W-B (USB-A to USB-B feedthrough)
- 1x Neutrik NA HDMI-W-B
- 1x Neutrik NE8FDP-B (RJ45 feedthrough, comes with screws)
- 2x Neutrik NC3 FD-LX-B (XLR female chassis connector)
- 8x M3x10 bolt
- 8x M3 nut

These will be connected to the Raspberry Pi that will be placed inside the camera. It's possible to
also add an extra HDMI feedthrough to use both the HDMI outputs of the Pi for different output feeds.

== The Raspberry Pi

Now the essential panels are installed it's possible to install the Raspberry Pi. 

= Installing the software

ConfCam consists of several software components running on top of Raspbian Trixie. The first step
is to install Raspbian Trixie lite 64-bit using the normal Raspberry Pi install methods. Then clone
the git repository for ConfCam. This contains the required software and an installation script:

```
$ git clone https://github.com/martijnbraam/c2
$ cd c2
$ ./install.sh
```

This should install MediaMTX and configure it. This is used for making the h264 stream available
on the network for remote viewing on the webinterface. It also installs the `c2` python package
itself which renders all the UI and controls the hardware.

Manual adjustments are required in the Raspberry Pi boot configuration. Edit the file at
`/boot/firmware/config.txt` and adjust it to the installed hardware:

- For the Waveshare display used in this manual add `dtoverlay=vc4-kms-dsi-waveshare-panel,7_0_inchC`
  to load the driver.
- For the prototype audio board add `dtoverlay=mncam-proto3`
- When not using a Raspberry Pi Foundation sensor, disable `camera_auto_detect` and add the overlay
  required for the specific sensor.

The first time ConfCam starts the hardware is autodetected and a configuration file is generated for it.
This is mainly detecting wether there's a DSI panel in the camera for the UI or if HDMI is used for
the monitoring output. If the hardware is changed or the detection is run before the Raspberry Pi
boot config was adjusted you can remove `/boot/camera.ini` and restart the camera to re-detect the
hardware.

== The configuration file

The configration for ConfCam is stored in `/boot/camera.ini`

= Using the camera

By default the camera will start in full-automatic mode. The controls on the top of the touchscreen
configure all the exposure parameters for the camera.

