import 'package:dartcore/apikey.dart';
import 'package:uuid/uuid.dart';

/// APIKeyManager class
class ApiKeyManager {
  final Set<ApiKey> _apiKeys = {};
  final Uuid _uuid = Uuid();

  /// Generates an API key using a UUID v4
  ApiKey generateApiKey({DateTime? expiresAt}) {
    final key = _uuid.v4();
    final apiKey =
        ApiKey(key: key, createdAt: DateTime.now(), expiresAt: expiresAt);
    _apiKeys.add(apiKey);
    return apiKey;
  }

  /// Validates an API key
  bool validateApiKey(String key) {
    return _apiKeys.any((apiKey) =>
        apiKey.key == key &&
        (apiKey.expiresAt == null ||
            apiKey.expiresAt!.isAfter(DateTime.now())));
  }

  /// Revokes an API Key
  void revokeApiKey(String key) {
    _apiKeys.removeWhere((apiKey) => apiKey.key == key);
  }
}
