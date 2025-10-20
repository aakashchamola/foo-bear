import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import '../utils/constants.dart';

class EncryptionService {
  static final _key =
      Key.fromBase64(base64.encode(AppConstants.encryptionKey.codeUnits));
  static final _iv = IV.fromSecureRandom(16);
  static final _encrypter = Encrypter(AES(_key));

  // Encrypt text
  static String encryptText(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // Decrypt text
  static String decryptText(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  // Encrypt bytes (for images)
  static Uint8List encryptBytes(Uint8List data) {
    final plainText = base64.encode(data);
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return base64.decode(encrypted.base64);
  }

  // Decrypt bytes (for images)
  static Uint8List decryptBytes(Uint8List encryptedData) {
    final encryptedText = base64.encode(encryptedData);
    final encrypted = Encrypted.fromBase64(encryptedText);
    final decryptedText = _encrypter.decrypt(encrypted, iv: _iv);
    return base64.decode(decryptedText);
  }

  // Generate a secure random key
  static String generateSecureKey() {
    return Key.fromSecureRandom(32).base64;
  }

  // Generate a secure random IV
  static String generateSecureIV() {
    return IV.fromSecureRandom(16).base64;
  }

  // Encrypt with custom key and IV
  static String encryptWithCustomKey(
      String plainText, String keyBase64, String ivBase64) {
    final key = Key.fromBase64(keyBase64);
    final iv = IV.fromBase64(ivBase64);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  // Decrypt with custom key and IV
  static String decryptWithCustomKey(
      String encryptedText, String keyBase64, String ivBase64) {
    final key = Key.fromBase64(keyBase64);
    final iv = IV.fromBase64(ivBase64);
    final encrypter = Encrypter(AES(key));
    final encrypted = Encrypted.fromBase64(encryptedText);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Hash password (for passcode verification)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password + AppConstants.encryptionKey);
    return base64.encode(bytes);
  }

  // Verify password hash
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
