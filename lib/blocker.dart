import 'dart:convert';

/// IPBlocker class
class IPBlocker {
  /// Set of blocked IP addresses
  final Set<String> blockedIps = {};

  /// Checks if an IP address is blocked
  bool isIpBlocked(String ip) {
    return blockedIps.contains(ip);
  }

  /// Blocks an IP address
  void blockIp(String ip) {
    blockedIps.add(ip);
  }

  /// Unblocks an IP address
  void unblockIp(String ip) {
    blockedIps.remove(ip);
  }

  /// Clears the IP block list
  void clear() {
    blockedIps.clear();
  }

  /// Returns the number of blocked IP addresses
  int get count => blockedIps.length;

  /// Returns a list of blocked IP addresses
  List<String> get blockedIpsList => blockedIps.toList();

  /// Returns a string representation of the IP block list
  String asJson() {
    return jsonEncode(blockedIps.toList());
  }

  /// Loads the IP block list from a JSON string
  /// NOTE: THIS WILL CLEAR ALL THE IP BLOCKS
  void fromJson(String json) {
    blockedIps.clear();
    blockedIps.addAll(jsonDecode(json) as Iterable<String>);
  }
}

/// CountryBlocker class
/// useful for geo-blocking
class CountryBlocker {
  /// Set of blocked countries
  final Set<String> blocked = {};

  /// Blocks a country
  /// uses country code
  /// e.g. US, IQ, CN, RU, etc..
  void block(String country) {
    blocked.add(country);
    print("[dartcore] Blocked Country: $country");
  }

  /// Unblocks a country
  void unblock(String country) {
    blocked.remove(country);
  }

  /// Clears the country block list
  void clear() {
    blocked.clear();
  }

  /// Returns the number of blocked countries
  int get count => blocked.length;

  /// Returns a list of blocked countries
  List<String> get blockedList => blocked.toList();

  /// Returns a string representation of the country block list
  String asJson() {
    return jsonEncode(blocked.toList());
  }

  /// Loads the country block list from a JSON string
  /// NOTE: THIS WILL CLEAR ALL THE COUNTRY BLOCKS
  void fromJson(String json) {
    blocked.clear();
    blocked.addAll(jsonDecode(json) as Iterable<String>);
  }
}
