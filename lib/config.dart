import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:toml/toml.dart';

/// Config class
class Config {
  final Map<String, dynamic> _settings = {};

  /// Config constructor
  Config(String filePath) {
    _loadConfig(filePath);
  }

  void _loadConfig(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      final jsonString = file.readAsStringSync();
      if (filePath.endsWith('.json')) {
        _settings.addAll(jsonDecode(jsonString));
      } else if (filePath.endsWith('.yaml')) {
        _settings.addAll(loadYaml(jsonString));
      } else if (filePath.endsWith('.toml')) {
        var config = TomlDocument.parse(jsonString).toMap();
        _settings.addAll(config);
      } else {
        print('[dartcore] Invalid configuration file format: $filePath');
      }
    } else {
      print(
          '[dartcore] Configuration file not found: ${filePath.replaceFirst("", "null")}');
    }
  }

  /// Get a config value
  dynamic get(String key) {
    return _settings[key];
  }
}
