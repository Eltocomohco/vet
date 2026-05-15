import 'package:firebase_auth/firebase_auth.dart';

/// Servicio que gestiona la autenticación con Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el usuario actual autenticado
  User? get currentUser => _auth.currentUser;

  /// Stream que emite cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicia sesión con email y contraseña
  /// Retorna el UserCredential si es exitoso
  /// Lanza FirebaseAuthException si hay error
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: $e');
    }
  }

  /// Registra un nuevo usuario con email y contraseña
  /// Retorna el UserCredential si es exitoso
  /// Lanza FirebaseAuthException si hay error
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error inesperado al registrar usuario: $e');
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Envía un email para restablecer la contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error al enviar email de restablecimiento: $e');
    }
  }

  /// Actualiza el nombre de visualización del usuario
  Future<void> updateDisplayName(String displayName) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
      } else {
        throw Exception('No hay usuario autenticado');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error al actualizar el nombre: $e');
    }
  }

  /// Actualiza el email del usuario actual
  Future<void> updateEmail(String newEmail) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail.trim());
      } else {
        throw Exception('No hay usuario autenticado');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error al actualizar el email: $e');
    }
  }

  /// Actualiza la contraseña del usuario actual
  Future<void> updatePassword(String newPassword) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No hay usuario autenticado');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error al actualizar la contraseña: $e');
    }
  }

  /// Reautentica al usuario (necesario para operaciones sensibles)
  Future<void> reauthenticate(String password) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw Exception('No hay usuario autenticado');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error al reautenticar: $e');
    }
  }

  /// Elimina la cuenta del usuario actual
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw Exception('No hay usuario autenticado');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error al eliminar la cuenta: $e');
    }
  }

  /// Envía un email de verificación al usuario actual
  Future<void> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Error al enviar email de verificación: $e');
    }
  }

  /// Verifica si el email del usuario está verificado
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Obtiene el token ID del usuario actual
  Future<String?> getIdToken() async {
    try {
      final User? user = _auth.currentUser;
      return await user?.getIdToken();
    } catch (e) {
      return null;
    }
  }

  /// Procesa los errores de Firebase Auth y retorna excepciones con mensajes legibles
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No existe una cuenta con este email.');
      case 'wrong-password':
        return Exception('Contraseña incorrecta.');
      case 'invalid-email':
        return Exception('El email no tiene un formato válido.');
      case 'user-disabled':
        return Exception('Esta cuenta ha sido deshabilitada.');
      case 'email-already-in-use':
        return Exception('Ya existe una cuenta con este email.');
      case 'operation-not-allowed':
        return Exception('Operación no permitida.');
      case 'weak-password':
        return Exception('La contraseña es demasiado débil.');
      case 'invalid-credential':
        return Exception('Credenciales inválidas.');
      case 'too-many-requests':
        return Exception(
            'Demasiados intentos fallidos. Intente más tarde.');
      case 'network-request-failed':
        return Exception('Error de red. Verifique su conexión a internet.');
      case 'requires-recent-login':
        return Exception(
            'Esta operación requiere autenticación reciente. Inicie sesión nuevamente.');
      case 'account-exists-with-different-credential':
        return Exception(
            'Ya existe una cuenta con este email usando otro método de inicio de sesión.');
      default:
        return Exception('Error de autenticación: ${e.message ?? e.code}');
    }
  }
}
