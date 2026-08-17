import glob
import os.path
import subprocess


class UVCGadget:
    def __init__(self):
        self.setup_kernel()

    def setup_kernel(self):
        self._load_module('libcomposite')
        gadgetfs = "/sys/kernel/config/usb_gadget"
        udcs = glob.glob("/sys/class/udc/*")
        if len(udcs) == 0:
            print("No UDC available for UVC gadget")
            return

        if not os.path.isdir(os.path.join(gadgetfs, "g1")):
            os.mkdir(os.path.join(gadgetfs, "g1"))

        self._sysfs_put("idVendor", "0x0525")
        self._sysfs_put("idProduct", "0xa4a2")
        os.makedirs(os.path.join(gadgetfs, "g1/strings/0x409"), exist_ok=True)
        self._sysfs_put("strings/0x409/manufacturer", "FOSDEM")
        self._sysfs_put("strings/0x409/product", "ConfCam")

        os.makedirs(os.path.join(gadgetfs, "g1/configs/c.1"), exist_ok=True)
        os.makedirs(os.path.join(gadgetfs, "g1/configs/c.1/strings/0x409"), exist_ok=True)

        self._create_uvc_gadget("c.1", "uvc.0")
        self._sysfs_put("UDC", os.path.basename(udcs[0]))

    def _load_module(self, name):
        mods = subprocess.run(['lsmod'], capture_output=True, text=True)
        for line in mods.stdout.splitlines():
            part = line.split()
            if part[0] == name:
                print(f"Module {name} is already loaded")
                break
        else:
            print("Loading kernel module", name)
            subprocess.run(['modprobe', name])

    def _sysfs_put(self, path, value):
        if not path.startswith("/"):
            p = os.path.join("/sys/kernel/config/usb_gadget/g1", path)
        else:
            p = path
        with open(p, "w") as f:
            f.write(str(value))

    def _create_uvc_gadget(self, config, function):
        gadget = "/sys/kernel/config/usb_gadget/g1"
        cp = os.path.join(gadget, "config", config)
        fd = os.path.join(gadget, "functions", function)

        os.makedirs(fd, exist_ok=True)
        self._create_format(function, "uncompressed", "u", 1920, 1080, 30)

        os.makedirs(os.path.join(fd, "streaming/header/h"), exist_ok=True)
        self._link(os.path.join(fd, "streaming/header/h"), os.path.join(fd, "streaming/uncompressed/u"))

        os.makedirs(os.path.join(fd, "streaming/class/fs"), exist_ok=True)
        self._link(os.path.join(fd, "streaming/class/fs"), os.path.join(fd, "header/h"))

        os.makedirs(os.path.join(fd, "streaming/class/hs"), exist_ok=True)
        self._link(os.path.join(fd, "streaming/class/hs"), os.path.join(fd, "header/h"))

        os.makedirs(os.path.join(fd, "streaming/class/ss"), exist_ok=True)
        self._link(os.path.join(fd, "streaming/class/ss"), os.path.join(fd, "header/h"))

        os.makedirs(os.path.join(fd, "control/header/h"), exist_ok=True)
        self._link(os.path.join(fd, "control/header/h"), os.path.join(fd, "control/class/fs"))
        self._link(os.path.join(fd, "control/header/h"), os.path.join(fd, "control/class/ss"))

        self._sysfs_put(os.path.join(fd, "streaming_maxpacket"), 2048)

        self._link(fd, cp)

    def _create_format(self, function, fmt, name, width, height, fps):
        gadget = "/sys/kernel/config/usb_gadget/g1"
        function = os.path.join(gadget, "functions", function)
        fd = os.path.join(function, "streaming", fmt, name, f"{height}p")
        print("make", fd)
        os.makedirs(fd, exist_ok=True)

        self._sysfs_put(os.path.join(fd, "wWidth"), width)
        self._sysfs_put(os.path.join(fd, "wHeight"), height)
        self._sysfs_put(os.path.join(fd, "dwMaxVideoFrameBufferSize"), width * height * 2)
        self._sysfs_put(os.path.join(fd, "dwFrameInterval"), fps)
        
    def _link(self, source, dest):
        if not os.path.exists(source):
            os.symlink(source, dest)
