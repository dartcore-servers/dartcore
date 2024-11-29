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

  /// Country Blocker instance
  final CountryBlocker countryBlocker;

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
    required this.countryBlocker,
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

  /// Refreshes the rate limits, IP and Country block lists
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
    await File("$storagePath.country").writeAsString(countryBlocker.asJson());
  }

  /// Check if IP is rate limited
  Future<bool> isRateLimited(String clientIp) async {
    // First, it gonna check if the IP is blocked
    if (ipBlocker.isIpBlocked(clientIp)) {
      return true;
    }

    await File("$storagePath.country").writeAsString(countryBlocker.asJson());

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
