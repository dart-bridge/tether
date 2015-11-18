part of tether.protocol;

class SimpleAnchor implements Anchor {
  final Sink<String> _sink;
  final Stream<String> _stream;

  SimpleAnchor(this._sink, this._stream);

  Sink<String> get sink => _sink;

  Stream<String> get stream => _stream;

  bool get isOpen => true;

  Future get onClose async => new Completer().future;

  Future get onOpen async => null;

  void close() {
    _sink.close();
  }
}
