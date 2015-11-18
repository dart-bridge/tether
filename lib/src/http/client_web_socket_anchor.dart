part of tether.http.client;

class ServerWebSocketAnchor extends SocketAnchor {
  final WebSocket _socket;

  ServerWebSocketAnchor(this._socket) : super();

  void close() {
    _socket.close();
  }

  bool get isOpen => _socket.readyState == WebSocket.OPEN;

  Future get onClose => _socket.onClose.first;

  Future get onOpen async => null;

  void send(String payload) {
    _socket.send(payload);
  }

  Stream<String> get stream {
    return _socket.onMessage.map((m) => m.data);
  }
}
