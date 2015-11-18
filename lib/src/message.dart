part of tether.protocol;

class Message {
  static const protocol = '1.0';
  final String key;
  final payload;
  final bool isError;
  String _returnKey;

  String get returnKey => _returnKey ??= _generateKey();

  bool get hasReturnKey => _returnKey != null;

  String _generateKey() {
    return '${key}_return_${generateHash()}';
  }

  Message(this.key, this.payload, {returnKey, isError})
      : isError = isError ?? false,
        _returnKey = returnKey;

  factory Message.deserialize(String serialized) {
    Map map = JSON.decode(serialized);
    if (map['protocol'] != protocol)
      print('WARNING: Communicating with a Tether of '
          'different protocol version! '
          'Theirs: ${map['protocol']} '
          'Yours: ${protocol}');
    return new Message(
        map['key'],
        map['payload'],
        returnKey: map['returnKey'],
        isError: map['isError']
    );
  }

  String serialize() {
    return JSON.encode({
      'protocol': protocol,
      'key': key,
      'payload': payload,
      'returnKey': _returnKey,
      'isError': isError,
    });
  }
}

