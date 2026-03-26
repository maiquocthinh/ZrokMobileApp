import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _tokenPrefix = 'env_token_';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String envId, String token) async {
    await _storage.write(key: '$_tokenPrefix$envId', value: token);
  }

  Future<String?> readToken(String envId) async {
    return await _storage.read(key: '$_tokenPrefix$envId');
  }

  Future<void> deleteToken(String envId) async {
    await _storage.delete(key: '$_tokenPrefix$envId');
  }

  Future<bool> hasToken(String envId) async {
    return await _storage.containsKey(key: '$_tokenPrefix$envId');
  }
}
