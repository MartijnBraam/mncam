import multiprocessing
import threading

from picamera2.outputs import Output

from zeroconf import IPVersion, ServiceInfo, Zeroconf
import select
import socket
import struct
import time
import xml.etree.ElementTree

import xml.etree.ElementTree as ET

_zc = None


def make_service(host, name, port):
    return ServiceInfo(type_="_omt._tcp.local.", name=f"{host} ({name})._omt._tcp.local.", port=port, weight=1,
                       addresses=[socket.inet_aton("192.168.2.34")])


def announce_service(service):
    global _zc
    if _zc is None:
        _zc = Zeroconf(ip_version=IPVersion.All)

    print("Announced service", service)
    _zc.register_service(service)


def denounce_service(service):
    global _zc
    if _zc is None:
        return
    _zc.unregister_service(service)
    _zc.close()


class OMTClient:
    def __init__(self, sock, address):
        self.sock = sock
        self.address = address
        self.subscribe_video = False
        self.subscribe_audio = False
        self.subscribe_metadata = False

    def on_metadata(self, data):
        if data.tag == "OMTSubscribe":
            for a in data.attrib:
                if a == "Video":
                    self.subscribe_video = data.attrib[a] == "true"
                elif a == "Audio":
                    self.subscribe_audio = data.attrib[a] == "true"
                elif a == "Metadata":
                    self.subscribe_metadata = data.attrib[a] == "true"


class OMTSender:
    _HEADER = struct.Struct("<BBQHI")
    _EXT_VIDEO = struct.Struct("<I II II f I I")

    TYPE_METADATA = 1
    TYPE_VIDEO = 2
    TYPE_AUDIO = 4

    CODEC_VMX1 = 0x31584D56

    def __init__(self, host, name):
        self._port_start = 6400
        self._port_end = self._port_start + 200
        self.port = self._port_start

        self.host = host
        self.name = name

        self.server = None
        self.sockets = []
        self.clients = {}
        self.fq = multiprocessing.Queue()

        self.video_ext = None
        self.audio_ext = None

    def _recv(self, s, length):
        data = b''
        while len(data) < length:
            data += s.recv(length - len(data))
        return data

    def start(self):
        for port in range(self._port_start, self._port_end):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.bind(("0.0.0.0", port))
                s.listen(1)
            except OSError as e:
                if e.errno == 98:
                    continue
                raise
            print(f"Listening on port {port}")
            self.port = port
            break

        self.server = s
        self.sockets.append(s)

        fq = self.fq._reader
        self.sockets.append(fq)

        self.service = make_service(self.host, self.name, port)
        announce_service(self.service)

        while True:
            try:
                ready, _, _ = select.select(self.sockets, [], [])
            except socket.error as e:
                print(e)

            for s in ready:
                if s == self.server:
                    client_socket, client_address = s.accept()
                    print("Client connected from", client_address)
                    self.sockets.append(client_socket)
                    self.clients[client_socket] = OMTClient(client_socket, client_address)
                elif s == fq:
                    packet = self.fq.get()
                    for c in self.clients.values():
                        if c.subscribe_video:
                            c.sock.send(packet)
                else:
                    received = self._recv(s, 16)

                    version, frameType, timestamp, metalength, datalength = self._HEADER.unpack(received)

                    if metalength > 0:
                        metadata = self._recv(s, metalength)

                    dl = datalength - metalength
                    if dl > 0:
                        data = self._recv(s, dl)

                    print(f"Received {frameType} with {metalength} meta and {datalength} data")
                    if frameType == self.TYPE_METADATA:
                        try:
                            root = ET.fromstring(data.decode())
                        except xml.etree.ElementTree.ParseError as e:
                            print("Invalid XML:", e)
                            continue
                        self.clients[s].on_metadata(root)

    def set_video_data(self, codec, width, height, fps, aspect, flags, colorspace):
        self.video_ext = self._EXT_VIDEO.pack(codec, width, height, fps, 1, aspect, flags, colorspace)

    def send_video(self, encoded_frame):
        if self.video_ext is None:
            raise Exception("Video metadata not configured yet")

        packet = self._HEADER.pack(1, self.TYPE_VIDEO, time.time_ns() // 100, 0, self._EXT_VIDEO.size + len(encoded_frame))
        packet += self.video_ext
        packet += encoded_frame
        self.fq.put(packet)


class OMTOutput(Output):
    def __init__(self, pts=None):
        super().__init__(pts)
        self.sender = OMTSender("cam", "C2")
        self.sender.set_video_data(OMTSender.CODEC_VMX1, 1920, 1080, 60, 16 / 9, 0, 709)

    def start(self):
        t = threading.Thread(target=self.sender.start)
        t.daemon = True
        t.start()

    def outputframe(self, frame, keyframe=True, timestamp=None, packet=None, audio=False):
        self.sender.send_video(frame)
