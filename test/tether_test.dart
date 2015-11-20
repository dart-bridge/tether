import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/tether.dart';
import 'dart:async';
import 'package:tether/protocol.dart';

class TetherTest implements TestCase {
  Tether master;
  Tether slave;

  setUp() async {
    Messenger.serializer = new TestSerializer();
    final masterController = new StreamController();
    final slaveController = new StreamController();
    master = new Tether.master(masterController, slaveController.stream);
    slave = new Tether.slave(slaveController, masterController.stream);
    await Future.wait([
      master.onConnection,
      slave.onConnection
    ]);
  }

  tearDown() {}

  @test
  it_can_communicate() async {
    master.listen('x', (String message) async {
      expect(message, 'y');
      return 'z';
    });
    expect(await slave.send('x', 'y'), 'z');
  }

  @test
  it_can_listen_once() async {
    master.listenOnce('x', (m) => m);
    expect(await slave.send('x', 'y'), 'y');
    master.listenOnce('x', (m) => '_$m');
    expect(await slave.send('x', 'z'), '_z');
  }

  @test
  it_can_throw_exceptions() async {
    master.listen('x', (_) {
      throw new TestException();
    });
    expect(slave.send('x'), throwsA(new isInstanceOf<TestException>()));
  }
}

class TestException implements Exception {}

class TestSerializer implements Serializer {
  Object deserialize(Object object) {
    if (object == '__testException')
      return new TestException();
    return object;
  }

  Object serialize(Object object) {
    if (object is TestException)
      return '__testException';
    return object;
  }
}
