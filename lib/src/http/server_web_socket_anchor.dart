part of tether.http.server;

class ServerWebSocketAnchor extends SocketAnchor {
  WebSocket _socket;
  final Completer _onOpen = new Completer();
  final Completer _onClose = new Completer();
  final StreamController<String> _controller = new StreamController<String>();

  ServerWebSocketAnchor(Future<WebSocket> socket) : super() {
    socket.then((socket) async{
      _socket = socket;
      while (!isOpen) await null;
      _onOpen.complete();
      _listen();
    });
  }

  Future _listen() async {
    await for (final payload in _socket)
      _controller.add(payload);
    _onClose.complete();
  }

  void close() {
    _socket?.close();
  }

  bool get isOpen => _socket?.readyState == WebSocket.OPEN;

  Future get onClose => _onClose.future;

  Future get onOpen => _onOpen.future;

  void send(String payload) {
    _socket?.add(payload);
  }

  Stream<String> get stream => _controller.stream;
}
