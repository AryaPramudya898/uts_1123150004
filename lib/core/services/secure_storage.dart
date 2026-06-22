import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken = 'auth_token';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyBiometricEmail = 'biometric_email';
  static const _keyBiometricPassword = 'biometric_password';
  static const _keyWalletConnected = 'wallet_connected';

  static Future<void> saveToken(String token) async =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> getToken() async => _storage.read(key: _keyToken);

  static Future<void> setBiometricEnabled(bool enabled) async =>
      _storage.write(key: _keyBiometricEnabled, value: enabled.toString());

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  static Future<void> setWalletConnected(bool connected) async =>
      _storage.write(key: _keyWalletConnected, value: connected.toString());

  static Future<bool> isWalletConnected() async {
    final val = await _storage.read(key: _keyWalletConnected);
    return val == 'true';
  }

  static Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(key: _keyBiometricEmail, value: email);
    await _storage.write(key: _keyBiometricPassword, value: password);
  }

  static Future<Map<String, String>?> getBiometricCredentials() async {
    final email = await _storage.read(key: _keyBiometricEmail);
    final password = await _storage.read(key: _keyBiometricPassword);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  static Future<void> clearBiometricCredentials() async {
    await _storage.delete(key: _keyBiometricEmail);
    await _storage.delete(key: _keyBiometricPassword);
    await _storage.delete(key: _keyBiometricEnabled);
  }

  static Future<void> clearAll() async => _storage.deleteAll();
}
