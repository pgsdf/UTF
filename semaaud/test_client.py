import os
import socket

SOCKET_PATH = os.environ.get("SEMAUD_SOCKET", "/tmp/semaud-default.sock")

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(SOCKET_PATH)
header = b'{"type":"pcm_stream_begin","sample_rate":48000,"channels":2,"sample_format":"s16le"}\n'
sock.sendall(header)
sock.sendall(os.urandom(16384))
sock.close()
