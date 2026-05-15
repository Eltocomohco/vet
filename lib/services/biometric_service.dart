import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio que gestiona la autenticación biométrica (huella/Face ID)
/// y el almacenamiento seguro de preferencias biométricas.
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricUserId = 'biometric_user_id';

  /// Verifica si el dispositivo soporta biometría
  static Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Verifica si hay biometrías registradas (huellas/Face ID)
  static Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final List<BiometricType> available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Devuelve los tipos de biometría disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Solicita autenticación biométrica al usuario
  static Future<bool> authenticate({String reason = 'Desbloquea VetClick'}) async {
    if (kIsWeb) return false;
    try {
      if (!await canCheckBiometrics()) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false, // permite PIN/patrón como fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Guarda que el usuario ha activado el desbloqueo biométrico
  static Future<void> setBiometricEnabled(String userId, bool enabled) async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: enabled ? 'true' : 'false');
    if (enabled) {
      await _secureStorage.write(key: _keyBiometricUserId, value: userId);
    } else {
      await _secureStorage.delete(key: _keyBiometricUserId);
    }
  }

  /// Indica si el usuario activó el desbloqueo biométrico
  static Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Obtiene el userId asociado a la biometría activada
  static Future<String?> getBiometricUserId() async {
    return await _secureStorage.read(key: _keyBiometricUserId);
  }

  /// Limpia todas las preferencias biométricas
  static Future<void> clearBiometricSettings() async {
    await _secureStorage.delete(key: _keyBiometricEnabled);
    await _secureStorage.delete(key: _keyBiometricUserId);
  }

  /// Devuelve un mensaje amigable según el tipo de biometría disponible
  static Future<String> getBiometricLabel() async {
    if (kIsWeb) return 'Biometría';
    final types = await getAvailableBiometrics();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (types.contains(BiometricType.face)) return 'Face ID';
      if (types.contains(BiometricType.fingerprint)) return 'Touch ID';
    }
    if (types.contains(BiometricType.strong)) return 'Huella dactilar';
    if (types.contains(BiometricType.weak)) return 'Desbloqueo biométrico';
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Huella dactilar';
    return 'Biometría';
  }
}
