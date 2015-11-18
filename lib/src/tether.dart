part of tether;

abstract class Tether {
  factory Tether.master(
      Anchor anchor,
      {Map sessionData: const {},
      Reconnect reconnect}) {
    final messenger = new Messenger(anchor);
    final session = new Session.generate(new Map.from(sessionData));
    final tether = new _Tether(reconnect: reconnect);
    messenger.onOpen.then((_) {
      messenger.send('__handshake', session).then((_) {
        tether._connect(messenger, session);
      });
    });
    return tether;
  }

  factory Tether.slave(Anchor anchor, {Reconnect reconnect}) {
    final messenger = new Messenger(anchor);
    final tether = new _Tether(reconnect: reconnect);
    messenger.listen('__handshake', (Session session) {
      tether._connect(messenger, session);
    });
    return tether;
  }

  Future send(String key, [payload]);

  StreamSubscription listen(String key, Function listener);

  Stream get onConnectionEstablished;

  Stream get onConnectionLost;

  Future get onConnection;

  bool get isConnected;

  Session get session;

  void close();
}

typedef Future<Messenger> Reconnect(Session session);

class _Tether implements Tether {
  final StreamController _onConnect = new StreamController.broadcast();
  final StreamController _onDisconnect = new StreamController.broadcast();
  final Reconnect _reconnect;
  Messenger _messenger;
  Session _session;

  _Tether({Reconnect reconnect})
      : _reconnect = reconnect;

  Future send(String key, [payload]) {
    return _messenger.send(key, payload);
  }

  StreamSubscription listen(String key, Function listener) {
    return _messenger.listen(key, listener);
  }

  void _connect(Messenger messenger, Session session) {
    _messenger = messenger;
    _session = session;
    messenger.onOpen.then(_onConnect.add);
    messenger.onClose.then((_) => _disconnect());
  }

  void _disconnect({bool noReconnect: false}) {
    final oldSession = _session;
    if (_reconnect != null)
      _reconnect(oldSession).then((m) => _connect(m, oldSession));
    _onDisconnect.add(null);
    _messenger = null;
    _session = null;
  }

  Stream get onConnectionEstablished => _onConnect.stream;

  Stream get onConnectionLost => _onDisconnect.stream;

  bool get isConnected => _messenger?.isOpen ?? false;

  Future get onConnection async {
    if (isConnected) return;
    await onConnectionEstablished.first;
  }

  Session get session => _session;

  void close() {
    _messenger.close();
    _disconnect(noReconnect: true);
  }
}
