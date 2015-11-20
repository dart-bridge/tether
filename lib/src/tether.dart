part of tether;

abstract class Tether {
  /// Creates a new master [Tether] from an [Anchor].
  ///
  /// The [session] parameter receives a [Session] object for external
  /// session handling. If no [session] is provided, a new [Session]
  /// will be generated.
  ///
  /// The [reconnect] parameter can be assigned a [Reconnect] strategy
  /// for re-establishing the connection. This behaviour is not yet
  /// implemented. TODO: implement Reconnect
  factory Tether.masterAnchor(Anchor anchor,
      {Session session,
      Reconnect reconnect}) {
    final messenger = new Messenger(anchor);
    final _session = session ?? new Session.generate({});
    final tether = new _Tether(reconnect: reconnect);
    messenger.onOpen.then((_) {
      messenger.send('__handshake', _session).then((_) {
        tether._connect(messenger, _session);
      });
    });
    return tether;
  }

  /// Creates a new slave [Tether] from an [Anchor].
  ///
  /// The slave will receive its [Session] from the master.
  factory Tether.slaveAnchor(Anchor anchor, {Reconnect reconnect}) {
    final messenger = new Messenger(anchor);
    final tether = new _Tether(reconnect: reconnect);
    messenger.listen('__handshake', (Session session) {
      tether._connect(messenger, session);
    });
    return tether;
  }

  /// Creates a new master [Tether] and spawn a new isolate, passing
  /// it the ports required to attach to the slave [Tether].
  factory Tether.spawnIsolate(void body(ports), {Session session}) {
    return new Tether.masterAnchor(
        new IsolateAnchor.spawn(body), session: session);
  }

  /// Creates a new master [Tether] and spawn an external isolate,
  /// passing it the ports required to attach the the slave.
  ///
  /// Receives [arguments] for the spawned file to receive.
  factory Tether.spawnIsolateUri(Uri uri,
      {List<String> arguments: const [], Session session}) {
    return new Tether.masterAnchor(
        new IsolateAnchor.spawnUri(uri, arguments), session: session);
  }

  /// Creates a new slave [Tether] by connecting to a master isolate,
  /// using the ports received by [Tether.spawnIsolate] or [Tether.spawnIsolateUri].
  factory Tether.connectIsolate(ports) {
    return new Tether.slaveAnchor(new IsolateAnchor.connect(ports));
  }

  /// Creates a simple master [Tether] by simply providing a [sink] and a [stream].
  factory Tether.master(Sink<String> sink, Stream<String> stream,
      {Session session}) {
    final anchor = new SimpleAnchor(sink, stream);
    return new Tether.masterAnchor(anchor, session: session);
  }

  /// Creates a simple slave [Tether] by simply providing a [sink] and a [stream].
  factory Tether.slave(Sink<String> sink, Stream<String> stream) {
    final anchor = new SimpleAnchor(sink, stream);
    return new Tether.slaveAnchor(anchor);
  }

  /// Sends a [payload] to the paired [Tether] with a [key]. The other side must [listen]
  /// to the same key to respond. The return value from that handler will be returned
  /// in the returned [Future] from this method.
  Future send(String key, [payload]);

  /// Semantic alias for using [send] with no payload.
  Future get(String key);

  /// Listens to a [key] on the open connection. Each time the paired [Tether] sends a
  /// payload to the same key, this [listener] will be used to react on, and respond to,
  /// that request. The return value from the [listener] will be sent back to the other
  /// side, if it's not null.
  StreamSubscription listen(String key, Function listener);

  /// The same as listening to a key and immediately cancel the subscription on
  /// the first payload.
  void listenOnce(String key, Function listener);

  /// A broadcasting stream that sends a ping each time the connection is (re-)established.
  Stream get onConnectionEstablished;

  /// A broadcasting stream that sends a ping each time the connection is lost.
  Stream get onConnectionLost;

  /// A future that completes the next time the [Tether] is connected.
  Future get onConnection;

  /// Checks if the [Tether] is connected.
  bool get isConnected;

  /// Get the unique [Session] that this is authorized with.
  Session get session;

  /// Close the [Tether] connection, as well as the underlying [Anchor].
  void close();
}

/// Enables a [Tether] to support reconnection, by providing a way
/// to get a new [Messenger] using the same [Session].
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

  Future get(String key) => send(key);

  StreamSubscription listen(String key, Function listener) {
    return _messenger.listen(key, listener);
  }

  void listenOnce(String key, Function listener) {
    StreamSubscription sub;
    sub = listen(key, ([payload]) async {
      final returnValue = await listener(payload);
      await sub.cancel();
      return returnValue;
    });
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
