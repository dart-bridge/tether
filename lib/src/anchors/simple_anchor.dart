part of tether.protocol;

class SimpleAnchor implements Anchor {
  final Sink<String> _sink;
  final Stream<String> _stream;
  final StreamController<String> _controller = new StreamController();

  SimpleAnchor(this._sink, this._stream) {
    _listen();
  }

  Future _listen() async {
    await for (final payload in _stream)
        _controller.add(payload);
    await _controller.close();
  }

  Sink<String> get sink => _sink;

  Stream<String> get stream => _controller.stream;

  bool get isOpen => _controller.isClosed;

  Future get onClose async => new Completer().future;

  Future get onOpen async => null;

  void close() {
    _sink.close();
  }
}
