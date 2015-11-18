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

_initTether(HttpRequest request) async {
  final tether = webSocketTether(request);

  await tether.onConnection;

  tether.listen('fromClient', print);

  tether.send('fromServer', 'Hello from server!');
}
