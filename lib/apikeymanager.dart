import 'package:dartcore/apikey.dart';
import 'package:uuid/uuid.dart';

/// APIKeyManager class
class ApiKeyManager {
  final Set<ApiKey> _apiKeys = {};
  final Uuid _uuid = Uuid();

  /// Generates a new API key, optionally with an expiration date, and adds it
  /// to the set of managed API keys.
  ///
  /// - Parameters:
  ///   - expiresAt: The optional expiration date of the API key.
  ///
  /// - Returns: The newly generated API key.
  ApiKey generateApiKey({DateTime? expiresAt}) {
    final key = _uuid.v4();
    final apiKey =
        ApiKey(key: key, createdAt: DateTime.now(), expiresAt: expiresAt);
    _apiKeys.add(apiKey);
    return apiKey;
  }

  /// Checks if an API key is valid and not expired.
  ///
  /// - Parameters:
  ///   - key: The API key to be validated.
  ///
  /// - Returns: `true` if the API key is valid, `false` otherwise.
  bool validateApiKey(String key) {
    return _apiKeys.any((apiKey) =>
        apiKey.key == key &&
        (apiKey.expiresAt == null ||
            apiKey.expiresAt!.isAfter(DateTime.now())));
  }

  /// Revokes the API key with the given [key].
  ///
  /// - Parameters:
  ///   - key: The API key to be revoked.
  ///
  /// - Returns: `void`.
  void revokeApiKey(String key) {
    _apiKeys.removeWhere((apiKey) => apiKey.key == key);
  }
}
