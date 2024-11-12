/// ApiKey model class
class ApiKey {
  /// API Key
  final String key;

  /// API Key creation date
  final DateTime createdAt;

  /// API Key expiration date
  final DateTime? expiresAt;

  /// API Key requires a key, creation date and expiration date
  ApiKey({required this.key, required this.createdAt, this.expiresAt});
}
