import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartcore/blocker.dart';
import 'package:dartcore/json_encryptor.dart';

/// RateLimiter class for rate limiting requests
class RateLimiter {
  /// File for IPs
  final String storagePath;

  /// IP Blocker instance
  final IPBlocker ipBlocker;

  /// Specifies if the captcha should be displayed when the rate limit is exceeded
  final bool shouldDisplayCaptcha;

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
    required this.ipBlocker,
    required this.shouldDisplayCaptcha,
  }) {
    _loadRequests();
  }

  void _loadRequests() async {
    final file = File(storagePath);
    if (await file.exists()) {
      Uint8List decrypted = Uint8List.fromList([0]);
      try {
        decrypted = await Encryptor().djson(
            utf8.encode(utf8.decode(await Encryptor()
                .ejson(utf8.encode('{"127.0.0.1": []}'), encryptionPassword))),
            encryptionPassword);
      } catch (e) {
        String executable = Platform.executable;
        List<String> executableArguments = [];
        String script = Platform.script.toFilePath(windows: Platform.isWindows);
        executableArguments.addAll(executableArguments);
        executableArguments.add(script);
        var process = await Process.start(executable, executableArguments,
            runInShell: false);
        var pid = process.pid;
        print(
            "[dartcore] Error decrypting rate limits.\n[dartcore] Starting the server in background.\n[dartcore] ProcessID: $pid");
        exit(1);
      }

      _requests = Map<String, List<DateTime>>.from(
        jsonDecode(utf8.decode(decrypted)).map((key, value) {
          return MapEntry(
              key, List<DateTime>.from(value.map((e) => DateTime.parse(e))));
        }),
      );
    }
  }

  /// Refreshes the rate limiter by saving the current request data to storage.
  ///
  /// This method ensures that the request data is persisted,
  /// allowing the rate limiter to maintain its state across restarts.
  Future<void> refresh() async {
    await _saveRequests();
  }

  Future<void> _saveRequests() async {
    final file = File(storagePath);
    Uint8List encrypted = Uint8List.fromList([0]);
    final Map<String, List<String>> requestsForJson = {
      for (var entry in _requests.entries)
        entry.key:
            entry.value.map((dateTime) => dateTime.toIso8601String()).toList(),
    };

    if (await file.exists()) {
      encrypted =
          await Encryptor().ejson(await file.readAsBytes(), encryptionPassword);
    }
    if (encrypted.isEmpty) {
      await file.writeAsString(jsonEncode(requestsForJson));
    }
    if (encrypted.isNotEmpty) {
      await file.writeAsBytes(encrypted);
    }

    // Saves the IP block list
    await File("$storagePath.ip").writeAsBytes(await Encryptor()
        .ejson(utf8.encode(ipBlocker.asJson()), encryptionPassword));
  }

  /// Checks if the client IP address is rate-limited.
  ///
  /// This function first checks if the given [clientIp] is in the blocked
  /// list using the IP blocker. If the IP is blocked, it returns `true`.
  /// Otherwise, it checks the number of requests associated with the [clientIp].
  /// If the number of requests exceeds the [maxRequests] within the
  /// [resetDuration], the function returns `true`, indicating that the IP is
  /// rate-limited. Otherwise, it records the current request and returns `false`.
  ///
  /// - Parameters:
  ///   - clientIp: The IP address of the client to check for rate limiting.
  ///
  /// - Returns: A `Future` that resolves to `true` if the IP is rate-limited,
  ///   or `false` if the IP is not rate-limited.
  Future<bool> isRateLimited(String clientIp) async {
    if (ipBlocker.isIpBlocked(clientIp)) {
      return true;
    }
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
