import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uts_1123150004/core/services/secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Check if the device has biometric hardware and it is enabled
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  // Check if biometric login is enabled by the user in settings
  Future<bool> isBiometricEnabled() async {
    return SecureStorage.isBiometricEnabled();
  }

  // Set biometric login enabled status
  Future<void> setBiometricEnabled(bool enabled) async {
    await SecureStorage.setBiometricEnabled(enabled);
  }

  // Save credentials for biometric login
  Future<void> saveCredentials(String email, String password) async {
    await SecureStorage.saveBiometricCredentials(email, password);
  }

  // Get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    return SecureStorage.getBiometricCredentials();
  }

  // Clear credentials
  Future<void> clearCredentials() async {
    await SecureStorage.clearBiometricCredentials();
  }

  // Perform authentication
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah Anda untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('[BiometricService] PlatformException: ${e.code} - ${e.message}');
      return false;
    }
  }
}
