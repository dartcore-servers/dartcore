import 'dart:convert';
import 'dart:io';

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
      _settings.addAll(jsonDecode(jsonString));
    } else {
      print('[dartcore] Configuration file not found: $filePath');
    }
  }

  /// Get a config value
  dynamic get(String key) {
    return _settings[key];
  }
}
