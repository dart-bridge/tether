import 'package:tether/tether.dart';

main() async {
  final tether = new Tether.spawnIsolate(slave);

  handler([_]) {
    tether.listen('greet', (String name) {
      return "Heeeeere's $name!";
    });
  }

  handler(await tether.onConnection);
  tether.onConnectionEstablished.listen(handler);
}

slave(ports) async {
  final tether = new Tether.connectIsolate(ports);

  handler([_]) async {
    print(await tether.send('greet', 'Johnny'));

    tether.close();
  }

  handler(await tether.onConnection);
  tether.onConnectionEstablished.listen(handler);
}