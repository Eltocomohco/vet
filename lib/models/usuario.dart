import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Modelo que representa un usuario de la aplicación
class Usuario {
  final String id;
  final String email;
  final String nombre;
  final String rol;
  final String clinicaId;
  final String? telefono;
  final bool activo;

  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.clinicaId,
    this.telefono,
    this.activo = true,
  });

  /// Crea una instancia de Usuario desde un DocumentSnapshot de Firestore
  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      rol: data['rol'] ?? rolRecepcionista,
      clinicaId: data['clinicaId'] ?? '',
      telefono: data['telefono'] as String?,
      activo: data['activo'] ?? true,
    );
  }

  /// Convierte el usuario a un Map<String, dynamic> para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nombre': nombre,
      'rol': rol,
      'clinicaId': clinicaId,
      'telefono': telefono,
      'activo': activo,
    };
  }

  /// Crea una copia del usuario con campos modificados
  Usuario copyWith({
    String? id,
    String? email,
    String? nombre,
    String? rol,
    String? clinicaId,
    String? telefono,
    bool? activo,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      clinicaId: clinicaId ?? this.clinicaId,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
    );
  }

  /// Verifica si el usuario tiene rol de administrador
  bool get esAdmin => rol == rolAdmin;

  /// Verifica si el usuario tiene rol de veterinario
  bool get esVeterinario => rol == rolVeterinario;

  /// Verifica si el usuario es recepcionista
  bool get esRecepcionista => rol == rolRecepcionista;

  /// Verifica si el usuario puede gestionar citas
  bool get puedeGestionarCitas => esAdmin || esRecepcionista;

  /// Verifica si el usuario puede gestionar mascotas
  bool get puedeGestionarMascotas => esAdmin || esVeterinario || esRecepcionista;

  /// Verifica si el usuario puede editar configuración
  bool get puedeEditarConfiguracion => esAdmin;

  /// Obtiene el nombre legible del rol
  String get rolDisplay {
    final Map<String, String> roles = {
      rolAdmin: 'Administrador',
      rolVeterinario: 'Veterinario',
      rolRecepcionista: 'Recepcionista',
    };
    return roles[rol] ?? rol;
  }

  /// Obtiene las iniciales del nombre del usuario
  String get iniciales {
    if (nombre.isEmpty) return '?';
    final List<String> partes = nombre.trim().split(' ');
    if (partes.length > 1) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, 1).toUpperCase();
  }

  @override
  String toString() {
    return 'Usuario(id: $id, nombre: $nombre, rol: $rol, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
