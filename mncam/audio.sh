#!/bin/sh

arecord -D hw:CARD=sndrpihifiberry,DEV=0 -c 2 -r 48000 -f S16_LE | ffmpeg -acodec pcm_s16le -i - -ac 2 \
  -af astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.1.RMS_level,ametadata=print:key=lavfi.astats.2.RMS_level \
 -f alsa hdmi:CARD=vc4hdmi0,DEV=0
