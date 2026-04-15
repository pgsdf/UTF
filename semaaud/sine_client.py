import math
import os
import socket
import struct

SOCKET_PATH = os.environ.get("SEMAUD_SOCKET", "/tmp/semaud-default.sock")
SAMPLE_RATE = 48000
CHANNELS = 2
DURATION_SECONDS = 10.0
FREQUENCY_HZ = 440.0
AMPLITUDE = 0.25

frame_count = int(SAMPLE_RATE * DURATION_SECONDS)

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(SOCKET_PATH)
header = b'{"type":"pcm_stream_begin","sample_rate":48000,"channels":2,"sample_format":"s16le"}\n'
sock.sendall(header)

pcm = bytearray()
for n in range(frame_count):
    sample = math.sin(2.0 * math.pi * FREQUENCY_HZ * (n / SAMPLE_RATE))
    value = int(sample * AMPLITUDE * 32767.0)
    pcm += struct.pack("<hh", value, value)

sock.sendall(pcm)
sock.close()
