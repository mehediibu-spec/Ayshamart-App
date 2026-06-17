import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted persistence for the customer's JWT. Uses the platform keystore
/// (Android EncryptedSharedPreferences / iOS Keychain) — never plain prefs.
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'ayshamart_jwt';

  Future<void> save(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
