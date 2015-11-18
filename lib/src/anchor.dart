part of tether.protocol;

abstract class Anchor {
  Sink<String> get sink;

  Stream<String> get stream;

  Future get onOpen;

  Future get onClose;

  bool get isOpen;

  void close();
}
