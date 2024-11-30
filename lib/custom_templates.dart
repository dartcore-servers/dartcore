import 'dart:io';

/// a Custom Template Engine
abstract class CustomTemplateEngine {
  /// Returns a `String` containing the rendered template
  String render(String template, Map<String, dynamic> context);

  /// Returns a `ContentType` containing the template content type
  ContentType contentType();
}
