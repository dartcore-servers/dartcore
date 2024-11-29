import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// A class for encrypting and decrypting JSON data using AES
class Encryptor {
  /// Encrypts JSON data using AES and returns the encrypted bytes
  Future<Uint8List> ejson(Uint8List jsonData, String password) async {
    final key = _generateKey(password);
    final iv = encrypt.IV.fromLength(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encryptedChunks = <Uint8List>[];
    for (int i = 0; i < jsonData.length; i += 4096) {
      final chunk = jsonData.sublist(
          i, i + 4096 > jsonData.length ? jsonData.length : i + 4096);
      final encryptedChunk = encrypter.encryptBytes(chunk, iv: iv);
      encryptedChunks.add(Uint8List.fromList(encryptedChunk.bytes));
    }
    final result = Uint8List.fromList(
        iv.bytes + encryptedChunks.expand((e) => e).toList());
    return result;
  }

  /// Decrypts JSON data using AES and returns the decrypted bytes
  Future<Uint8List> djson(Uint8List encryptedData, String password) async {
    final key = _generateKey(password);
    final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    final encryptedContent = encryptedData.sublist(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decryptedChunks = <Uint8List>[];
    for (int i = 0; i < encryptedContent.length; i += 4096) {
      final chunk = encryptedContent.sublist(
          i,
          i + 4096 > encryptedContent.length
              ? encryptedContent.length
              : i + 4096);
      final decryptedChunk =
          encrypter.decryptBytes(encrypt.Encrypted(chunk), iv: iv);
      decryptedChunks.add(Uint8List.fromList(decryptedChunk));
    }
    final result =
        Uint8List.fromList(decryptedChunks.expand((e) => e).toList());
    return result;
  }

  encrypt.Key _generateKey(String password) {
    final hashedPassword = sha256.convert(utf8.encode(password)).bytes;
    return encrypt.Key(Uint8List.fromList(hashedPassword));
  }
}
