/// Cache Class
class Cache {
  final Map<String, dynamic> _cache = {};

  /// Retrieves an item from the cache
  ///
  /// - Parameters:
  ///   - key: The key of the item to retrieve
  ///
  /// - Returns: The item associated with the key, or null if the key is not in the cache
  dynamic get(String key) {
    return _cache[key];
  }

  /// Stores an item in the cache
  ///
  /// - Parameters:
  ///   - key: The key to store the item under
  ///   - value: The value to store
  void set(String key, dynamic value) {
    _cache[key] = value;
  }

  /// Removes an item from the cache
  ///
  /// - Parameters:
  ///   - key: The key of the item to remove
  void remove(String key) {
    _cache.remove(key);
  }

  /// Removes all items from the cache
  void clear() {
    _cache.clear();
  }
}
