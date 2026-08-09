#import "@preview/colorful-boxes:1.4.3": colorbox
#set document(title: [ConfCam user manual])
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

ConfCam is a modular open hardware camera for live streaming conferences.

Main features:
- video output: low latency HDMI, network stream
- control: touchscreen, web browser and ssh
- audio input: dual XLR, dual internal mic
- modular sensors and lenses

#outline()

= Hardware setup

== The lens

The camera uses a c-mount lens by default. If yours comes without a lens, consult the ConfCam build manual on connecting one.

You can adjust the lens manually to the room: zoom, aperture and focus. 

== Mounting the camera

To mount the camera on a tripod, use one or more tripod thread insert holes on the bottom panel of the camera.

To hang the camera, use the thread insert holes on the top panel of the camera.

== Rear I/O panel

TODO photo
- 1x 5.5/2.1mm barrel jack receiver for power input
- 1x HDMI output
- 1x RJ45 connector
- 2x XLR female audio input


== Powering the camera

Connect 12V >=1A power to the back panel of the camera using a 5.5/2.1mm barrel jack connector.

== Connect hdmi output (optional)

Connect a hdmi output cable to the back panel of the camera. This is optional. Video only output will still work over the network.

== Connect network (optional)

If you want to use ConfCam's network stream or remote configuration, connect to an ethernet network. 

== Connect XLR audio input (optional)

Each audio input expects line level balanced mono XLR audio input.

= User interface

== Touchscreen

=== Top bar
- Auto Exposure
  - AE Comp (auto exposure compensation): slider
  - Auto Exposure: toggle
- FPS
  - 24|25|30|60
- Shutter: slider 1/30 - 1/300s
- Gain: slider 1 - 15 dB
- Timecode
- Balance
  - #link("https://en.wikipedia.org/wiki/Color_temperature")[Temperature]: slider
  - Auto Whitebalance: toggle
  - Mode: Auto|Tungsten|Fluorescent|Indoor|Daylight|Cloudy
- Camera ID. TODO. Only implemented for use with ATEM switchers for now.
- ⚙ (Settings)
  - System
    - Backlight
  - Audio
    - Left gain
    - Right gain
    - Left src
    - Right src
  - Info
    - Sensor
    - IP Address

=== Bottom bar
Toggles. White means disabled. Blue means enabled.

- #link("https://en.wikipedia.org/wiki/Zebra_patterning")[Zebra]
- #link("https://en.wikipedia.org/wiki/Image_histogram")[Hist.] (histogram)
- #link("https://en.wikipedia.org/wiki/Focus_(optics)")[Focus]
- #link("https://en.wikipedia.org/wiki/Exposure_%28photography%29")[Exp] (exposure hint)
- Guides multi toggle: #link("https://en.wikipedia.org/wiki/Rule_of_thirds")[Thirds]|Cross|#link("https://en.wikipedia.org/wiki/Safe_area_(television)")[Safe area overlay]
- HDMI overlay. Toggles visibility of menu items onto the hdmi output stream. 

== IP

The camera's ip address is available via the touchscreen: ⚙ -> info -> ip address. (The camera configures its ip address by dhcp.)

=== Web
The web interface is available at #link("http://$camera_ip").

=== Ssh

TODO The default ssh password is available via the touchscreen: ⚙ -> info -> password.

The ConfCam configration is stored in `/boot/camera.ini`.

Systemd services to observe are: camera, camera-api and mediamtx.

= Output stream

The camera outputs are available as both an hdmi and a network stream.

Hdmi stream characteristics:
- resolution: 1920x1080 (1080p)
- framerate: 30 fps default. Higher framerates up to 60 fps are possible, but disable network preview streams.
- audio: disabled by default, can be enabled in the touchscreen interface

Network stream characteristics:
- resolution: 1920x1080p
- video encoding: h264
- framerate: up to 30 fps
- bitrate: default 10 Mbit/s
- audio: not available
- #link("rtmp://$camera_ip:1935/cam") : rtmp stream
- #link("rtsp://$camera_ip:8554/cam"): rtsp stream
- #link("http://$camera_ip:8888/cam/index.m3u8") : hls stream
- #link("http://$camera_ip:8889/cam") : webrtc stream (browser only)
- #link("srt://$camera_ip:8890?streamid=read:cam") : srt stream
