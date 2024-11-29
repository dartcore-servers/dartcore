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

  /// Sends a json response
  Future<void> json(Map<String, dynamic> data) async {
    request.response
      ..headers.contentType = io.ContentType.json
      ..write(jsonEncode(data))
      ..close();
  }

  /// Serves a file, useful for downloading a file

  Future<void> file(io.File file) async {
    if (await file.exists()) {
      request.response.headers.contentType = io.ContentType.binary;
      await file.openRead().pipe(request.response);
    } else {
      request.response.statusCode = 404;
    }
  }

  /// Sends an HTML data

  Future<void> html(String htmlContent) async {
    request.response
      ..headers.contentType = io.ContentType.html
      ..write(htmlContent)
      ..close();
  }

  /// Sends a data with a custom type

  Future<void> send(String content, io.ContentType contentType) async {
    request.response
      ..headers.contentType = contentType
      ..write(content)
      ..close();
  }

  /// Sends a static file

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
