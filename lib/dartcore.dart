import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';

/// dotcore's version
const version = '0.0.3';

/// Defines Handler type
typedef Handler = Future<void> Function(HttpRequest request);

/// Defines Middleware type
typedef Middleware = Future<void> Function(HttpRequest request, Function next);

void main() {} // for WASM compatibility

/// dotcore App class for routing and handling HTTP requests
class App {
  final Map<String, Map<String, Handler>> _routes = {};
  final List<Middleware> _middlewares = [];
  late Function(HttpRequest request)? _custom404;
  late Function(HttpRequest request, Object error)? _custom500;

  final Map<String, int> _requestCounts = {};
  int _maxRequestsPerMinute = 60;
  // final Duration _rateLimitDuration = Duration(minutes: 1);              // TODO

  /// Adds a new route for the HTTP server
  void route(String method, String path, Handler handler) {
    _routes.putIfAbsent(method, () => {})[path] = handler;
  }

  /// Uses a middleware (A script that runs before a request is handled)

  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Sets the rate limit per minute
  void setRateLimit(int maxlimit) {
    _maxRequestsPerMinute = maxlimit;
  }

  /// Adds a group of routes (e.g. /api has /posts which means /api/posts)
  void group(String prefix, void Function(App group) registerRoutes) {
    var groupApp = App();
    registerRoutes(groupApp);
    groupApp._routes.forEach((method, routes) {
      routes.forEach((path, handler) {
        route(method, '$prefix$path', handler);
      });
    });
  }

  /// Starts the server with Address and a Port (defaults: Address: ALL, Port: 8080)

  Future<void> start({String address = '0.0.0.0', int port = 8080}) async {
    var server = await HttpServer.bind(address, port);
    print(
        '[dartcore] Server running on ${address.replaceFirst('0.0.0.0', 'All IP Addresses on port ')}:$port');
    await for (HttpRequest request in server) {
      await _handleRequest(request);
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    _applyCorsHeaders(request);

    await _runMiddlewares(request, () async {
      final clientIp =
          request.connectionInfo?.remoteAddress.address ?? 'unknown';
      if (_isRateLimited(clientIp)) {
        _handleRateLimit(request);
        return;
      }

      final handler = _findHandler(method, path);
      if (handler != null) {
        await handler(request);
        print('[dartcore] $method $path --> ${request.response.statusCode}');
      } else {
        _custom404?.call(request) ?? _handle404(request);
      }
    });
  }

  void _applyCorsHeaders(HttpRequest request) {
    request.response.headers
        .add(HttpHeaders.accessControlAllowOriginHeader, '*');
    request.response.headers.add(HttpHeaders.accessControlAllowMethodsHeader,
        'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add(HttpHeaders.accessControlAllowHeadersHeader,
        'Content-Type, Authorization');
    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
    }
  }

  Future<void> _runMiddlewares(HttpRequest request, Function next) async {
    var index = 0;
    Future<void> nextMiddleware() async {
      if (index < _middlewares.length) {
        final middleware = _middlewares[index++];
        await middleware(request, nextMiddleware);
      } else {
        await next();
      }
    }

    await nextMiddleware();
  }

  bool _isRateLimited(String clientIp) {
    final currentTime = DateTime.now();
    _requestCounts.removeWhere((ip, count) =>
        currentTime
            .difference(DateTime.fromMillisecondsSinceEpoch(count))
            .inMinutes >=
        1);
    _requestCounts[clientIp] = (_requestCounts[clientIp] ?? 0) + 1;
    return _requestCounts[clientIp]! > _maxRequestsPerMinute;
  }

  void _handleRateLimit(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.tooManyRequests
      ..write('Rate limit exceeded\n[dartcore v$version]')
      ..close();
  }

  Handler? _findHandler(String method, String path) {
    final routesForMethod = _routes[method];
    if (routesForMethod == null) return null;
    for (var route in routesForMethod.keys) {
      if (_isMatchingRoute(route, path)) return routesForMethod[route];
    }
    return null;
  }

  bool _isMatchingRoute(String route, String path) {
    if (route == path) return true;
    if (route.endsWith('/*')) {
      final baseRoute = route.substring(0, route.length - 2);
      return path.startsWith(baseRoute);
    }
    final routeParts = route.split('/');
    final pathParts = path.split('/');
    if (routeParts.length != pathParts.length) return false;
    for (var i = 0; i < routeParts.length; i++) {
      if (routeParts[i].startsWith(':')) continue;
      if (routeParts[i] != pathParts[i]) return false;
    }
    return true;
  }

  void _handle404(HttpRequest request) {
    _custom404 != null ? _custom404!(request) : request.response
      ..statusCode = HttpStatus.notFound
      ..write('404 Not Found\n[dartcore v$version]')
      ..close();
    print('[dartcore] ${request.method} ${request.uri.path} --> 404');
  }

  void _handle500(HttpRequest request, Object error) {
    _custom500 != null ? _custom500!(request, error) : request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('500 Internal Server Error\n[dartcore v$version]')
      ..close();
    print('[dartcore] ${request.method} ${request.uri.path} --> 500: $error');
  }

  /// Sets a custom 404 error
  void set404(Function(HttpRequest request) handler) {
    _custom404 = handler;
  }

  /// sets a custom 500 error
  void set500(Function(HttpRequest request, Object error) handler) {
    _custom500 = handler;
  }

  /// Sends a json response
  Future<void> sendJson(HttpRequest request, Map<String, dynamic> data) async {
    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(data))
      ..close();
  }

  /// Sets a header to the response

  void setHeader(HttpRequest request, String key, String value) {
    request.response.headers.set(key, value);
  }

  /// Serves a static file

  Future<void> serveStaticFile(HttpRequest request, String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final fileStream = file.openRead();
      await fileStream.pipe(request.response);
    } else {
      _handle404(request);
    }
  }

  /// Parses a JSON from the request body

  Future<Map<String, dynamic>> parseJson(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Gets query parameters (e.g. getQueryParams(request)['name'])

  Map<String, String> getQueryParams(HttpRequest request) {
    return request.uri.queryParameters;
  }

  /// Parses Multipart Requests, useful for adding upload a file

  Future<void> parseMultipartRequest(HttpRequest request, String saveTo) async {
    if (request.headers.contentType?.mimeType == 'multipart/form-data') {
      final boundary = request.headers.contentType?.parameters['boundary'];
      if (boundary == null) {
        _handle500(request, 'Boundary not found');
        return;
      }
      final transformer = MimeMultipartTransformer(boundary);
      final bodyStream = request.cast<List<int>>().transform(transformer);
      await for (MimeMultipart part in bodyStream) {
        if (part.headers['content-disposition'] != null &&
            part.headers['content-disposition']!.contains('filename')) {
          final contentDisposition =
              HeaderValue.parse(part.headers['content-disposition']!);
          final filename = contentDisposition.parameters['filename'];
          final file = File('$saveTo/$filename');
          final sink = file.openWrite();
          await part.pipe(sink);
          await sink.close();
          print('[dartcore] File uploaded: $filename');
        }
      }
    } else {
      _handle500(request, 'Invalid content type');
    }
  }

  /// Serves a file, useful for downloading a file

  Future<void> sendFile(HttpRequest request, File file) async {
    if (await file.exists()) {
      request.response.headers.contentType = ContentType.binary;
      await file.openRead().pipe(request.response);
    } else {
      _handle404(request);
    }
  }

  /// Sends an HTML data

  Future<void> sendHtml(HttpRequest request, String htmlContent) async {
    request.response
      ..headers.contentType = ContentType.html
      ..write(htmlContent)
      ..close();
  }
}
