import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartcore/apikeymanager.dart';
import 'package:dartcore/cache.dart';
import 'package:dartcore/config.dart';
import 'package:dartcore/event_emitter.dart';
import 'package:dartcore/rate_limiter.dart';
import 'package:dartcore/template_engine.dart';
import 'package:mime/mime.dart';

/// dartcore's version
const version = '0.0.5';

/// Defines Handler
typedef Handler = Future<void> Function(HttpRequest request);

/// Defines Middleware
typedef Middleware = Future<void> Function(HttpRequest request, Function next);

/// App class, almost the most important class.
class App {
  HttpServer? _server;
  Config? _config;
  final EventEmitter _eventEmitter = EventEmitter();
  TemplateEngine? _templateEngine;
  final Cache _cache = Cache();
  final Map<String, Map<String, Handler>> _routes = {};
  final List<Middleware> _middlewares = [];
  Function(HttpRequest request)? _custom404;
  Function(HttpRequest request, Object error)? _custom500;

  RateLimiter? _rateLimiter;

  /// Constructor
  App(String configPath) {
    _config = Config(configPath);
    _templateEngine = TemplateEngine();
    _rateLimiter = RateLimiter(
      storagePath: './rate_limits.dartcorelimits',
      maxRequests: 60,
      resetDuration: Duration(minutes: 1),
      encryptionPassword:
          "dartcore", // Don't keep it unless it's a private server, recommend changing it
    );
  }

  /// Sets a custom rate limiter
  void setRateLimiter(RateLimiter ratelimiter) {
    _rateLimiter = ratelimiter;
  }

  /// Returns dartcore's version
  String getVersion() {
    return version;
  }

  /// Routing function

  void route(String method, String path, Handler handler) {
    _routes.putIfAbsent(method, () => {})[path] = handler;
  }

  /// Using middleware function

  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Starts the server

  Future<void> start({String address = '0.0.0.0', int port = 8080}) async {
    _server = await HttpServer.bind(address, port);
    print(
        '[dartcore] Server running on ${address.replaceFirst('0.0.0.0', 'All IP Addresses on port ')}:$port');
    emit('serverStarted', {'address': address, 'port': port});

    await for (HttpRequest request in _server!) {
      await _handleRequest(request);
    }
  }

  /// Get configuration
  dynamic getFromConfig(String key) {
    return _config?.get(key);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    _applyCorsHeaders(request);

    await _runMiddlewares(request, () async {
      final clientIp =
          request.connectionInfo?.remoteAddress.address ?? 'unknown';
      if (_rateLimiter!.isRateLimited(clientIp)) {
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

  /// Sets a custom 404 Message
  void set404(Function(HttpRequest request) handler) {
    _custom404 = handler;
  }

  /// Sets a custom 500 Message
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

  void _handle500(HttpRequest request, Object error) {
    _custom500 != null ? _custom500!(request, error) : request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('500 Internal Server Error\n[dartcore v$version]')
      ..close();
    print('[dartcore] ${request.method} ${request.uri.path} --> 500: $error');
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

  /// Sends a data with a custom type

  Future<void> send(
      HttpRequest request, String content, ContentType contentType) async {
    request.response
      ..headers.contentType = contentType
      ..write(content)
      ..close();
  }

  /// Renders a template and sends it as a response
  Future<void> renderTemplate(HttpRequest request, String templatePath,
      Map<String, dynamic> context) async {
    try {
      String renderedTemplate =
          await _templateEngine!.render(templatePath, context);
      request.response
        ..headers.contentType = ContentType.html
        ..write(renderedTemplate)
        ..close();
    } catch (e) {
      _handle500(request, e);
    }
  }

  /// Middleware to handle errors
  Middleware errorHandlingMiddleware() {
    return (HttpRequest request, Function next) async {
      try {
        await next(); // Continue to the next middleware or route handler
      } catch (e, stackTrace) {
        _handleError(request, e, stackTrace);
      }
    };
  }

  /// Handle errors and respond to the client
  void _handleError(HttpRequest request, Object error, StackTrace stackTrace) {
    print('[dartcore] Error: $error\nStackTrace: $stackTrace');
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('500 Internal Server Error\n[dartcore v$version]')
      ..close();
  }

  /// Caches a response
  void cacheResponse(String key, dynamic value) {
    _cache.set(key, value);
  }

  /// Retrieves a cached response
  dynamic getCachedResponse(String key) {
    return _cache.get(key);
  }

  /// Adds an event listener
  void on(String event, Function(dynamic) listener) {
    _eventEmitter.on(event, listener);
  }

  /// Emits an event
  void emit(String event, [dynamic data]) {
    _eventEmitter.emit(event, data);
  }

  /// Gracefully shuts down the server
  Future<void> shutdown() async {
    if (_server != null) {
      await _server!.close();
      print('[dartcore] Server shutdown.');
      emit('serverShutdown', {'message': 'Server has been shut down.'});
    }
  }

  /// API Key Middleware
  Middleware apiKeyMiddleware(ApiKeyManager apiKeyManager) {
    return (HttpRequest request, Function next) async {
      final apiKey = request.headers['x-api-key']?.first;

      if (apiKey == null || !apiKeyManager.validateApiKey(apiKey)) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Invalid or missing API key\n[dartcore $version]')
          ..close();
        return;
      }

      await next();
    };
  }

  /// Sets up a basic API key management routes

  void setupApiKeyRoutes(App app, ApiKeyManager apiKeyManager) {
    app.route('POST', '/api-keys', (HttpRequest request) async {
      final newApiKey = apiKeyManager.generateApiKey();
      await app.sendJson(request, {'apiKey': newApiKey.key});
    });

    app.route('DELETE', '/api-keys/:key', (HttpRequest request) async {
      final key = request.uri.pathSegments.last;
      apiKeyManager.revokeApiKey(key);
      request.response
        ..statusCode = HttpStatus.noContent
        ..close();
    });
  }
}
