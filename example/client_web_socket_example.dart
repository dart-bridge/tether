import 'package:tether/http_client.dart';
import 'dart:html';

main() {
  final tether = webSocketTether('ws://localhost:1337');

  tether.onConnectionEstablished.listen((_) async {
    print('Established connection to Tether '
        '${tether.session.id.substring(0, 5)}...');

    tether.listen('fromServer', (String message) {
      querySelector('body').append(new DivElement()
        ..text = message);
    });

    tether.send('fromClient', 'Hello from client!');
  });

  querySelector('button').onClick.listen((_) {
    tether.disconnect();
  });
}