import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _keyAppLock = "security_app_lock_enabled";
  static const String _keySecurityPin = "security_app_pin";
  static const String _keyBiometric = "security_biometric_enabled";

  /// Check if App Lock is enabled
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAppLock) ?? false;
  }

  /// Toggle App Lock enabled state
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLock, enabled);
  }

  /// Get current Security PIN
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySecurityPin);
  }

  /// Save new Security PIN
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySecurityPin, pin);
  }

  /// Verify entered PIN against saved PIN
  Future<bool> verifyPin(String enteredPin) async {
    final pin = await getPin();
    return pin != null && pin == enteredPin;
  }

  /// Check if Biometric Unlock is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometric) ?? false;
  }

  /// Toggle Biometric Unlock enabled state
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, enabled);
  }

  /// Check if device hardware supports biometrics (Fingerprint / Face ID)
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint("Biometric Availability Error: $e");
      return false;
    }
  }

  /// Get list of available biometric types (Fingerprint, Face, Weak, Strong)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint("Get Biometrics Error: $e");
      return [];
    }
  }

  /// Trigger Biometric Authentication Prompt (Fingerprint / Face Unlock)
  Future<bool> authenticateWithBiometrics({
    String reason = "Scan Fingerprint or Face to unlock Expense Tracker",
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Authentication Error: $e");
      return false;
    }
  }
}
