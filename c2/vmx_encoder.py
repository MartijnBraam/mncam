import ctypes

from picamera2 import MappedArray
from picamera2.encoders import MultiEncoder
from ctypes import *


class VMXSize(Structure):
    _fields_ = ("width", c_int), ("height", c_int)


class VMXEncoder(MultiEncoder):
    def __init__(self):
        super().__init__()

        self.vmx = cdll.LoadLibrary("libvmx.so")
        self.vmx.VMX_Create.restype = POINTER(c_void_p)
        self.encoder = self.vmx.VMX_Create(VMXSize(width=1920, height=1080), 133, 709)
        self.vmx.VMX_SaveTo.argtypes = c_void_p, c_void_p, c_int

        self.vmx.VMX_EncodeBGRA.argtypes = c_void_p, c_void_p, c_int, c_int
        # Instance, srcY, strideY, srcU, strideU, srcV, strideV, interlaced
        self.vmx.VMX_EncodeYV12.argtypes = c_void_p, POINTER(c_byte), c_int, POINTER(c_byte), c_int, POINTER(
            c_byte), c_int
        self.vmx.VMX_EncodeYV12.restype = c_uint32

        self.dest = bytes(bytearray(1920 * 1080 * 4))

    def encode_func(self, request, name):
        fmt = request.config[name]["format"]
        with MappedArray(request, name) as m:
            if fmt == "YUV420":
                width, height = request.config[name]['size']
                Y = m.array[:height, :width].ctypes.data_as(POINTER(c_byte))
                reshaped = m.array.reshape((m.array.shape[0] * 2, m.array.strides[0] // 2))
                U = reshaped[2 * height: 2 * height + height // 2, :width // 2].ctypes.data_as(POINTER(c_byte))
                V = reshaped[2 * height + height // 2:, :width // 2].ctypes.data_as(POINTER(c_byte))
                res = self.vmx.VMX_EncodeYV12(self.encoder, Y, width, U, width // 2,
                                              V, width // 2, 0)
                size = self.vmx.VMX_SaveTo(self.encoder, self.dest, width * height * 4)
                print(size)
                return self.dest[:size]
