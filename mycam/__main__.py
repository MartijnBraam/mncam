import math
import time

import libcamera
from libcamera import ColorSpace
from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
from picamera2.outputs import PyavOutput
import numpy as np

from mycam.drmoutput import DRMOutput
from mycam.edid import check_edid
from PIL import Image, ImageDraw, ImageFont


class Camera:
    def __init__(self):
        self.cam = Picamera2()
        self.state = {}
        self.edid = None

        # Set initial camera mode and controls
        preview_config = self.cam.create_preview_configuration({"size": (1920, 1080), "format": "YUV420"}, controls={
            'FrameRate': 30,
            "NoiseReductionMode": libcamera.controls.draft.NoiseReductionModeEnum.Fast,
            "Sharpness": 0,
            "Saturation": 1,
            "HdrMode": 3,
        }, colour_space=ColorSpace.Rec709())
        self.cam.configure(preview_config)

        # Enable DRM output of the camera stream to the HDMI output and the DSI display
        self.drm = DRMOutput(1920, 1080)
        self.out_hdmi = self.drm.use_output("HDMI-A-1", 1920, 1080, 60)
        self.out_dsi = self.drm.use_output("DSI-1", 720, 1280)

        # Configure the hardware H.264 encoder
        self.encoder = H264Encoder(10_000_000)
        self.stream = PyavOutput("rtsp://127.0.0.1:8554/cam", format="rtsp")
        self.encoder.output = self.stream

        # Load fonts for overlays
        self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
        self.font_heading = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
        self.font_value = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)

        # Image buffers for overlay drawing
        self.dsi_overlay = Image.new("RGBA", (720, 1280), (0, 0, 0, 0))
        self.hdmi_overlay = Image.new("RGBA", (1920, 64), (0, 0, 0, 0))

    def start(self):
        self.cam.start_preview(self.drm)
        self.cam.start()
        self.cam.start_encoder(self.encoder)

        self.out_hdmi.position_overlay(0, 0, 1920, 64)

    def loop(self):
        self.state = self.cam.capture_metadata()
        self.edid = check_edid()
        self.draw_lcd_overlay()
        time.sleep(0.1)
        self.draw_hdmi_overlay()
        time.sleep(1)

    def draw_lcd_overlay(self):
        draw = ImageDraw.Draw(self.dsi_overlay)
        draw.rectangle((0, 0, 720, 28), fill=(0, 0, 0, 128))
        draw.text((13, 10), f"Camera {self.edid.camera_id}", font=self.font, fill=(255, 255, 255, 255))
        self.drm.set_overlay(np.array(self.dsi_overlay), output="DSI-1")

    def draw_hdmi_overlay(self):
        draw = ImageDraw.Draw(self.hdmi_overlay)
        draw.rectangle((0, 0, 1920, 64), fill=(0, 0, 0, 128))

        self.draw_value(draw, 32, "Camera", self.edid.camera_id)
        gdb = int(10 * math.log10(self.state["AnalogueGain"]))
        self.draw_value(draw, 150, "Gain", f"{gdb} dB")

        self.draw_value(draw, 300, "Shutter",
                        int(self.state["ExposureTime"] / float(self.state["FrameDuration"]) * 360))
        self.draw_value(draw, 450, "Whitebalance", f'{self.state["ColourTemperature"]}k')
        self.draw_value(draw, 600, "Focus", self.state["FocusFoM"])

        self.drm.set_overlay(np.array(self.hdmi_overlay), output="HDMI-A-1")

    def draw_value(self, ctx, x, name, value):
        ctx.text((x, 10), name, font=self.font_heading, fill=(255, 255, 255, 255), stroke_fill=(0, 0, 0, 255),
                 stroke_width=1)
        ctx.text((x, 24), str(value), font=self.font_value, fill=(255, 255, 255, 255), stroke_fill=(0, 0, 0, 255),
                 stroke_width=1)


if __name__ == '__main__':
    camera = Camera()
    camera.start()
    while True:
        camera.loop()
