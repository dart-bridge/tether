import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/protocol.dart';
import 'dart:async';
import 'dart:convert';

class MessengerTest implements TestCase {
  Messenger messenger;
  SpyAnchor anchor;

  setUp() {
    anchor = new SpyAnchor();
    messenger = new Messenger(anchor);
  }

  tearDown() {}

  Future waitForWhen(bool condition()) async {
    while (!condition())
      await null;
  }

  @test
  it_can_send_a_payload() async {
    messenger.send('x', 'y');
    await waitForWhen(() => anchor.log.length > 0);
    expect(anchor.log[0]['payload'], 'y');
  }

  @test
  it_can_listen_for_a_payload() async {
    final completer = new Completer();
    final sub = messenger.listen('x', (payload) {
      completer.complete(payload);
    });
    anchor.send({
      'protocol': Message.protocol,
      'key': 'x',
      'payload': 'y',
    });
    expect(await completer.future, 'y');
    await sub.cancel();
  }

  @test
  it_can_listen_for_same_key_again_only_if_cancelled() async {
    final h = (_) => null;
    final sub = messenger.listen('x', h);
    expect(() => messenger.listen('x', h), throwsA(new isInstanceOf<StateError>()));
    await sub.cancel();
    final sub2 = messenger.listen('x', h);
    await sub2.cancel();
  }
}

class SpyAnchor implements Anchor {
  final StreamController<String> _send = new StreamController<String>();
  final StreamController<String> _receive = new StreamController<String>();
  final List<Map> _log = <Map>[];

  SpyAnchor() {
    _receive.stream
        .map(JSON.decode)
        .listen(_log.add);
  }

  bool get isOpen => true;

  Future get onClose async => new Completer().future;

  Future get onOpen async => null;

  Sink<String> get sink => _receive;

  Stream<String> get stream => _send.stream;

  void send(Map payload) {
    _send.add(JSON.encode(payload));
  }

  List<Map> get log => _log;

  void close() {}
}
