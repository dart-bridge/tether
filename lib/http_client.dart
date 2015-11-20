library tether.http.client;

import 'dart:async';
import 'dart:html';

import 'package:tether/tether.dart';

import 'src/http/util.dart';

part 'src/http/client_web_socket_anchor.dart';

Tether webSocketTether(String url) {
  anchor(s) => new ClientWebSocketAnchor(s);
  return new Tether.slaveAnchor(anchor(new WebSocket(url)),
      reconnect: () async {
        final socket = new WebSocket(url);
        final completer = new Completer<WebSocket>();
        socket.onError.first.then((_) {
          if (!completer.isCompleted)
            completer.completeError(_);
        });
        socket.onOpen.first.then((_) {
          if (!completer.isCompleted)
            completer.complete(socket);
        });
    return anchor(await completer.future);
  });
}
