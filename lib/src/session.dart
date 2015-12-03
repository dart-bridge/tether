part of tether.protocol;

typedef Session SessionFactory(String id, Map data);

abstract class Session {
  final String id;
  Map data;

  static SessionFactory factory = (String id, Map data) => new _Session(id, data);

  factory Session(String id, Map data) => factory(id, data);

  factory Session.generate(Map data) {
    return factory(generateHash(length: 128), new Map.from(data));
  }
}

class _Session implements Session {
  final String id;
  Map data;

  _Session(this.id, this.data);

  operator ==(Session other) => other is Session && other.id == id;
}
