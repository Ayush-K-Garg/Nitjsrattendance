import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    final password = await _storage.read(key: _keyPassword);

    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}

