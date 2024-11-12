import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aes256/aes256.dart';

/// RateLimiter class for rate limiting requests
class RateLimiter {
  /// File for IPs
  final String storagePath;

  /// Max requests
  final int maxRequests;

  /// Reset duration
  final Duration resetDuration;

  /// Encryption Key for IPs
  final String encryptionPassword;

  Map<String, List<DateTime>> _requests = {};

  /// Constructor
  RateLimiter({
    required this.storagePath,
    required this.maxRequests,
    required this.resetDuration,
    required this.encryptionPassword,
  }) {
    _loadRequests();
  }

  void _loadRequests() async {
    final file = File(storagePath);
    if (await file.exists()) {
      final contents = await file.readAsString();
      final decrypted = await Aes256.decrypt(contents, encryptionPassword);
      _requests = Map<String, List<DateTime>>.from(
        jsonDecode(decrypted!).map((key, value) {
          return MapEntry(
              key, List<DateTime>.from(value.map((e) => DateTime.parse(e))));
        }),
      );
    }
  }

  Future<void> _saveRequests() async {
    final file = File(storagePath);
    String encrypted = "";
    final Map<String, List<String>> requestsForJson = {
      for (var entry in _requests.entries)
        entry.key:
            entry.value.map((dateTime) => dateTime.toIso8601String()).toList(),
    };

    if (await file.exists()) {
      final contents = await file.readAsString();
      encrypted = await Aes256.encrypt(
          ((!contents.startsWith("{"))
              ? await Aes256.decrypt(
                  await file.readAsString(), encryptionPassword)
              : (jsonEncode(requestsForJson)))!,
          encryptionPassword);
    }
    if (encrypted.isEmpty) {
      await file.writeAsString(jsonEncode(requestsForJson));
    }
    if (encrypted.isNotEmpty) {
      await file.writeAsString(encrypted);
    }
  }

  /// Check if IP is rate limited
  bool isRateLimited(String clientIp) {
    final now = DateTime.now();
    _requests[clientIp] ??= [];
    _requests[clientIp]!
        .removeWhere((time) => now.difference(time) > resetDuration);

    if (_requests[clientIp]!.length < maxRequests) {
      _requests[clientIp]!.add(now);
      _saveRequests();
      return false;
    }
    return true;
  }
}
