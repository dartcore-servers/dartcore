/// EventEmitter class
class EventEmitter {
  final Map<String, List<Function(dynamic)>> _listeners = {};

  /// Adds a listener for a specific event.
  void on(String event, Function(dynamic) listener) {
    _listeners.putIfAbsent(event, () => []).add(listener);
  }

  /// Removes a listener for a specific event.
  void off(String event, Function(dynamic) listener) {
    _listeners[event]?.remove(listener);
    if (_listeners[event]?.isEmpty ?? false) {
      _listeners.remove(event);
    }
  }

  /// Emits an event, calling all registered listeners.
  void emit(String event, [dynamic data]) {
    for (var listener in _listeners[event] ?? []) {
      listener(data);
    }
  }
}
