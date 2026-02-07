import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _apiKeyKey = 'api_key';

  final FlutterSecureStorage _storage;

  Future<String?> readApiKey() async {
    try {
      return await _storage.read(key: _apiKeyKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> writeApiKey(String value) async {
    await _storage.write(key: _apiKeyKey, value: value);
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }
}
