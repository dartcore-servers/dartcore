/// SSL Options
/// [keyFile] - path to the key file
/// [certificate] - path to the certificate
class SSLOptions {
  /// Path to the key file
  final String keyFile;

  /// Path to the certificate
  final String certificate;

  /// Constructor
  SSLOptions({required this.keyFile, required this.certificate});
}
