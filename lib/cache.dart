/// Cache Class
class Cache {
  final Map<String, dynamic> _cache = {};

  /// Retrieve an item from the cache
  dynamic get(String key) {
    return _cache[key];
  }

  /// Add or update an item in the cache
  void set(String key, dynamic value) {
    _cache[key] = value;
  }

  /// Remove an item from the cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear the cache
  void clear() {
    _cache.clear();
  }
}
