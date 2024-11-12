import 'dart:io';

/// TemplateEngine class
class TemplateEngine {
  /// Renders a template file with the given context.
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

  /// Handles template inheritance by merging the base template and blocks.
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

  /// Processes {% for item in items %} loops.
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

  /// Processes {% if condition %} statements.
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

  /// Replaces placeholders within a specific content with the context.
  String _replacePlaceholders(String content, Map<String, dynamic> context) {
    context.forEach((key, value) {
      content = content.replaceAll('{{ $key }}', value.toString());
    });
    return content;
  }
}
