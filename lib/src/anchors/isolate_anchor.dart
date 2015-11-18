part of tether.protocol;

typedef Future<Isolate> _IsolateGenerator(Map<String, SendPort> ports, SendPort onExit);

class IsolateAnchor implements Anchor {
  final ReceivePort _receiver;
  _IsolateSink _sink;
  final Completer _onOpen = new Completer();
  final Completer _onClose = new Completer();
  bool _isOpen = false;

  IsolateAnchor._(this._receiver);

  factory IsolateAnchor.spawn(void body(Map<String, SendPort> ports)) {
    return _spawn((ports, onExit) {
      return Isolate.spawn(body, ports, onExit: onExit);
    });
  }

  factory IsolateAnchor.spawnUri(Uri uri, List<String> arguments) {
    return _spawn((ports, onExit) {
      return Isolate.spawnUri(uri, arguments, ports, onExit: onExit);
    });
  }

  static IsolateAnchor _spawn(_IsolateGenerator generator) {
    final onData = new ReceivePort();
    final onClose = new ReceivePort();
    final onExit = new ReceivePort();
    final expectsTransmitters = new ReceivePort();
    final ports = <String, SendPort>{
      'transmitter': onData.sendPort,
      'closePort': onClose.sendPort,
      'expectsTransmitters': expectsTransmitters.sendPort,
    };
    final anchor = new IsolateAnchor._(onData);
    SendPort closePort;
    tearDown(_) {
      onData.close();
      onExit.close();
      onClose.close();
      closePort?.send(1);
      anchor._close();
    }
    onClose.first.then(tearDown);
    onExit.listen(tearDown);
    expectsTransmitters.first
        .then((Map<String, SendPort> transmitters) {
      anchor._open(
          transmitters['transmitter'],
          closePort = transmitters['closePort']
      );
      expectsTransmitters.close();
    });
    generator(ports, onExit.sendPort);
    return anchor;
  }

  factory IsolateAnchor.connect(Map<String, SendPort> ports) {
    final SendPort transmitter = ports['transmitter'];
    final SendPort closePort = ports['closePort'];
    final SendPort expectsTransmitters = ports['expectsTransmitters'];
    final onData = new ReceivePort();
    final onClose = new ReceivePort();
    expectsTransmitters.send({
      'transmitter': onData.sendPort,
      'closePort': onClose.sendPort,
    });

    final anchor = new IsolateAnchor._(onData)
      .._open(transmitter, closePort);

    tearDown(_) {
      onData.close();
      onClose.close();
      closePort.send(1);
      anchor._close();
    }
    onClose.first.then(tearDown);

    return anchor;
  }

  void _open(SendPort transmitter, SendPort closePort) {
    _sink = new _IsolateSink(transmitter, closePort, _close);
    _isOpen = true;
    _onOpen.complete();
  }

  void _close() {
    if (!_onClose.isCompleted)
      _onClose.complete();
  }

  Sink<String> get sink => _sink;

  Stream<String> get stream => _receiver;

  bool get isOpen => _isOpen;

  Future get onClose => _onClose.future.then((_) {
    _isOpen = false;
  });

  Future get onOpen => _onOpen.future;

  void close() {
    sink.close();
  }
}

class _IsolateSink implements Sink<String> {
  final SendPort _transmitter;
  final SendPort _closePort;
  final Function _onClose;

  _IsolateSink(this._transmitter, this._closePort, this._onClose);

  void add(String data) {
    _transmitter.send(data);
  }

  void close() {
    _onClose();
    _closePort.send(0);
  }
}
