import 'dart:io';
import 'package:dartcore/custom_templates.dart';

/// A CSS templating engine that supports:
/// - Variable substitution: {{ key }}
/// - Conditional blocks: {{ if condition }}...{{ endif }}
/// - Loops: {{ for item in list }}...{{ endfor }}
/// - Filters: {{ key | filterName }}
/// - Dynamic expression evaluation: {{ if width < 500 }}...{{ endif }}
class CssTemplateEngine implements CustomTemplateEngine {
  @override
  ContentType contentType() => ContentType("text", "css");

  @override
  String render(String template, Map<String, dynamic> context) {
    var result = template;
    result = _handleFilters(result, context);
    result = _handleVariables(result, context);
    result = _handleConditionals(result, context);
    result = _handleLoops(result, context);

    return result;
  }

  String _handleFilters(String template, Map<String, dynamic> context) {
    final filterPattern = RegExp(r'\{\{ (.*?) \| (.*?) \}\}');

    return template.replaceAllMapped(filterPattern, (match) {
      final variable = match.group(1)?.trim();
      final filterName = match.group(2)?.trim();

      if (variable != null && filterName != null) {
        var value = context[variable];
        if (value != null) {
          return _applyFilter(value, filterName);
        }
      }
      return match.group(0) ?? '';
    });
  }

  String _applyFilter(dynamic value, String filterName) {
    switch (filterName) {
      case 'upper':
        return value.toString().toUpperCase();
      case 'lower':
        return value.toString().toLowerCase();
      case 'capital':
        return _capitalize(value.toString());
      case 'date':
        return _formatDate(value);
      case 'num':
        return _numberFormat(value);
      default:
        return value.toString();
    }
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  String _formatDate(dynamic value) {
    if (value is DateTime) {
      return '${value.year}-${value.month}-${value.day}';
    }
    return value.toString();
  }

  String _numberFormat(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _handleConditionals(String template, Map<String, dynamic> context) {
    final conditionPattern =
        RegExp(r'\{\{ if (.*?) \}\}(.*?)\{\{ endif \}\}', dotAll: true);
    return template.replaceAllMapped(conditionPattern, (match) {
      final condition = match.group(1)?.trim();
      final block = match.group(2)?.trim();
      if (_evaluateCondition(condition!, context)) {
        return block ?? '';
      } else {
        return '';
      }
    });
  }

  bool _evaluateCondition(String condition, Map<String, dynamic> context) {
    try {
      final expression = _parseCondition(condition);
      return expression(context);
    } catch (e) {
      print('[dartcore] Error evaluating condition: $e');
      return false;
    }
  }

  bool Function(Map<String, dynamic>) _parseCondition(String condition) {
    final comparisonPattern = RegExp(r'(\w+)\s*([<=>!]+)\s*(\d+)');
    final match = comparisonPattern.firstMatch(condition);

    if (match != null) {
      final variable = match.group(1);
      final operator = match.group(2);
      final value = int.tryParse(match.group(3)!);

      if (variable != null && value != null && operator != null) {
        return (context) {
          final variableValue = context[variable];
          if (variableValue is num) {
            switch (operator) {
              case '<':
                return variableValue < value;
              case '>':
                return variableValue > value;
              case '==':
                return variableValue == value;
              case '!=':
                return variableValue != value;
              case '<=':
                return variableValue <= value;
              case '>=':
                return variableValue >= value;
              default:
                return false;
            }
          }
          return false;
        };
      }
    }
    return (_) => false;
  }

  String _handleLoops(String template, Map<String, dynamic> context) {
    final loopPattern = RegExp(
        r'\{\{ for (.*?) in (.*?) \}\}(.*?)\{\{ endfor \}\}',
        dotAll: true);
    return template.replaceAllMapped(loopPattern, (match) {
      final variable = match.group(1)?.trim();
      final listName = match.group(2)?.trim();
      final block = match.group(3)?.trim();
      final list = context[listName];
      if (list is List && list.isNotEmpty) {
        return list.map((item) {
          var loopBlock = block;
          context[variable!] = item;
          loopBlock = _handleVariables(loopBlock!, context);
          return loopBlock;
        }).join('\n');
      }

      return '';
    });
  }

  String _handleVariables(String template, Map<String, dynamic> context) {
    context.forEach((key, value) {
      template = template.replaceAll('{{ $key }}', value.toString());
    });
    return template;
  }

  @override
  String toString() {
    return "CssTemplateEngine";
  }
}
