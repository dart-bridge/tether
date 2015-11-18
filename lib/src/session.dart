part of tether.protocol;

class Session {
  final String id;
  final Map data;

  const Session(this.id, this.data);

  factory Session.generate(Map data) {
    return new Session(generateHash(length: 128), new Map.from(data));
  }
}
