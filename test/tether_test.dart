import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/tether.dart';
import 'dart:async';
import 'package:tether/protocol.dart';

class TetherTest implements TestCase {
  Tether master;
  Tether slave;
  StreamController masterController;
  StreamController slaveController;
  StreamController reconnectSlaveController;
  StreamController reconnectMasterController;


  setUp() async {
    Messenger.serializer = new TestSerializer();
    masterController = new StreamController();
    slaveController = new StreamController();
    reconnectMasterController = new StreamController();
    reconnectSlaveController = new StreamController();
    master = new Tether.master(
        masterController,
        slaveController.stream,
        reconnect: () async {
          return new SimpleAnchor(
              reconnectMasterController,
              reconnectSlaveController.stream
          );
        });
    slave = new Tether.slave(
        slaveController,
        masterController.stream,
        reconnect: () async {
          return new SimpleAnchor(
              reconnectSlaveController,
              reconnectMasterController.stream
          );
        });
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

  @test
  it_can_reconnect() async {
    master.listen('x', (_) async {
      masterController.close();
      slaveController.close();
      await null;
    });
    slave.send('x');
    await Future.wait([
      slave.onConnectionEstablished.first,
      master.onConnectionEstablished.first
    ]);
    master.listen('y', (_) => _);
    expect(await slave.send('y', 'z'), 'z');
    expect(master.session, slave.session);
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
