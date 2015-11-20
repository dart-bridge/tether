import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:tether/tether.dart';
import 'dart:async';
import 'package:tether/protocol.dart';

class TethersTest implements TestCase {
  Tethers tethers;

  setUp() {
    tethers = new Tethers.empty();
  }

  tearDown() {}

  Future createTethers(
      {master(Tether tether),
      slave(Tether tether)}) async {
    final onHandlerCompletion = new Completer();

    tethers.registerHandler((tether) async {
      await master?.call(tether);
      onHandlerCompletion.complete();
    });

    final masterController = new StreamController();
    final slaveController = new StreamController();
    final masterAnchor = new SimpleAnchor(masterController, slaveController.stream);
    tethers.add(masterAnchor);
    final slaveAnchor = new SimpleAnchor(
        slaveController, masterController.stream);
    final slaveTether = new Tether.slaveAnchor(slaveAnchor);
    await slaveTether.onConnection;
    await onHandlerCompletion.future;
    await slave?.call(slaveTether);
  }

  @test
  it_contains_handlers_for_new_tethers() async {
    await createTethers(
        master: (tether) {
          tether.listen('x', (_) => 'y');
        },
        slave: (tether) async {
          expect(await tether.send('x'), 'y');
        }
    );
  }

  @test
  it_can_broadcast_to_all_tethers() async {
    final completer = new Completer();

    await createTethers(
        slave: (tether) async {
          tether.listen('x', (_) {
            completer.complete();
          });
        }
    );

    tethers.broadcast('x');

    await completer.future;
  }
}
