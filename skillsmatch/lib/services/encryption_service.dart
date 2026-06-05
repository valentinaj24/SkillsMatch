import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final _key = Key.fromUtf8('12345678901234567890123456789012');
  static final _iv = IV.fromUtf8('1234567890123456');

  static final _encrypter = Encrypter(
    AES(_key, mode: AESMode.cbc),
  );

  static String encryptMessage(String text) {
    return _encrypter.encrypt(text, iv: _iv).base64;
  }

  static String decryptMessage(String encryptedText) {
    try {
      return _encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      print('DECRYPT ERROR: $e');
      return encryptedText;
    }
  }
}