part of tether.protocol;

class Messenger {
  static Serializer serializer;

  final Map<String, StreamController<Message>> _listeners = {};
  final Anchor _anchor;

  Messenger(this._anchor) {
    _anchor.stream
        .map((s) => new Message.deserialize(s))
        .listen((Message message) {
      if (hasListener(message.key)) {
        final controller = _listeners[message.key];
        if (message.isError)
          controller.addError(message);
        else controller.add(message);
      }
    });
  }

  Object serialize(Object object) {
    if (object is Session)
      return {
        'isSession': true,
        'id': object.id,
        'data': serialize(object.data),
      };
    return serializer?.serialize(object) ?? object;
  }

  Object deserialize(Object object) {
    if (object is Map && (object['isSession'] ?? false))
      return new Session(object['id'], deserialize(object['data']));
    return serializer?.deserialize(object) ?? object;
  }

  Future send(String key, payload) {
    final returnValue = new Completer();
    final message = new Message(key, serialize(payload));
    final returnSub = listen(message.returnKey, returnValue.complete);
    returnSub.onError((Message message) {
      returnValue.completeError(message.payload);
    });
    _anchor.sink.add(message.serialize());
    return returnValue.future.then((_) async {
      await returnSub.cancel();
      return _;
    });
  }

  void _send(String key, payload, {bool isError: false}) {
    final message = new Message(key, serialize(payload), isError: isError);
    _anchor.sink.add(message.serialize());
  }

  void sendError(String key, error) {
    _send(key, error, isError: true);
  }

  StreamSubscription<Message> listen(String key,
      handler(payload)) {
    if (hasListener(key))
      throw new StateError('Tether is already listening to key $key');

    final controller = new StreamController<Message>(onCancel: () {
      _listeners.remove(key);
    });
    _listeners[key] = controller;
    return controller.stream.listen((message) async {
      final payload = deserialize(message.payload);
      try {
        final returnValue = await handler(payload);
        if (message.hasReturnKey)
          _send(message.returnKey, returnValue);
      } catch (error) {
        if (message.hasReturnKey)
          sendError(message.returnKey, error);
      }
    });
  }

  bool hasListener(String key) => _listeners.containsKey(key);

  Future get onOpen => _anchor.onOpen;

  Future get onClose => _anchor.onClose;

  bool get isOpen => _anchor.isOpen;

  void close() {
    _listeners.values.forEach((c) => c.close());
    _anchor.sink.close();
    _anchor.close();
  }
}
