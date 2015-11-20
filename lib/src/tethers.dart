part of tether;

abstract class Tethers {
  factory Tethers.empty() => new _Tethers();

  void registerHandler(handler(Tether tether));

  void add(Anchor anchor, {Session session});

  void broadcast(String key, [payload]);

  Tether get(Session session);
}

class _Tethers implements Tethers {
  final Set<Tether> _tethers = new Set<Tether>();
  final List<Function> _handlers = <Function>[];

  void registerHandler(handler(Tether tether)) {
    _handlers.add(handler);
  }

  void add(Anchor anchor, {Session session}) {
    final tether = new Tether.masterAnchor(anchor, session: session);
    _tethers.add(tether);
    tether.onConnection.then((_) async {
      _runTetherThroughHandlers(tether);
      tether.onConnectionEstablished.listen((_) {
        _tethers.add(tether);
        _runTetherThroughHandlers(tether);
      });
      tether.onConnectionLost.listen((_) => _tethers.remove(tether));
    });
  }

  void _runTetherThroughHandlers(Tether tether) {
    for (final handler in _handlers)
      handler(tether);
  }

  void broadcast(String key, [payload]) {
    _tethers
        .where((t) => t.isConnected)
        .forEach((t) => t.send(key, payload));
  }

  Tether get(Session session, {Tether orElse()}) =>
      _tethers.firstWhere((t) => t.session == session, orElse: orElse);
}
