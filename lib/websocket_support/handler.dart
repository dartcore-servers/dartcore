import 'dart:io';

/// WebSocket Handler for HttpRequest
extension WebSocketHandler on HttpRequest {
  /// is WebSocket Upgrade request
  bool get isWebSocketUpgrade =>
      headers.value(HttpHeaders.connectionHeader)?.toLowerCase() == 'upgrade' &&
      headers.value(HttpHeaders.upgradeHeader)?.toLowerCase() == 'websocket';
}
