import 'package:dartcore/dartcore.dart';
import 'dart:convert';
import 'dart:io';

/// logs
final List<Map<String, dynamic>> logs = [];

/// Debug sockets
final List<WebSocket> debugSockets = [];

/// Debugging middleware
Middleware debugMiddleware({int maxLogs = 100}) {
  return (HttpRequest request, Function next) async {
    final stopwatch = Stopwatch()..start();

    try {
      final requestLog = {
        'method': request.method,
        'uri': request.uri.toString(),
        'headers': request.headers,
        'body': await _readRequestBody(request),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await next();

      stopwatch.stop();

      requestLog['responseTimeMs'] = stopwatch.elapsedMilliseconds;

      logs.add(requestLog);

      if (logs.length > maxLogs) logs.removeAt(0);
    } catch (e, stackTrace) {
      logs.add({
        'method': request.method,
        'uri': request.uri.toString(),
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  };
}

Future<String> _readRequestBody(HttpRequest request) async {
  try {
    return await utf8.decoder.bind(request).join();
  } catch (_) {
    return 'Unable to read body';
  }
}

/// Enables debug dashboard
void enableDashboard(App app) {
  app.use(debugMiddleware());
  app.use(websocketDebugMiddleware());
  app.route("GET", "/debug/logs", (req, res) async {
    res.send(jsonEncode(logs), ContentType.json);
  });

  app.route("GET", "/debug", (req, res) async {
    res.html(
      '<html><head><title>Debug Dashboard</title></head><body><h1>Debug Logs</h1><div id="logs"></div><script src="/debug/app.js"></script></body></html>',
    );
  });

  app.route("GET", "/debug/app.js", (req, res) async {
    res.send('''
    const logsContainer = document.getElementById('logs');
    async function fetchLogs() {
      const response = await fetch('/debug/logs');
      const logs = await response.json();
      logsContainer.innerHTML = logs.map(log => `
        <div>
          <strong>\${log.method}</strong> \${log.uri}<br>
          Time: \${log.timestamp}<br>
          Response Time: \${log.responseTimeMs || 'Error'}
        </div>
      `).join('<hr>');
    }
    setInterval(fetchLogs, 2000);
    ''', ContentType("application", "javascript"));
  });
  app.route("GET", "/debug/ws", (req, res) async {
    final socket = await WebSocketTransformer.upgrade(req);
    debugSockets.add(socket);
    socket.add(jsonEncode(logs));
  });
}

/// Websocket debug middleware
Middleware websocketDebugMiddleware() {
  return (HttpRequest request, Function next) async {
    await next();
    for (final socket in debugSockets) {
      if (socket.readyState == WebSocket.open) {
        socket.add(jsonEncode(logs.last));
      }
    }
  };
}
