import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // 32 karaktera = AES-256
  static final _key = Key.fromUtf8('12345678901234567890123456789012');

  static final _iv = IV.fromLength(16);

  static final _encrypter = Encrypter(AES(_key));

  static String encryptMessage(String text) {
    final encrypted = _encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  static String decryptMessage(String encryptedText) {
    try {
      final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      return '⚠️ Error decrypting';
    }
  }
}
