import 'dart:io';
import 'package:tether/http_server.dart';

main() async {
  final server = await HttpServer.bind('localhost', 1337);
  final clientScript = await new File('example/client_web_socket_example.dart').readAsString();

  await for (final HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      _initTether(request);
      continue;
    }

    final static = new File('example/${request.uri.pathSegments.join('/')}');
    if (await static.exists()) {
      request.response.headers.set('Content-Type', 'application/dart');
      request.response.write(await static.readAsString());
      request.response.close();
      continue;
    }

    request.response.headers.set('Content-Type', 'text/html');
    request.response.write('''
      <!DOCTYPE html>
      <html>
        <head>
          <button>Disconnect and reconnect</button>
          <script type='application/dart'>
            $clientScript
          </script>
        </head>
        <body></body>
      </html>
    ''');
    request.response.close();
  }
}

_initTether(HttpRequest request) {
  final tether = webSocketTether(request);

  tether.onConnectionEstablished.listen((_) async {
    print('Established connection to Tether ${tether.session.id.substring(0, 5)}...');

    tether.listen('fromClient', print);

    tether.send('fromServer', 'Hello from server!');
  });
}
