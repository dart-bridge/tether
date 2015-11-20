part of tether;

const _handshakeKey = '__handshake';
const _reconnectKey = '__reconnect';

Future<Session> _slaveHandshake(Messenger messenger, [Session reconnect]) async {
  await messenger.onOpen;
  final completer = new Completer();
  messenger.listen(_reconnectKey, completer.complete);
  messenger.listen(_handshakeKey, (Session session) {
    if (reconnect != null)
      return reconnect;
    completer.complete(session);
  });
  return completer.future;
}

Future<Session> _masterHandshake(Messenger messenger, Session session) async {
  await messenger.onOpen;
  final handshakeReturn = await messenger.send(_handshakeKey, session);
  if (handshakeReturn == null)
    return session;
  await messenger.send(_reconnectKey, handshakeReturn);
  return handshakeReturn;
}

abstract class Tether {
  /// Creates a new master [Tether] from an [Anchor].
  ///
  /// The [session] parameter receives a [Session] object for external
  /// session handling. If no [session] is provided, a new [Session]
  /// will be generated.
  ///
  /// The [reconnect] parameter can be assigned a [Reconnect] strategy
  /// for re-establishing the connection.
  factory Tether.masterAnchor(Anchor anchor,
      {Session session,
      Reconnect reconnect}) {
    final messenger = new Messenger(anchor);
    final _session = session ?? new Session.generate({});
    final tether = new _Tether(true, reconnect: reconnect);
    _masterHandshake(messenger, _session).then((session) {
      tether._connect(messenger, session);
    });
    return tether;
  }

  /// Creates a new slave [Tether] from an [Anchor].
  ///
  /// The slave will receive its [Session] from the master.
  factory Tether.slaveAnchor(Anchor anchor, {Reconnect reconnect}) {
    final messenger = new Messenger(anchor);
    final tether = new _Tether(false, reconnect: reconnect);
    _slaveHandshake(messenger).then((session) {
      tether._connect(messenger, session);
    });
    return tether;
  }

  /// Creates a new master [Tether] and spawn a new isolate, passing
  /// it the ports required to attach to the slave [Tether].
  factory Tether.spawnIsolate(void body(ports), {Session session, Reconnect reconnect}) {
    return new Tether.masterAnchor(
        new IsolateAnchor.spawn(body), session: session, reconnect: reconnect);
  }

  /// Creates a new master [Tether] and spawn an external isolate,
  /// passing it the ports required to attach the the slave.
  ///
  /// Receives [arguments] for the spawned file to receive.
  factory Tether.spawnIsolateUri(Uri uri,
      {List<String> arguments: const [], Session session, Reconnect reconnect}) {
    return new Tether.masterAnchor(
        new IsolateAnchor.spawnUri(uri, arguments), session: session, reconnect: reconnect);
  }

  /// Creates a new slave [Tether] by connecting to a master isolate,
  /// using the ports received by [Tether.spawnIsolate] or [Tether.spawnIsolateUri].
  factory Tether.connectIsolate(ports) {
    return new Tether.slaveAnchor(new IsolateAnchor.connect(ports));
  }

  /// Creates a simple master [Tether] by simply providing a [sink] and a [stream].
  factory Tether.master(Sink<String> sink, Stream<String> stream,
      {Session session, Reconnect reconnect}) {
    final anchor = new SimpleAnchor(sink, stream);
    return new Tether.masterAnchor(anchor, session: session, reconnect: reconnect);
  }

  /// Creates a simple slave [Tether] by simply providing a [sink] and a [stream].
  factory Tether.slave(Sink<String> sink, Stream<String> stream,
      {Reconnect reconnect}) {
    final anchor = new SimpleAnchor(sink, stream);
    return new Tether.slaveAnchor(anchor, reconnect: reconnect);
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

  /// Disconnect the underlying [Anchor]. Optionally reconnect.
  void disconnect({bool reconnect});

  /// The length of the timeout that the [Tether] will do before reconnecting.
  /// Note that this will only be used if a [Reconnect] was passed into the object.
  Duration reconnectTimeout;
}

/// Enables a [Tether] to support reconnection, by providing a way
/// to get a new [Messenger] using the same [Session].
typedef Future<Anchor> Reconnect();

class _Tether implements Tether {
  final StreamController _onConnect = new StreamController.broadcast();
  final StreamController _onDisconnect = new StreamController.broadcast();
  final Reconnect _reconnect;
  final bool _isMaster;
  Duration reconnectTimeout = const Duration(seconds: 10);
  Messenger _messenger;
  Session _session;
  bool _willReconnect = true;

  _Tether(this._isMaster, {Reconnect reconnect})
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
    _willReconnect = true;
    _messenger = messenger;
    _session = session;
    messenger.onOpen.then(_onConnect.add);
    messenger.onClose.then((_) => _disconnect());
  }

  void _disconnect() {
    final oldSession = _session;
    if (_reconnect != null && _willReconnect) {
      applyReconnect(anchor) async {
        final messenger = new Messenger(anchor);
        final newSession = _isMaster
            ? _masterHandshake(messenger, oldSession)
            : _slaveHandshake(messenger, oldSession);
        _connect(messenger, await newSession);
      }
      tryReconnect() async {
        try {
          applyReconnect(await _reconnect());
        } catch (e) {
          await new Future.delayed(reconnectTimeout);
          if (isConnected) return;
          tryReconnect();
        }
      }
      tryReconnect();
    }
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
  }

  void disconnect({bool reconnect: true}) {
    _willReconnect = reconnect;
    _messenger.close();
  }
}
