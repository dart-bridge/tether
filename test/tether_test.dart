import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/tether.dart';
import 'dart:async';

class TetherTest implements TestCase {
  Tether master;
  Tether slave;

  setUp() async {
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
}
