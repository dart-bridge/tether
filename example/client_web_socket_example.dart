import 'package:tether/tether.dart';
import 'package:tether/http_client.dart';
import 'dart:html';

main() async {
  final tether = webSocketTether('ws://localhost:1337');

  await tether.onConnection;
  tether.listen('fromServer', (String message) {
    querySelector('body').append(new DivElement()
      ..text = message);
  });

  tether.send('fromClient', 'Hello from client!');
}