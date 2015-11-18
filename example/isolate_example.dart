import 'package:tether/protocol.dart';
import 'package:tether/tether.dart';
import 'dart:async';

main() async {
  // 1. Create master tether
  final tether = new Tether.master(new IsolateAnchor.spawn(slave));

  // 2. Wait for connection
  await tether.onConnection;

  // 3. Use the tether
  tether.listen('greet', (String name) {
    return "Heeeeere's $name!";
  });
}

slave(ports) async {
  // 1. Create master tether
  final tether = new Tether.slave(new IsolateAnchor.connect(ports));

  // 2. Wait for connection
  await tether.onConnection;

  // 3. Use the tether
  print(await tether.send('greet', 'Johnny'));

  // 4. Isolate slave tethers need to be explicitly destroyed
  tether.close();
}