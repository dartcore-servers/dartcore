/// EventEmitter class
class EventEmitter {
  final Map<String, List<Function(dynamic)>> _listeners = {};

  /// Adds a listener for a specific event.
  ///
  /// - Parameters:
  ///   - event: The name of the event to listen for.
  ///   - listener: The function to call when the event is emitted.
  void on(String event, Function(dynamic) listener) {
    _listeners.putIfAbsent(event, () => []).add(listener);
  }

  /// Removes a listener for a specific event.
  ///
  /// - Parameters:
  ///   - event: The name of the event to remove the listener for.
  ///   - listener: The function to remove from the listeners.
  void off(String event, Function(dynamic) listener) {
    _listeners[event]?.remove(listener);
    if (_listeners[event]?.isEmpty ?? false) {
      _listeners.remove(event);
    }
  }

  /// Emits an event, calling all registered listeners.
  ///
  /// - Parameters:
  ///   - event: The name of the event to emit.
  ///   - data: The data to pass to the listeners.
  void emit(String event, [dynamic data]) {
    for (var listener in _listeners[event] ?? []) {
      listener(data);
    }
  }
}
