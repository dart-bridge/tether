library tether.http.server;

import 'dart:async';
import 'dart:io';

import 'package:tether/tether.dart';

import 'src/http/util.dart';

part 'src/http/server_web_socket_anchor.dart';

Tether webSocketTether(HttpRequest request) {
  if (!WebSocketTransformer.isUpgradeRequest(request))
    throw new Exception(
        'The HttpRequest is not a valid WebSocket upgrade request');

  final socket = WebSocketTransformer.upgrade(request);

  return new Tether.masterAnchor(new ServerWebSocketAnchor(socket));
}

Tether webSocketClientTether(String url) {
  final socket = WebSocket.connect(url);
  return new Tether.slaveAnchor(new ServerWebSocketAnchor(socket));
}
