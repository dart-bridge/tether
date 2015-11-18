import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/tether.dart';
import 'package:tether/protocol.dart';
import 'dart:async';

class TetherTest implements TestCase {
  Tether master;
  Tether slave;

  setUp() async {
    final masterController = new StreamController();
    final slaveController = new StreamController();
    final masterAnchor = new SimpleAnchor(
        masterController,
        slaveController.stream
    );
    final slaveAnchor = new SimpleAnchor(
        slaveController,
        masterController.stream
    );
    master = new Tether.master(masterAnchor);
    slave = new Tether.slave(slaveAnchor);
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
}
