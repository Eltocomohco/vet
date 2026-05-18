import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/models/usuario.dart';
import 'package:vetmanager/services/auth_service.dart';
import 'package:vetmanager/services/logger_service.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Provider que gestiona el estado de autenticación del usuario
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  Usuario? _usuario;
  bool _cargando = false;
  bool _modoDemo = false;

  /// Usuario de Firebase actual
  User? get firebaseUser => _firebaseUser;

  /// Usuario del modelo de la aplicación
  Usuario? get usuario => _usuario;

  /// Indica si se está cargando información
  bool get cargando => _cargando;

  /// Indica si está en modo demo
  bool get modoDemo => _modoDemo;

  /// Indica si hay un usuario autenticado
  /// NOTA: Ahora solo requiere FirebaseUser para permitir usuarios que existen
  /// en Auth pero aun no tienen documento en Firestore (se crea automaticamente)
  bool get estaAutenticado => _modoDemo || (_firebaseUser != null);

  /// ID de la clínica asociada al usuario
  String? get clinicaId => _usuario?.clinicaId;

  /// Indica si el usuario tiene rol de administrador
  bool get esAdmin => _usuario?.esAdmin ?? false;

  /// Indica si el usuario tiene rol de veterinario
  bool get esVeterinario => _usuario?.esVeterinario ?? false;

  /// Indica si el usuario es recepcionista
  bool get esRecepcionista => _usuario?.esRecepcionista ?? false;

  /// Indica si el usuario puede gestionar citas
  bool get puedeGestionarCitas => _usuario?.puedeGestionarCitas ?? false;

  /// Indica si el usuario puede editar configuración
  bool get puedeEditarConfiguracion =>
      _usuario?.puedeEditarConfiguracion ?? false;

  /// Nombre del usuario autenticado
  String get nombreUsuario => _usuario?.nombre ?? _firebaseUser?.displayName ?? 'Usuario';

  /// Email del usuario autenticado
  String? get emailUsuario => _firebaseUser?.email;

  /// ID del usuario autenticado
  String? get userId => _firebaseUser?.uid;

  AuthProvider() {
    _iniciarEscuchaAuth();
  }

  /// Inicia la escucha de cambios en el estado de autenticación
  void _iniciarEscuchaAuth() {
    _cargando = true;
    notifyListeners();

    _authSubscription = _authService.authStateChanges.listen(
      (User? user) async {
        if (_modoDemo && user != null) {
          // Modo demo: ya creamos el usuario manualmente, solo actualizar referencia
          _firebaseUser = user;
        } else {
          _firebaseUser = user;

          if (user != null) {
            await _cargarUsuarioFirestore(user.uid);
          } else {
            _usuario = null;
          }
        }

        _cargando = false;
        notifyListeners();
      },
      onError: (Object error) {
        _cargando = false;
        notifyListeners();
        debugPrint('Error en authStateChanges: $error');
      },
    );
  }

  /// Carga los datos del usuario desde Firestore.
  /// Si no existe, crea un documento basico automaticamente.
  Future<void> _cargarUsuarioFirestore(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(coleccionUsuarios)
          .doc(userId)
          .get();

      if (doc.exists) {
        _usuario = Usuario.fromFirestore(doc);
      } else {
        // Usuario existe en Auth pero no en Firestore → crear documento basico
        LoggerService.warn('Usuario $userId no encontrado en Firestore. Creando documento basico...', tag: 'AUTH');
        final User? currentUser = _authService.currentUser;
        final String email = currentUser?.email ?? '';
        final String nombre = currentUser?.displayName ?? email.split('@').first;

        final Usuario nuevoUsuario = Usuario(
          id: userId,
          email: email,
          nombre: nombre,
          rol: rolAdmin, // Por defecto admin si se crea automaticamente
          clinicaId: '', // Vacio hasta que cree una clinica
          telefono: currentUser?.phoneNumber,
          activo: true,
        );

        await _firestore
            .collection(coleccionUsuarios)
            .doc(userId)
            .set(nuevoUsuario.toFirestore());

        _usuario = nuevoUsuario;
        LoggerService.info('Usuario $userId creado automaticamente en Firestore', tag: 'AUTH');
      }
    } catch (e, stack) {
      LoggerService.error('Error al cargar/crear usuario en Firestore',
          tag: 'AUTH', exception: e, stackTrace: stack);
      _usuario = null;
    }
  }

  /// Inicia sesión con email y contraseña
  /// Retorna true si el login fue exitoso
  Future<bool> login(String email, String password) async {
    try {
      _cargando = true;
      notifyListeners();

      final UserCredential userCredential =
          await _authService.signInWithEmail(email, password);

      if (userCredential.user != null) {
        await _cargarUsuarioFirestore(userCredential.user!.uid);
        _firebaseUser = userCredential.user;

        _cargando = false;
        notifyListeners();
        return true;
      }

      _cargando = false;
      notifyListeners();
      return false;
    } catch (e, stack) {
      _cargando = false;
      notifyListeners();
      LoggerService.error('Error en login', tag: 'AUTH', exception: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Registra un nuevo usuario con email y contraseña
  /// Retorna el ID del usuario creado
  Future<String?> register({
    required String email,
    required String password,
    required String nombre,
    required String rol,
    required String clinicaId,
    String? telefono,
  }) async {
    try {
      _cargando = true;
      notifyListeners();

      final UserCredential userCredential =
          await _authService.registerWithEmail(email, password, nombre);

      if (userCredential.user != null) {
        await crearUsuarioEnFirestore(
          userId: userCredential.user!.uid,
          email: email,
          nombre: nombre,
          rol: rol,
          clinicaId: clinicaId,
          telefono: telefono,
        );

        _firebaseUser = userCredential.user;
        await _cargarUsuarioFirestore(userCredential.user!.uid);

        _cargando = false;
        notifyListeners();
        return userCredential.user!.uid;
      }

      _cargando = false;
      notifyListeners();
      return null;
    } catch (e, stack) {
      _cargando = false;
      notifyListeners();
      LoggerService.error('Error en registro', tag: 'AUTH', exception: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Crea un documento de usuario en Firestore
  Future<void> crearUsuarioEnFirestore({
    required String userId,
    required String email,
    required String nombre,
    required String rol,
    required String clinicaId,
    String? telefono,
  }) async {
    try {
      final Usuario nuevoUsuario = Usuario(
        id: userId,
        email: email,
        nombre: nombre,
        rol: rol,
        clinicaId: clinicaId,
        telefono: telefono,
        activo: true,
      );

      await _firestore
          .collection(coleccionUsuarios)
          .doc(userId)
          .set(nuevoUsuario.toFirestore());

      _usuario = nuevoUsuario;
      notifyListeners();
    } catch (e, stack) {
      LoggerService.error('Error al crear usuario en Firestore',
          tag: 'AUTH', exception: e, stackTrace: stack);
      throw Exception('Error al crear usuario en Firestore: $e');
    }
  }

  /// Actualiza el rol de un usuario en Firestore
  Future<void> actualizarRol(String userId, String nuevoRol) async {
    try {
      await _firestore.collection(coleccionUsuarios).doc(userId).update({
        'rol': nuevoRol,
      });

      if (_usuario != null && _usuario!.id == userId) {
        await _cargarUsuarioFirestore(userId);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al actualizar el rol: $e');
    }
  }

  /// Actualiza el estado activo de un usuario
  Future<void> actualizarEstadoActivo(String userId, bool activo) async {
    try {
      await _firestore.collection(coleccionUsuarios).doc(userId).update({
        'activo': activo,
      });

      if (_usuario != null && _usuario!.id == userId) {
        await _cargarUsuarioFirestore(userId);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al actualizar el estado del usuario: $e');
    }
  }

  /// Entra en modo demo con datos de prueba.
  /// Usa autenticación anónima real para que Firestore acepte las operaciones.
  Future<void> entrarModoDemo() async {
    try {
      _cargando = true;
      notifyListeners();

      final userCredential = await _authService.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        _modoDemo = true;
        _firebaseUser = user;

        final demoUsuario = Usuario(
          id: user.uid,
          nombre: 'Veterinario Demo',
          email: 'demo@vetclick.app',
          rol: rolAdmin,
          clinicaId: 'demo-clinica',
          telefono: '600123456',
          activo: true,
        );

        await _firestore
            .collection(coleccionUsuarios)
            .doc(user.uid)
            .set(demoUsuario.toFirestore(), SetOptions(merge: true));

        _usuario = demoUsuario;
        LoggerService.info('Modo demo activado con auth anónima: ${user.uid}', tag: 'AUTH');
      }

      _cargando = false;
      notifyListeners();
    } catch (e, stack) {
      _modoDemo = false;
      _cargando = false;
      notifyListeners();
      LoggerService.error('Error al entrar en modo demo', tag: 'AUTH', exception: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      _cargando = true;
      notifyListeners();

      await _authService.signOut();
      _firebaseUser = null;
      _usuario = null;
      _modoDemo = false;

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _modoDemo = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Envía un email para restablecer la contraseña
  Future<void> resetPassword(String email) async {
    try {
      _cargando = true;
      notifyListeners();

      await _authService.resetPassword(email);

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Actualiza el nombre de visualización del usuario actual
  Future<void> actualizarNombre(String nuevoNombre) async {
    try {
      _cargando = true;
      notifyListeners();

      await _authService.updateDisplayName(nuevoNombre);

      if (_usuario != null) {
        await _firestore
            .collection(coleccionUsuarios)
            .doc(_usuario!.id)
            .update({'nombre': nuevoNombre});

        _usuario = _usuario!.copyWith(nombre: nuevoNombre);
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Actualiza el teléfono del usuario
  Future<void> actualizarTelefono(String nuevoTelefono) async {
    try {
      if (_usuario != null) {
        await _firestore
            .collection(coleccionUsuarios)
            .doc(_usuario!.id)
            .update({'telefono': nuevoTelefono});

        _usuario = _usuario!.copyWith(telefono: nuevoTelefono);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al actualizar el teléfono: $e');
    }
  }

  /// Obtiene todos los usuarios de una clínica
  Future<List<Usuario>> getUsuariosDeClinica(String clinicaId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(coleccionUsuarios)
          .where('clinicaId', isEqualTo: clinicaId)
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Usuario.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios de la clínica: $e');
    }
  }

  /// Obtiene un usuario por su ID
  Future<Usuario?> getUsuarioPorId(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(coleccionUsuarios).doc(userId).get();
      if (doc.exists) {
        return Usuario.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Actualiza la clínica asociada al usuario
  Future<void> actualizarClinicaId(String nuevaClinicaId) async {
    try {
      if (_usuario != null) {
        await _firestore
            .collection(coleccionUsuarios)
            .doc(_usuario!.id)
            .update({'clinicaId': nuevaClinicaId});

        _usuario = _usuario!.copyWith(clinicaId: nuevaClinicaId);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al actualizar la clínica del usuario: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
