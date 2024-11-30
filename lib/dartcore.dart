// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartcore/apikeymanager.dart';
import 'package:dartcore/blocker.dart';
import 'package:dartcore/cache.dart';
import 'package:dartcore/config.dart';
import 'package:dartcore/custom_templates.dart';
import 'package:dartcore/custom_types.dart';
import 'package:dartcore/event_emitter.dart';
import 'package:dartcore/openapi_spec.dart';
import 'package:dartcore/rate_limiter.dart';
import 'package:dartcore/template_engine.dart';
import 'package:dartcore/websocket_support/handler.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

/// dartcore's version
const version = '0.0.8-git';

/// Defines Handler
typedef Handler = Future<void> Function(HttpRequest request, Response response);

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
  Map<String, dynamic> _metadata = {};
  final List<Middleware> _middlewares = [];
  Function(HttpRequest request)? _custom404;
  Function(HttpRequest request, Object error)? _custom500;
  final _websocketRoutes = <String, void Function(WebSocket socket)>{};

  /// Debug mode (TODO)
  final bool debug = true;

  RateLimiter? _rateLimiter;

  /// Constructor
  App({String? configPath, bool? debug, Map<String, dynamic>? metadata}) {
    _config = Config(configPath ?? "");
    _metadata = metadata ??
        {"title": "My API", "version": "1.0.0", "description": "Dartcore API"};
    _templateEngine = TemplateEngine();
    _rateLimiter = RateLimiter(
      shouldDisplayCaptcha: false,
      storagePath: './rate_limits.dartcorelimits',
      maxRequests: 60,
      resetDuration: Duration(minutes: 1),
      ipBlocker: IPBlocker(), // Yeah, recommend changing it
      countryBlocker: CountryBlocker(), // Yeah...
      encryptionPassword:
          "dartcore", // Don't keep it unless it's a private server, recommend changing it
    );
  }

  /// Sets the rate limiter for the application.
  ///
  /// - Parameters:
  ///   - ratelimiter: The RateLimiter instance to be used for managing
  ///     the rate limits of incoming requests.
  void setRateLimiter(RateLimiter ratelimiter) {
    _rateLimiter = ratelimiter;
  }

  /// Returns the current version of dartcore as a string.
  String getVersion() {
    return version;
  }

  /// Returns a map of all the routes in the application, where each key is
  /// an HTTP method and the value is another map with the path as the key
  /// and the handler function as the value.
  ///
  /// For example, if the application has a route for GET requests to '/api',
  /// the returned map would contain the following entry:
  ///
  /// {
  ///   'GET': {
  ///     '/api': (HttpRequest request, Response response) {
  ///       // Handle the request
  ///     }
  ///   }
  /// }
  Map<String, Map<String, Handler>> routes() {
    return _routes;
  }

  /// Returns the metadata associated with the application.
  ///
  /// The metadata contains key-value pairs that provide additional
  /// information about the application, such as title, version,
  /// and description.
  ///
  /// - Returns: A map containing the application's metadata.
  Map<String, dynamic> metadata() {
    return _metadata;
  }

  /// Adds a route to the application with the specified HTTP method and path.
  /// Associates the route with a handler function and optional metadata.
  ///
  /// - Parameters:
  ///   - method: The HTTP method for the route (e.g., 'GET', 'POST').
  ///   - path: The path for the route (e.g., '/api/resource').
  ///   - handler: The function to handle requests to this route.
  ///   - metadata: Optional metadata for the route, such as description or status.
  void route(String method, String path, Handler handler,
      {Map<String, dynamic>? metadata}) {
    _routes.putIfAbsent(method, () => {})[path] = handler;
    if (metadata != null) {
      _metadata.putIfAbsent(path, () => {})[method] = metadata;
    }
  }

  /// Adds a WebSocket route to the application with the specified path.
  /// Associates the route with a handler function to manage WebSocket connections.
  ///
  /// - Parameters:
  ///   - path: The path for the WebSocket route (e.g., '/ws/resource').
  ///   - handler: The function to handle WebSocket connections for this route.

  void ws(String path, void Function(WebSocket socket) handler) {
    _websocketRoutes[path] = handler;
  }

  /// Adds a GET route to the application with the specified path.
  /// Associates the route with a handler function and optional metadata.
  ///
  /// - Parameters:
  ///   - path: The path for the route (e.g., '/api/resource').
  ///   - handler: The function to handle requests to this route.
  ///   - metadata: Optional metadata for the route, such as description or status.
  void get(String path, Handler handler, {Map<String, dynamic>? metadata}) {
    final method = 'GET';
    _routes.putIfAbsent(method, () => {})[path] = handler;
    if (metadata != null) {
      _metadata.putIfAbsent(path, () => {})[method] = metadata;
    }
  }

  /// Adds a POST route to the application with the specified path.
  /// Associates the route with a handler function and optional metadata.
  ///
  /// - Parameters:
  ///   - path: The path for the route (e.g., '/api/resource').
  ///   - handler: The function to handle requests to this route.
  ///   - metadata: Optional metadata for the route, such as description or status.
  void post(String path, Handler handler, {Map<String, dynamic>? metadata}) {
    final method = 'POST';
    _routes.putIfAbsent(method, () => {})[path] = handler;
    if (metadata != null) {
      _metadata.putIfAbsent(path, () => {})[method] = metadata;
    }
  }

  /// Adds a PUT route to the application with the specified path.
  /// Associates the route with a handler function and optional metadata.
  ///
  /// - Parameters:
  ///   - path: The path for the route (e.g., '/api/resource').
  ///   - handler: The function to handle requests to this route.
  ///   - metadata: Optional metadata for the route, such as description or status.
  void put(String path, Handler handler, {Map<String, dynamic>? metadata}) {
    final method = 'PUT';
    _routes.putIfAbsent(method, () => {})[path] = handler;
    if (metadata != null) {
      _metadata.putIfAbsent(path, () => {})[method] = metadata;
    }
  }

  /// Adds a DELETE route to the application with the specified path.
  /// Associates the route with a handler function and optional metadata.
  ///
  /// - Parameters:
  ///   - path: The path for the route (e.g., '/api/resource').
  ///   - handler: The function to handle requests to this route.
  ///   - metadata: Optional metadata for the route, such as description or status.
  void delete(String path, Handler handler, {Map<String, dynamic>? metadata}) {
    final method = 'DELETE';
    _routes.putIfAbsent(method, () => {})[path] = handler;
    if (metadata != null) {
      _metadata.putIfAbsent(path, () => {})[method] = metadata;
    }
  }

  /// Returns the country for the given IP address.
  ///
  /// This method sends a request to http://ip-api.com/json/$ip to get the country
  /// for the given IP address. If the request is successful, it returns the country,
  /// otherwise it returns null.
  ///
  /// - Parameters:
  ///   - ip: The IP address to get the country for.
  ///
  /// - Returns: The country for the given IP address, or null if the request fails.
  Future<String?> getGeoLocation(String ip) async {
    final url = 'http://ip-api.com/json/$ip';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['country'];
    }
    return null;
  }

  /// Determines if the country associated with the given IP address is blocked.
  ///
  /// This function retrieves the country associated with the provided [ip] address
  /// using the `getGeoLocation` method. It then checks if the country is present
  /// in the list of blocked countries managed by the rate limiter's country blocker.
  ///
  /// - Parameters:
  ///   - ip: The IP address for which to check the country block status.
  ///
  /// - Returns: A `Future` that resolves to `true` if the country is blocked,
  ///   or `false` if the country is not blocked or if the country could not be determined.
  Future<bool> isBlockedCountry(String ip) async {
    final country = await getGeoLocation(ip);
    final blockedCountries = _rateLimiter!.countryBlocker.blockedList;

    return country != null && blockedCountries.contains(country);
  }

  /// Adds a middleware to the list of middlewares that will be executed in order.
  /// Note that the order of execution is the same as the order of addition.
  /// You can add a middleware at any time, but it will only start executing on new requests.
  /// If you add a middleware after the server is started, it will be executed on new requests,
  /// but not on requests that are already in progress.
  void use(Middleware middleware) {
    _middlewares.add(middleware);
  }

  /// Starts the server.
  ///
  /// If [port] is not provided, it will use 8080.
  /// If [port] is `0`, it will use a random port chosen by the OS.
  /// If [address] is not provided, it will use `localhost`, `127.0.0.1`, `0.0.0.0` or `::1`
  ///
  /// If the server fails to start, it will print an error message and exit with code 1.
  ///
  /// If the server starts successfully, it will print a success message, and the server
  /// will listen for incoming requests.
  ///
  /// If the server is interrupted with Ctrl+C, it will shutdown the server, delete the
  /// rate limit file if it exists, and exit with code 0.
  Future<void> start({String address = '0.0.0.0', int port = 8080}) async {
    try {
      _server = await HttpServer.bind(address, port);
    } on SocketException catch (e) {
      if (e.osError!.errorCode == 10048) {
        print(
            '[dartcore] Port is already in use, try to use to a different port.');
        exit(1);
      } else {
        print(
            '[dartcore] Failed to start server: OS ERROR ${e.osError!.errorCode}, ${e.osError!.message}');
        exit(1);
      }
    } catch (e) {
      print('[dartcore] Failed to start server:');
      print(e);
      exit(1);
    }
    print(
        '[dartcore] Server running on ${_server!.address.address}:${_server!.port}\n[dartcore] Press Ctrl+C to shutdown the Server.');
    emit('serverStarted', {'address': address, 'port': port});

    ProcessSignal.sigint.watch().listen((_) async {
      final file = File(_rateLimiter!.storagePath);
      if (await file.exists()) {
        await file.delete();
      }
      await shutdown();
      exit(0);
    });

    await for (HttpRequest request in _server!) {
      await _handleRequest(request, Response(request: request));
    }
  }

  /// Retrieves a configuration value by its key.
  ///
  /// - Parameters:
  ///   - key: The key of the configuration value to retrieve.
  ///
  /// - Returns: The value associated with the key, or null if the key does not exist.
  dynamic getFromConfig(String key) {
    return _config?.get(key);
  }

  /// Adds SwaggerUI routes to the application.
  ///
  /// This method makes it easier for users to document and use the API.
  /// It sets up routes for the SwaggerUI at the following paths:
  /// - `/openapi`: The OpenAPI specification for the API.
  /// - `/docs`: The SwaggerUI itself.
  /// - `/index.css`: The CSS file for the SwaggerUI.
  /// - `/swagger-ui-bundle.js`: The JavaScript file for the SwaggerUI.
  /// - `/swagger-initializer.js`: A JavaScript file that initializes the SwaggerUI.
  /// - `/swagger-ui-standalone-preset.js`: A JavaScript file that sets up the SwaggerUI with the standalone preset.
  ///
  /// The user can visit the SwaggerUI at `<http://localhost:8080/docs>`.
  ///
  /// You can also copy-paste and edit the names of the routes, but you should
  /// add `app.` before each `route()` call to ensure that the routes are correctly
  /// added to the application.
  void openApi() {
    route("GET", "/openapi", (req, res) async {
      res.json(generateOpenApiSpec(this,
          true)); // set it to `false` in case you are copy-pasting and editing the names of the routes
    });
    route("GET", "/docs", (req, res) async {
      await res.staticFile("./swaggerui/index.html", ContentType.html);
    });
    route("GET", "/index.css", (req, res) async {
      await res.staticFile("./swaggerui/index.css", ContentType("text", "css"));
    });
    route("GET", "/swagger-ui-bundle.js", (req, res) async {
      await res.send(
          (await http.get(Uri.parse(
                  "https://raw.githubusercontent.com/swagger-api/swagger-ui/refs/heads/master/dist/swagger-ui-bundle.js")))
              .body,
          ContentType("application", "javascript"));
    });
    route("GET", "/swagger-initializer.js", (req, res) async {
      await res.staticFile("./swaggerui/swagger-initializer.js",
          ContentType("application", "javascript"));
    });
    route("GET", "/swagger-ui-standalone-preset.js", (req, res) async {
      await res.send(
          (await dio.Dio().get(
                  "https://raw.githubusercontent.com/swagger-api/swagger-ui/refs/heads/master/dist/swagger-ui-standalone-preset.js",
                  options: dio.Options(
                    responseType: dio.ResponseType.json,
                    followRedirects: true,
                    headers: {
                      'Content-Type': 'application/json; charset=utf-8',
                    },
                    contentType: 'application/json; charset=utf-8',
                  )))
              .data,
          ContentType("application", "javascript"));
    });
    route("GET", "/swagger-ui.css", (req, res) async {
      await res.staticFile(
          "./swaggerui/swagger-ui.css", ContentType("text", "css"));
    });
  }

  Future<void> _handleRequest(HttpRequest request, Response response) async {
    final path = request.uri.path;
    final method = request.method;

    if (_websocketRoutes.containsKey(request.uri.path) &&
        request.isWebSocketUpgrade) {
      try {
        var socket = await WebSocketTransformer.upgrade(request);
        _websocketRoutes[request.uri.path]!(socket);
      } catch (e) {
        print('[dartcore] Failed to upgrade to WebSocket: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      }
      return;
    }

    _applyCorsHeaders(request);

    await _runMiddlewares(request, () async {
      final clientIp =
          request.connectionInfo?.remoteAddress.address ?? 'unknown';
      if (await _rateLimiter!.isRateLimited(clientIp)) {
        _handleRateLimit(request);
        return;
      }
      if (await isBlockedCountry(clientIp)) {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.write(
            'Access from your country is blocked.\n[dartcore v$version]');
        await request.response.close();
        return;
      }

      final handler = _findHandler(method, path);
      if (handler != null) {
        await handler(request, response);
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
    if (!_rateLimiter!.shouldDisplayCaptcha) {
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..write('Rate limit exceeded\n[dartcore v$version]')
        ..close();
    } else {
      final res = Response(request: request);
      res.html("""
<html>
<title>Rate Limit Exceeded - Dartcore</title>
    <body>
      <p>You have exceeded the maximum number of requests. Please complete the CAPTCHA to continue:</p>
      <div class="g-recaptcha" data-sitekey="YOUR_SITE_KEY"></div>
      <script src="https://www.google.com/recaptcha/api.js" async defer></script>
      <form action="/verify-captcha" method="post">
        <input type="hidden" name="captchaResponse" value="CAPTCHA_RESPONSE">
        <button type="submit">Submit</button>
      </form>
    </body>
  </html>
""");
    }
  }

  /// Verifies the given CAPTCHA [response] with the provided [secretKey].
  ///
  /// - Parameters:
  ///   - response: The user's response to the CAPTCHA challenge.
  ///   - secretKey: The secret key of the recaptcha site.
  ///
  /// - Returns: `true` if the CAPTCHA is valid, `false` otherwise.
  Future<bool> verifyCaptcha(String response, String secretKey) async {
    final url = Uri.parse('https://www.google.com/recaptcha/api/siteverify');
    final responseH = await http.post(
      url,
      body: {
        'secret': secretKey,
        'response': response,
      },
    );
    final responseBody = json.decode(responseH.body);
    return responseBody['success'] == true;
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

  /// Sets a custom 404 error handler.
  /// The handler is called with the original [HttpRequest] as an argument.
  /// The handler is responsible for writing a response to the client
  /// and closing the request.
  void set404(Function(HttpRequest request) handler) {
    _custom404 = handler;
  }

  /// Sets a custom 500 error handler.
  /// The handler is called with the original [HttpRequest] and the error
  /// object as arguments.
  /// The handler is responsible for writing a response to the client
  /// and closing the request.
  void set500(Function(HttpRequest request, Object error) handler) {
    _custom500 = handler;
  }

  void _handle500(HttpRequest request, Object error) {
    _custom500 != null ? _custom500!(request, error) : request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('500 Internal Server Error\n[dartcore v$version]')
      ..close();
    print('[dartcore] ${request.method} ${request.uri.path} --> 500: $error');
  }

  /// Serves a static file at [filePath] to the client.
  ///
  /// The file is sent to the client with the correct MIME type.
  ///
  /// If the file does not exist, a 404 error is sent to the client and
  /// the request is not closed.
  Future<void> serveStaticFile(HttpRequest request, String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      final fileStream = file.openRead();
      await fileStream.pipe(request.response);
    } else {
      _handle404(request);
    }
  }

  /// Parses the request body as JSON and returns it as a Map<String, dynamic>
  ///
  /// The request body should contain a valid JSON string.
  ///
  /// Throws a FormatException if the request body is not a valid JSON string.
  Future<Map<String, dynamic>> parseJson(HttpRequest request) async {
    final content = await utf8.decodeStream(request);
    return jsonDecode(content);
  }

  /// Retrieves query parameters from the given HTTP request.
  ///
  /// Returns a map containing key-value pairs of query parameters.
  /// For example, a request with the URI `/endpoint?name=value` will
  /// return `{'name': 'value'}`.
  ///
  /// - Parameter request: The HTTP request containing the URI with query parameters.

  Map<String, String> params(HttpRequest request) {
    return request.uri.queryParameters;
  }

  /// Parses a multipart/form-data request and saves the uploaded files
  ///
  /// to the [saveTo] directory.
  ///
  /// The request body should contain a valid multipart/form-data content.
  ///
  /// Throws a 500 error if the request body is not a valid multipart/form-data
  /// content.
  ///
  /// - [request]: The HTTP request containing the multipart/form-data
  ///   content.
  /// - [saveTo]: The directory where the uploaded files will be saved.
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

  /// Renders a template file with the given context.
  ///
  /// The template file should be an HTML file with placeholders in the form
  /// of `{{ key }}` where `key` is a key in the [context] map.
  ///
  /// The rendered template is written to the response and the response is
  /// closed.
  ///
  /// If the template file does not exist or cannot be rendered, a 500 error
  /// is sent to the client and the request is not closed.
  ///
  /// - [request]: The HTTP request.
  /// - [templatePath]: The path to the template file.
  /// - [context]: The map containing the context for the template.
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

  /// Renders a template file with the given context using a Custom Template Engine.
  ///
  /// The template file should have placeholders in the form
  /// of `{{ key }}` where `key` is a key in the [context] map.
  ///
  /// The rendered template is written to the response and the response is
  /// closed.
  ///
  /// If the template file does not exist or cannot be rendered, a 500 error
  /// is sent to the client and the request is not closed.
  ///
  /// - [request]: The HTTP request.
  /// - [template]: The template itself.
  /// - [context]: The map containing the context for the template.
  Future<void> render(HttpRequest request, CustomTemplateEngine ctemplateEngine,
      String template, Map<String, dynamic> context) async {
    try {
      String renderedTemplate = ctemplateEngine.render(template, context);
      request.response
        ..headers.contentType = ctemplateEngine.contentType()
        ..write(renderedTemplate)
        ..close();
    } catch (e) {
      _handle500(request, e);
    }
  }

  /// Middleware that catches any unhandled errors in the stack and handles
  /// them according to the error handling strategy of the app.
  ///
  /// The error handling strategy is as follows:
  ///
  /// 1. If an error handler is specified, it is called with the error and
  ///    stack trace. The handler should return a boolean indicating whether
  ///    the error was handled. If the error was handled, the request is
  ///    closed. If the error was not handled, the request is not closed.
  /// 2. If no error handler is specified, a 500 error is sent to the client
  ///    and the request is not closed.
  Middleware errorHandlingMiddleware() {
    return (HttpRequest request, Function next) async {
      try {
        await next();
      } catch (e, stackTrace) {
        _handleError(request, e, stackTrace);
      }
    };
  }

  void _handleError(HttpRequest request, Object error, StackTrace stackTrace) {
    print('[dartcore] Error: $error\nStackTrace: $stackTrace');
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('500 Internal Server Error\n[dartcore v$version]')
      ..close();
  }

  /// Stores a response in the cache under the given key.
  ///
  /// - Parameters:
  ///   - key: The key to store the response under.
  ///   - value: The response to store in the cache.
  void cacheResponse(String key, dynamic value) {
    _cache.set(key, value);
  }

  /// Retrieves a response from the cache under the given key.
  ///
  /// - Parameters:
  ///   - key: The key of the response to retrieve.
  ///
  /// - Returns: The response associated with the key, or null if the key is not in the cache.
  dynamic getCachedResponse(String key) {
    return _cache.get(key);
  }

  /// Adds a listener for a specific event.
  ///
  /// - Parameters:
  ///   - event: The name of the event to listen for.
  ///   - listener: The function to call when the event is emitted.
  void on(String event, Function(dynamic) listener) {
    _eventEmitter.on(event, listener);
  }

  /// Emits an event, calling all registered listeners.
  ///
  /// - Parameters:
  ///   - event: The name of the event to emit.
  ///   - data: The data to pass to the listeners.
  void emit(String event, [dynamic data]) {
    _eventEmitter.emit(event, data);
  }

  /// Shuts down the server if it is running.
  ///
  /// If the server is running, it will be closed and a shutdown message will be printed.
  /// An event named 'serverShutdown' will be emitted with a message indicating the server
  /// has been shut down.
  Future<void> shutdown() async {
    if (_server != null) {
      await _server!.close();
      print('[dartcore] Server shutting down.');
      emit('serverShutdown', {'message': 'Server has been shut down.'});
    }
  }

  /// Middleware that validates API keys using the provided [apiKeyManager].
  ///
  /// This middleware checks for the presence of an 'x-api-key' header in the
  /// request. If the header is missing or the API key is invalid, a 403
  /// Forbidden response is returned to the client. If the API key is valid,
  /// the request is passed to the next middleware or handler in the chain.
  ///
  /// - Parameters:
  ///   - apiKeyManager: The manager responsible for validating API keys.
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

  /// Sets up the following routes for basic API key management:
  ///
  /// - `POST /api-keys`: Generates a new API key and returns it in the response
  ///   body.
  /// - `DELETE /api-keys/:key`: Revokes the API key with the given `:key`.
  ///
  /// The API keys are managed by the given [apiKeyManager].
  void setupApiKeyRoutes(ApiKeyManager apiKeyManager) {
    route('POST', '/api-keys', (req, res) async {
      final newApiKey = apiKeyManager.generateApiKey();
      await res.json({'apiKey': newApiKey.key});
    });

    route('DELETE', '/api-keys/:key', (req, res) async {
      final key = req.uri.pathSegments.last;
      apiKeyManager.revokeApiKey(key);
      req.response
        ..statusCode = HttpStatus.noContent
        ..close();
    });
  }
}
