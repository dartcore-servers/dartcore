import 'dart:io';
import 'package:dartcore/apikeymanager.dart';
import 'package:dartcore/blocker.dart';
import 'package:dartcore/custom_template_engines/json.dart';
import 'package:dartcore/dartcore.dart' as dartcore;
import 'package:dartcore/rate_limiter.dart';

final app = dartcore.App(debug: true, metadata: {
  "version": "1.0.0",
  "description": "Dartcore Example",
  "title": "Example",
}); // optional to inculde config, but might helps in removing repeated parts of the code
final apiKeyManager = ApiKeyManager();
final IPBlocker ipBlocker = IPBlocker();
final CountryBlocker countryBlocker = CountryBlocker();
final RateLimiter rateLimiter = RateLimiter(
    shouldDisplayCaptcha: true,
    storagePath: "./ratelimits",
    maxRequests: 99,
    resetDuration: Duration(hours: 1),
    encryptionPassword: "encryptionPassword",
    ipBlocker: ipBlocker,
    countryBlocker: countryBlocker);

void main() async {
  app.setRateLimiter(rateLimiter);

  // app.use(app.apiKeyMiddleware(apiKeyManager));           // Not needed for this example, will make ALL routes need an API key
  app.setupApiKeyRoutes(apiKeyManager);

  // custom 500 error
  app.set500((request, error) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('Custom 500 Internal Server Error: $error\n')
      ..close();
  });

  app.openApi();

  // WebSocket support!
  app.ws('/ws', (socket) {
    print('[App] WebSocket connection established');
    socket.listen((message) {
      print('Received: $message');
      socket.add('[App] $message');
    }, onDone: () {
      print('[App] WebSocket connection closed');
    });
  });

  app.route('GET', '/data', (req, res) async {
    final cacheKey = 'data_key';
    final cachedData = app.getCachedResponse(cacheKey);

    if (cachedData != null) {
      await res.json(cachedData); // Send cached response
    } else {
      // Simulate fetching data
      final data = {'key': 'value'};
      app.cacheResponse(cacheKey, data); // Cache the response
      await res.json(data); // Send fresh response
    }
  }, metadata: {
    'summary': 'A route',
    'operationId': 'getMain',
    'responses': {
      '200': {
        'description': 'Successful Response',
        'content': {
          'application/json': {'type': 'string'}
        }
      }
    }
  });
  // Event test
  app.route('GET', '/d', (req, res) async {
    app.emit('dataRequested', {'path': req.uri.path}); // Emit event
    final data = {'key': 'value'};
    await res.json(data);
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
  app.route('GET', '/config', (req, res) async {
    final someSetting = app.getFromConfig('hi');
    await res.json({'hi': someSetting});
  });

  // serving static files
  app.route('GET', '/static/<file>', (req, res) async {
    var filePath = req.uri.pathSegments[2];
    await app.serveStaticFile(req, 'static/$filePath');
  });

  // render template
  app.route('GET', '/hello', (req, res) async {
    final context = {
      'name': 'Alex',
      'version': dartcore.version,
      'showDetails': true,
      'email': 'alex@example.com',
      'subscription': 'Premium',
      'showItems': true,
      'items': ['Item 1', 'Item 2', 'Item 3']
    };
    await app.renderTemplate(req, './templates/child.html',
        context); // renders child.html that extends hello.html
  });

  app.get("/hello/v2", (req, res) async {
    await app.render(
        req,
        JsonTemplateEngine(),
        '{"hello": "world", "name": "{{ name }}", "version": "{{ version }}}"',
        {
          'name': 'Alex',
          'version': dartcore.version,
        });
  });

  // JSON POST requests
  app.route('POST', '/json', (req, res) async {
    var jsonData = await app.parseJson(req);
    await res.json({'received': jsonData});
  });

  // file uploads      -- Make the directory "uploads" before executing, else the server will crash with an OS error.
  app.post('/upload', (req, res) async {
    await app.parseMultipartRequest(req, 'uploads');
    await res.send("File Uploaded Successfully!", ContentType.text);
  });

  app.get("/", (req, res) => res.html("<h1>Hello World!</h1>"));
  app.get("/block", (req, res) async {
    countryBlocker.block(
        "CN"); // Blocks "China" country. sorry chinese people. thats just for showcasing
    await rateLimiter.refresh();
    res.json({"message": "Blocked China."});
  });
  app.get("/test",
      (req, res) async => res.json({"request": await app.parseJson(req)}));
  app.get("/shutdown", (req, res) async {
    res.html(
        "<center><h1>Server is shutting down in 3 seconds...</h1></center>");
    Future.delayed(Duration(seconds: 3), () {
      app.shutdown();
    });
  });

  // Start the server
  await app.start(port: 8080);
}
