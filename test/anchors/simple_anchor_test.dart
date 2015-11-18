import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/protocol.dart';
import 'dart:async';

class SimpleAnchorTest implements TestCase {
  SimpleAnchor masterAnchor;
  SimpleAnchor slaveAnchor;

  setUp() {
    final masterController = new StreamController<String>();
    final slaveController = new StreamController<String>();
    masterAnchor = new SimpleAnchor(
        masterController,
        slaveController.stream
    );
    slaveAnchor = new SimpleAnchor(
        slaveController,
        masterController.stream
    );
  }

  tearDown() {}

  @test
  it_can_communicate() async {
    masterAnchor.sink.add('x');
    expect(await slaveAnchor.stream.first, 'x');
    slaveAnchor.sink.add('y');
    expect(await masterAnchor.stream.first, 'y');
  }
}
