// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io' as io;

/// HTTP Response, mainly used to return data to the Requester.
class Response {
  /// Request that will be edited
  final io.HttpRequest request;

  /// Adds a header to the response
  void addHeader(String key, String value) {
    request.response.headers.set(key, value);
  }

  /// Sends a JSON response with the provided [data].
  ///
  /// The response's content type is set to `application/json`.
  /// The [data] is encoded to a JSON string and written to the response.
  Future<void> json(dynamic data) async {
    request.response
      ..headers.contentType = io.ContentType.json
      ..write(jsonEncode(data))
      ..close();
  }

  /// Sends the file at the given path to the client.
  ///
  /// If the file does not exist, a 404 error is sent to the client and
  /// the request is not closed.
  Future<void> file(io.File file) async {
    if (await file.exists()) {
      request.response.headers.contentType = io.ContentType.binary;
      await file.openRead().pipe(request.response);
    } else {
      request.response.statusCode = 404;
    }
  }

  /// Sends an HTML response with the provided [htmlContent].
  ///
  /// The response's content type is set to `text/html`.
  /// The [htmlContent] is written to the response and the response is closed.
  Future<void> html(String htmlContent) async {
    request.response
      ..headers.contentType = io.ContentType.html
      ..write(htmlContent)
      ..close();
  }

  /// Sends a response with the provided [content] and [contentType].
  ///
  /// The content type of the response is set to [contentType].
  /// The content type of the response is set to [contentType].
  /// The [content] is written to the response and the response is closed.
  Future<void> send(String content, io.ContentType contentType) async {
    request.response
      ..headers.contentType = contentType
      ..write(content)
      ..close();
  }

  /// Sends the file at the given path to the client.
  ///
  /// The response's content type is set to [contentType].
  /// The content of the file is read and written to the response and the response is closed.
  ///
  /// If the file does not exist, a 404 error is sent to the client and
  /// the request is not closed.
  Future<void> staticFile(String path, io.ContentType contentType) async {
    request.response
      ..headers.contentType = contentType
      ..write(await io.File(path).readAsString())
      ..close();
  }

  /// Constuctor
  Response({required this.request});
}

/// Database Type Model Class
class DatabaseType {
  /// Type as String
  final String asString;

  /// MySQL
  final DatabaseType MySQL = DatabaseType('mysql');

  /// Postgres
  final DatabaseType Postgres = DatabaseType('postgres');

  /// Constuctor
  DatabaseType(this.asString);
}
