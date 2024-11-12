import 'dart:io';
import 'package:dartcore/apikeymanager.dart';
import 'package:dartcore/dartcore.dart' as dartcore;
import 'package:dartcore/rate_limiter.dart';

void main() async {
  var app = dartcore.App(
      "./config.json"); // optional to inculde config, but might helps in removing repeated parts of the code
  final apiKeyManager = ApiKeyManager();

  app.setRateLimiter(RateLimiter(
      storagePath: "./ratelimits",
      maxRequests: 99,
      resetDuration: Duration(hours: 1),
      encryptionPassword: "encryptionPassword"));

  // app.use(app.apiKeyMiddleware(apiKeyManager));           // Not needed for this example, will make ALL routes need an API key
  app.setupApiKeyRoutes(app, apiKeyManager);

  // custom 500 error
  app.set500((request, error) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('Custom 500 Internal Server Error: $error\n')
      ..close();
  });

  app.route('GET', '/data', (HttpRequest request) async {
    final cacheKey = 'data_key';
    final cachedData = app.getCachedResponse(cacheKey);

    if (cachedData != null) {
      await app.sendJson(request, cachedData); // Send cached response
    } else {
      // Simulate fetching data
      final data = {'key': 'value'};
      app.cacheResponse(cacheKey, data); // Cache the response
      await app.sendJson(request, data); // Send fresh response
    }
  });
  // Event test
  app.route('GET', '/d', (HttpRequest request) async {
    app.emit('dataRequested', {'path': request.uri.path}); // Emit event
    final data = {'key': 'value'};
    await app.sendJson(request, data);
  });

  // on Shutdown the server
  app.on('serverShutdown', (data) {
    print('Event: ${data['message']}');
  });

  // Listen for the event
  app.on('dataRequested', (data) {
    print('Data requested from ${data['path']}');
  });

  // Use error handling middleware
  app.use(app.errorHandlingMiddleware());

  // middleware for logging
  app.use((request, next) async {
    print('[Middleware] ${request.method} ${request.uri}');
    await next();
  });

  // Gets config
  app.route('GET', '/config', (HttpRequest request) async {
    final someSetting = app.getFromConfig('hi');
    await app.sendJson(request, {'hi': someSetting});
  });

  // serving static files
  app.route('GET', '/static/<file>', (request) async {
    var filePath = request.uri.pathSegments[2];
    await app.serveStaticFile(request, 'static/$filePath');
  });

  // render template
  app.route('GET', '/hello', (HttpRequest request) async {
    final context = {
      'name': 'Alex',
      'version': dartcore.version,
      'showDetails': true,
      'email': 'alex@example.com',
      'subscription': 'Premium',
      'showItems': true,
      'items': ['Item 1', 'Item 2', 'Item 3']
    };
    await app.renderTemplate(request, './templates/child.html',
        context); // renders child.html that extends hello.html
  });

  // JSON POST requests
  app.route('POST', '/json', (request) async {
    var jsonData = await app.parseJson(request);
    await app.sendJson(request, {'received': jsonData});
  });

  // file uploads      -- Make the directory "uploads" before executing, else the server will crash with an OS error.
  app.route('POST', '/upload', (request) async {
    await app.parseMultipartRequest(request, 'uploads');
    request.response
      ..statusCode = HttpStatus.ok
      ..write('File uploaded successfully.\n')
      ..close();
  });

  // Start the server
  await app.start(port: 8080);
}
