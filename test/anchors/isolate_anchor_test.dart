import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/protocol.dart';
import 'dart:isolate';
import 'dart:async';

class IsolateAnchorTest implements TestCase {
  IsolateAnchor anchor;

  setUp() async {
    anchor = new IsolateAnchor.spawn(slave);
    await anchor.onOpen;
  }

  tearDown() {}

  @test
  it_can_communicate() async {
    final completer = new Completer();
    anchor.stream.first.then(completer.complete);
    anchor.sink.add('x');
    expect(await completer.future, 'x');
  }
}

void slave(Map<String, SendPort> ports) {
  final anchor = new IsolateAnchor.connect(ports);
  anchor.stream.first.then((message) {
    anchor.sink.add(message);
  });
}