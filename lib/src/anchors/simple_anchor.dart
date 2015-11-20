part of tether.protocol;

class SimpleAnchor implements Anchor {
  final Sink<String> _sink;
  final Stream<String> _stream;
  final StreamController<String> _controller = new StreamController();
  final Completer _onOpen = new Completer();
  final Completer _onClose = new Completer();

  SimpleAnchor(this._sink, this._stream) {
    _listen();
  }

  Future _listen() async {
    _onOpen.complete();
    await for (final payload in _stream)
        _controller.add(payload);
    await _controller.close();
    _onClose.complete();
  }

  Sink<String> get sink => _sink;

  Stream<String> get stream => _controller.stream;

  bool get isOpen => !_controller.isClosed;

  Future get onClose async => _onClose.future;

  Future get onOpen async => _onOpen.future;

  void close() {
    _sink.close();
  }
}
