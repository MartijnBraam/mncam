#import "@preview/colorful-boxes:1.4.3": colorbox
#set document(title: [ConfCam build manual])
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

These are build instructions for ConfCam, a modular open hardware camera for live streaming conferences.

Main features:
- video output: low latency HDMI, network stream
- control: touchscreen, web browser and ssh
- audio input: dual XLR, dual internal mic
- modular sensors and lenses

#outline()

= Hardware build
== BOM

For building the most accessible variant, the following components are used:
- Raspberry pi 4 compute module >=1 Gb RAM. Note that the Raspberry pi 5 compute module will not work. It lacks crucial components.
- 8 Gb SD card
- Waveshare 5inch 1024x600 DSI touch display (#link("https://www.waveshare.com/5inch-dsi-lcd-c.htm")[5inch-dsi-lcd-c])
- Raspberry pi HQ camera module
- custom audio module
- 3d printed
  - case
  - lens mount
- cables and connectors
- screws, nuts and bolts
- connectors
- threaded M2.5x4x4 metal inserts for putting bolts in the 3D prints
- M2.5x6mm bolts

== The box
#align(center)[#image("box-exploded.png")]

The bottom of the box frame is a tripod mounting plate with 3 holes for tripod thread inserts. The other 5 sides you can adapt to your needs.


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

== Common parts

All current versions of the camera are build around the same Raspberry Pi and display. The Raspberry Pi 4 is used because the newer versions no longer have the DSI output for the display connected to the SoC so they don't allow the zero copy video output directly from the camera on it.


#note[
  Sizes of threaded metal heat-inserts are specified in #text(gray)[size]x#text(gray)[depth]x#text(gray)[outer-diameter] format. For example
  an M2.5x5x4 is an insert for an M2.5 sized bolt that fits in a hole that's 5mm deep and 4mm in diameter.
]

== Sensors and lenses

The cases are designed to have a modular lens and sensor mounting system, allowing to build a camera with any combination of the
supported sensors and lens mounts. This is done by printing the sensor mount for the sensor you need and mounting that to one
of the lens mounts to make a complete sensor assembly.

=== Raspberry Pi HQ sensor (IMX477)

This is the easiest sensor to get. It combines well with C-mount lenses.

- Raspberry Pi HQ sensor (#link("https://www.raspberrypi.com/products/raspberry-pi-high-quality-camera/")[at raspberrypi.com])

This sensor has a pretty nice metal C-mount attached to it so for this specific case there's a seperate mount that integrates
the sensor and lens mount. For this print `p4_pi_hq.stl` and order 4x M2.5x4x4 inserts and 4 M2.5 bolts.

=== C-mount lenses

C-mount security camera lenses are the easiest and cheapest option. These are widely available and match pretty well with the small sensors used in the ConfCam. The most flexible option is the 8-50mm lens that can be found rebranded from many manufacturers.

- 8-50mm C-mount lens (#link("https://www.waveshare.com/product/raspberry-pi/cameras/10mp-pixels/8-50mm-zoom-lens-for-pi.htm")[available at Waveshare])

For this lens mount you need to print `p4_cmount.stl` and this print takes 4 M2.5x4x4 inserts TODO length. 4 M2.5x6 bolts are needed
to mount the sensor to the lens mount.

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

Connect these to the Raspberry Pi inside the camera.

== The Raspberry Pi

With the essential panels installed, install the Raspberry Pi. 

= Software installation

ConfCam consists of several software components running on top of Raspbian Trixie.

== Raspbian trixie 64 bit
#link("https://projects.raspberrypi.org/en/projects/imager-install")[Install Raspbian Trixie lite 64-bit].

== Install c2 software

Boot the Raspberry pi with Raspbian trixie 64 bit installed. Either connect an external screen and keyboard or log in through ssh.

Clone the c2 git repository:

```
$ git clone https://github.com/martijnbraam/c2
```

Now we run the installation script:
```
$ cd c2
$ ./install.sh
```

This installs two components:
- MediaMTX. This publishes the video to the network.
- the `c2` python package. This publishes the video over hdmi, controls the hardware and renders the touchscreen UI.

== Configure software

=== `/boot/firmware/config.txt`

Now edit `/boot/firmware/config.txt` and adjust it to the installed hardware:

- For the Waveshare display, uncomment the line `dtoverlay=vc4-kms-dsi-waveshare-panel,7_0_inchC` to load the driver. Note the actual display size is 5", but the driver name suggests 7". That is confusing, but correct.
- For the audio board, uncomment the line `dtoverlay=mncam-proto3` to load the driver.

Now, we reboot the system:
`/sbin/reboot`

=== `/boot/camera.ini`

After the reboot, the camera and display hardware are autodetected. This generates a `/boot/camera.ini` configuration file. Verify this exists. Changes to this file are optional. This is where changes made using the touchscreen will be saved.

== Alternative hardware

=== Alternative sensors
If not using a Raspberry Pi Foundation sensor, in `/boot/firmware/config.txt`, comment the line `camera_auto_detect` and uncomment the line for your specific sensor.

==== Waveshare IMX462

This sensor has better light sensitivity but slightly higher base noise than the Raspberry Pi HQ sensor.

It comes on a slightly smaller board than the official Raspberry Pi HQ sensor. You will have to remove the pre-mounted lens first.

Waveshare also has slightly different versions available with slightly adjusted mounting points. ConfCam uses a version with the mounting points to the side of the connector instead of behind it.

- #link("https://www.waveshare.com/imx462-ir-cut-camera-a.htm")[Waveshare IMX462 IR-CUT Camera (A)]

For this sensor, 3d print `p4_imx290.stl` and order 4x M2.5x4x4 inserts and 4 M2.5 bolts.


=== MFT lenses

For better image quality MFT lenses can be used. Do mind that if combined with a small sensor, the effective zoom will be massively increased.

The MFT mount is a spring loaded bayonet mount. It needs some parts scavenged from an existing MFT extension
tube to work properly.

- #link("aliexpress.com/item/1005012641252086.html")[MCoplus autofocus MFT extension tube]

This extension set comes with 3 adapters. Each adapter has the machined metal parts needed. Remove the lens side of the adapter and keep the metal ring that holds the ring, the metal spring ring below it and the 4 screws that mount them to the case.

For this lens mount you need to print `p4_mft.stl` and mount the MFT extension tube parts to that. Use 4 M2.5x4x4 inserts and M2.5 bolts to mount the sensor to the lens mount.


