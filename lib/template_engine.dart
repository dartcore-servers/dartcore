import 'dart:io';

/// TemplateEngine class
class TemplateEngine {
  /// Renders a template file with the given context.
  ///
  /// The template file should be an HTML file with placeholders in the form
  /// of `{{ key }}` where `key` is a key in the [context] map.
  ///
  /// The rendered template is returned as a string.
  ///
  /// - [templatePath]: The path to the template file.
  /// - [context]: The map containing the context for the template.
  Future<String> render(
      String templatePath, Map<String, dynamic> context) async {
    String template = await File(templatePath).readAsString();
    template = await _processInheritance(template, context);
    template = _processLoops(template, context);
    template = _processConditionals(template, context);
    context.forEach((key, value) {
      template = template.replaceAll('{{ $key }}', value.toString());
    });

    return template;
  }

  /// Processes `{% extends "base.html" %}` inheritance blocks.
  ///
  /// Any `{% block blockName %}` blocks in the template are replaced with the
  /// matching block from the base template. If no matching block is found in the
  /// base template, the block is left as is.
  Future<String> _processInheritance(
      String template, Map<String, dynamic> context) async {
    final extendsPattern = RegExp(r'{%\s*extends\s*"(.+)"\s*%}');
    final blockPattern =
        RegExp(r'{%\s*block\s*(\w+)\s*%}([\s\S]*?){%\s*endblock\s*%}');
    final extendsMatch = extendsPattern.firstMatch(template);
    if (extendsMatch != null) {
      String baseTemplatePath = extendsMatch.group(1)!;
      String baseTemplate = await File(baseTemplatePath).readAsString();
      Map<String, String> childBlocks = {};
      for (var match in blockPattern.allMatches(template)) {
        childBlocks[match.group(1)!] = match.group(2)!;
      }
      template = baseTemplate.replaceAllMapped(blockPattern, (match) {
        String blockName = match.group(1)!;
        return childBlocks[blockName] ?? match.group(2)!;
      });
    }
    return template;
  }

  /// Processes `{% for item in list %}` loops.
  ///
  /// Replaces the loop block with the content of the loop block repeated for
  /// each item in the list, with the loop variable available in the context
  /// as `item`.
  ///
  /// If the list is not found in the context, the loop block is replaced with
  /// an empty string.
  String _processLoops(String template, Map<String, dynamic> context) {
    final loopPattern =
        RegExp(r'{%\s*for\s+(\w+)\s+in\s+(\w+)\s*%}([\s\S]*?){%\s*endfor\s*%}');
    return template.replaceAllMapped(loopPattern, (match) {
      String itemName = match.group(1)!;
      String listName = match.group(2)!;
      String loopContent = match.group(3)!;

      if (context.containsKey(listName) && context[listName] is List) {
        List items = context[listName];
        return items.map((item) {
          Map<String, dynamic> loopContext = Map.from(context);
          loopContext[itemName] = item;
          return _replacePlaceholders(loopContent, loopContext);
        }).join();
      }
      return '';
    });
  }

  /// Processes `{% if condition %}` conditionals.
  ///
  /// Replaces the conditional block with its content if the condition is true,
  /// or an empty string if the condition is false.
  ///
  /// The condition is evaluated by looking up the condition name in the
  /// context. If the condition is found and is true, the content of the
  /// conditional block is returned. Otherwise, an empty string is returned.
  String _processConditionals(String template, Map<String, dynamic> context) {
    final ifPattern = RegExp(r'{%\s*if\s+(\w+)\s*%}([\s\S]*?){%\s*endif\s*%}');
    return template.replaceAllMapped(ifPattern, (match) {
      String condition = match.group(1)!;
      String ifContent = match.group(2)!;

      if (context[condition] == true) {
        return ifContent;
      }
      return '';
    });
  }

  /// Replaces all placeholders in the content with the corresponding values from
  /// the context.
  ///
  /// The placeholders are replaced with the values from the context, with the
  /// key enclosed in double curly braces. For example, if the context contains
  /// a key-value pair of "name": "John", the placeholder "{{ name }}" would
  /// be replaced with "John".
  String _replacePlaceholders(String content, Map<String, dynamic> context) {
    context.forEach((key, value) {
      content = content.replaceAll('{{ $key }}', value.toString());
    });
    return content;
  }
}
