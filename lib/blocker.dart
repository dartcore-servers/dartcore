import 'dart:convert';

/// IPBlocker class
class IPBlocker {
  /// Set of blocked IP addresses
  final Set<String> blockedIps = {};

  /// Checks if the given IP address is blocked.
  ///
  /// Returns `true` if the IP address is in the blocked list, otherwise `false`.
  bool isIpBlocked(String ip) {
    return blockedIps.contains(ip);
  }

  /// Blocks an IP address
  //
  /// Adds the given [ip] to the blocked list, so that any incoming request
  /// from this IP address will be blocked.
  ///
  /// If the IP address is already in the blocked list, this method does
  /// nothing.
  void blockIp(String ip) {
    blockedIps.add(ip);
  }

  /// Unblocks an IP address
  //
  /// Removes the given [ip] from the blocked list, so that any incoming request
  /// from this IP address will no longer be blocked.
  //
  /// If the IP address is not in the blocked list, this method does
  /// nothing.
  void unblockIp(String ip) {
    blockedIps.remove(ip);
  }

  /// Clears the list of blocked IP addresses.
  ///
  /// This method removes all IP addresses from the blocked list,
  /// allowing requests from any IP address that was previously blocked.
  void clear() {
    blockedIps.clear();
  }

  /// Returns the number of blocked IP addresses
  int get count => blockedIps.length;

  /// Returns a list of blocked IP addresses
  List<String> get blockedIpsList => blockedIps.toList();

  /// Returns the IP block list as a JSON string
  ///
  /// The JSON string is a list of IP addresses.
  String asJson() {
    return jsonEncode(blockedIps.toList());
  }

  /// Loads the IP block list from a JSON string
  //
  /// The JSON string should contain a list of IP addresses. This method
  /// clears the current list of blocked IP addresses and replaces it with
  /// the list of IP addresses in the JSON string.
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
  ///
  /// Adds the given [country] to the blocked list, preventing any requests
  /// from this country. Logs the blocked country to the console.
  void block(String country) {
    blocked.add(country);
    print("[dartcore] Blocked Country: $country");
  }

  /// Unblocks a country
  ///
  /// Removes the given [country] from the blocked list, allowing requests from
  /// this country. If the country is not in the blocked list, this method does
  /// nothing.
  void unblock(String country) {
    blocked.remove(country);
  }

  /// Clears all blocked countries.
  ///
  /// This method removes all countries from the blocked list, allowing requests
  /// from any country that was previously blocked.
  void clear() {
    blocked.clear();
  }

  /// Returns the number of blocked countries
  int get count => blocked.length;

  /// Returns a list of blocked countries
  List<String> get blockedList => blocked.toList();

  /// Returns the country block list as a JSON string
  ///
  /// The JSON string is a list of country codes (e.g. "US", "CA", "UK", etc.).
  String asJson() {
    return jsonEncode(blocked.toList());
  }

  /// Loads the country block list from a JSON string.
  ///
  /// The JSON string should contain a list of country codes.
  /// This method clears the current list of blocked countries and
  /// replaces it with the list of country codes in the JSON string.
  void fromJson(String json) {
    blocked.clear();
    blocked.addAll(jsonDecode(json) as Iterable<String>);
  }
}
