import 'dart:io';
import 'package:dartcore/dartcore.dart' as dartcore;

void main() async {
  var app = dartcore.App();

  // custom 404 error
  app.set404((request) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Custom 404 Not Found Handler\n')
      ..close();
  });

  // custom 500 error
  app.set500((request, error) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('Custom 500 Internal Server Error: $error\n')
      ..close();
  });

  // middleware for logging
  app.use((request, next) async {
    print('[Middleware] ${request.method} ${request.uri}');
    await next();
  });

  // serving static files
  app.route('GET', '/static/<file>', (request) async {
    var filePath = request.uri.pathSegments[2];
    await app.serveStaticFile(request, 'static/$filePath');
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
