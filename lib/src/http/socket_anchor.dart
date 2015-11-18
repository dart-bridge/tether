part of tether.http.util;

abstract class SocketAnchor implements Anchor {
  final StreamController<String> _controller = new StreamController<String>();

  SocketAnchor() {
    _controller.stream.listen(send);
  }

  void close();

  void send(String payload);

  bool get isOpen;

  Future get onClose;

  Future get onOpen;

  Sink<String> get sink => _controller;

  Stream<String> get stream;
}
