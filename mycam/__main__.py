import math
import time
import cv2

import libcamera
from libcamera import ColorSpace
from picamera2 import Picamera2, Preview, MappedArray
from picamera2.encoders import H264Encoder
from picamera2.outputs import PyavOutput
import numpy as np

from mycam.api import ControlAPI
from mycam.drmoutput import DRMOutput
from mycam.edid import check_edid
from PIL import Image, ImageDraw, ImageFont


class Camera:
    def __init__(self):
        self.cam = Picamera2()
        self.state = {}
        self.edid = None
        self.preview_w = 1
        self.preview_h = 1

        self.output_hdmi = "HDMI-A-1"
        self.output_ui = "DSI-1"

        # Set initial camera mode and controls
        preview_config = self.cam.create_preview_configuration(main={
            "size": (1920, 1080),
            "format": "YUV420"
        },
            lores={
                "size": (1280, 720),
                "format": "YUV420"
            },
            controls={
                'FrameRate': 30,
                "NoiseReductionMode": libcamera.controls.draft.NoiseReductionModeEnum.Fast,
                "Sharpness": 0,
                "Saturation": 1,
                "HdrMode": 3,
            }, colour_space=ColorSpace.Rec709())
        self.cam.configure(preview_config)

        # Enable DRM output of the camera stream to the HDMI output and the DSI display
        self.drm = DRMOutput(1920, 1080)
        self.out_hdmi = self.drm.use_output(self.output_hdmi, 1920, 1080, 60, 1)
        self.out_dsi = self.drm.use_output(self.output_ui, 720, 1280, None, 3)

        # Configure the hardware H.264 encoder
        self.encoder = H264Encoder(10_000_000)
        self.stream = PyavOutput("rtsp://127.0.0.1:8554/cam", format="rtsp")
        self.encoder.output = self.stream

        def preview(request):
            self.update_preview(request)

        self.cam.pre_callback = preview

        # Load fonts for overlays
        self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
        self.font_heading = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
        self.font_value = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 30)

        # Image buffers for overlay drawing
        self.dsi_overlay = Image.new("RGBA", (720, 1280), (0, 0, 0, 0))
        self.hdmi_overlay = Image.new("RGBA", (1920, 64), (0, 0, 0, 0))

        self.api = ControlAPI(self)

        self.mat_black = None
        self.mat_white = None
        self.mat_zebra = None
        self.update_idx = 0

        self.thresh_zebra = 232
        self.thresh_under = 18

    def start(self):
        self.cam.start_preview(self.drm)
        self.cam.start()
        self.cam.start_encoder(self.encoder)

        self.out_hdmi.overlay_position(0, 0, 0, 1920, 64)

        # Set initial state to keep consistency with the API
        self.cam.set_controls({"AeEnable": True, "AwbEnable": True})
        self.preview_w, self.preview_h = self.cam.stream_configuration("lores")["size"]
        self.create_mask_images()

    def create_mask_images(self):
        self.mat_black = np.zeros((self.preview_h, self.preview_w), np.uint8)
        self.mat_white = np.zeros((self.preview_h, self.preview_w), np.uint8)
        self.mat_white[:] = (255,)
        self.mat_zebra = np.zeros((self.preview_h, self.preview_w), np.uint8)
        self.mat_zebra[:] = (255,)

        for offset in range(0, self.preview_w, 10):
            cv2.line(self.mat_zebra, (offset, 0), (offset, self.preview_h), (0, 0, 0), 3)

    def loop(self):
        self.state = self.cam.capture_metadata()
        self.api.update_state(self.cam.capture_metadata())
        self.api.do_work()

        self.edid = check_edid()
        self.draw_lcd_overlay()
        time.sleep(0.1)
        self.draw_hdmi_overlay()
        time.sleep(1)
        self.cam.capture_array()

    def set_controls(self, **kwargs):
        self.cam.set_controls(kwargs)

    def draw_lcd_overlay(self):
        draw = ImageDraw.Draw(self.dsi_overlay)
        draw.rectangle((0, 0, 720, 28), fill=(0, 0, 0, 128))
        draw.text((13, 10), f"Camera {self.edid.camera_id}", font=self.font, fill=(255, 255, 255, 255))
        self.drm.set_overlay(np.array(self.dsi_overlay), output=self.output_ui, num=2)

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

        self.drm.set_overlay(np.array(self.hdmi_overlay), output=self.output_hdmi)

    def draw_value(self, ctx, x, name, value):
        ctx.text((x, 10), name, font=self.font_heading, fill=(255, 255, 255, 255), stroke_fill=(0, 0, 0, 255),
                 stroke_width=1)
        ctx.text((x, 24), str(value), font=self.font_value, fill=(255, 255, 255, 255), stroke_fill=(0, 0, 0, 255),
                 stroke_width=1)

    def update_preview(self, request):
        with MappedArray(request, "lores") as mapped:
            grey = mapped.array[0:self.preview_h]
            if self.update_idx == 0:
                _, clipping = cv2.threshold(grey, self.thresh_zebra, 255, cv2.THRESH_BINARY)
                clip_mat = cv2.merge((self.mat_zebra, self.mat_zebra, self.mat_zebra, clipping))
                self.drm.set_overlay(clip_mat, output=self.output_ui, num=0)
                self.update_idx = 1
            elif self.update_idx == 1:
                _, mask = cv2.threshold(grey, self.thresh_under, 255, cv2.THRESH_BINARY)
                mask_inv = cv2.bitwise_not(mask)
                mat = cv2.merge((self.mat_black, self.mat_black, self.mat_white, mask_inv))
                self.drm.set_overlay(mat, output=self.output_ui, num=1)
                self.update_idx = 0


if __name__ == '__main__':
    camera = Camera()
    camera.start()

    while True:
        camera.loop()
