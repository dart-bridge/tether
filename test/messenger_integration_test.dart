import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/protocol.dart';
import 'dart:async';

class MessengerIntegrationTest implements TestCase {
  Messenger master;
  Messenger slave;

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
    master = new Messenger(masterAnchor);
    slave = new Messenger(slaveAnchor);
  }

  tearDown() {}

  @test
  it_can_communicate() async {
    final completer = new Completer();
    master.listen('x', (payload) {
      completer.complete(payload);
    });
    slave.send('x', 'y');
    expect(await completer.future, 'y');
  }

  @test
  it_lets_the_return_value_of_listener_complete_future_of_send() async {
    master.listen('foo', (_) async {
      return 'bar';
    });
    expect(await slave.send('foo', null), 'bar');
  }

  @test
  it_can_throw_in_the_listener() async {
    master.listen('foo', (_) async {
      throw 'bar';
    });
    expect(slave.send('foo', null), throwsA('bar'));
  }
}
