library tether.http.client;

import 'dart:async';
import 'dart:html';

import 'package:tether/tether.dart';

import 'src/http/util.dart';

part 'src/http/client_web_socket_anchor.dart';

Tether webSocketTether(String url) {
  return new Tether.slaveAnchor(new ServerWebSocketAnchor(new WebSocket(url)));
}
