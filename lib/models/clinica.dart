import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una clínica veterinaria
class Clinica {
  final String id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String email;
  final Map<String, dynamic> horario;
  final String plan;
  final List<String> veterinarios;
  final Map<String, dynamic> configuracionWhatsApp;
  final bool activa;
  final DateTime creada;

  const Clinica({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.horario,
    required this.plan,
    required this.veterinarios,
    required this.configuracionWhatsApp,
    required this.activa,
    required this.creada,
  });

  /// Crea una instancia de Clinica desde un DocumentSnapshot de Firestore
  factory Clinica.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Clinica(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      email: data['email'] ?? '',
      horario: data['horario'] is Map
          ? Map<String, dynamic>.from(data['horario'] as Map)
          : {},
      plan: data['plan'] ?? 'basico',
      veterinarios: data['veterinarios'] != null
          ? List<String>.from(data['veterinarios'] as List)
          : [],
      configuracionWhatsApp: data['configuracionWhatsApp'] is Map
          ? Map<String, dynamic>.from(
              data['configuracionWhatsApp'] as Map)
          : {},
      activa: data['activa'] ?? true,
      creada: data['creada'] != null
          ? (data['creada'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convierte la clínica a un Map<String, dynamic> para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'horario': horario,
      'plan': plan,
      'veterinarios': veterinarios,
      'configuracionWhatsApp': configuracionWhatsApp,
      'activa': activa,
      'creada': Timestamp.fromDate(creada),
    };
  }

  /// Crea una copia de la clínica con campos modificados
  Clinica copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? telefono,
    String? email,
    Map<String, dynamic>? horario,
    String? plan,
    List<String>? veterinarios,
    Map<String, dynamic>? configuracionWhatsApp,
    bool? activa,
    DateTime? creada,
  }) {
    return Clinica(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      horario: horario ?? this.horario,
      plan: plan ?? this.plan,
      veterinarios: veterinarios ?? this.veterinarios,
      configuracionWhatsApp:
          configuracionWhatsApp ?? this.configuracionWhatsApp,
      activa: activa ?? this.activa,
      creada: creada ?? this.creada,
    );
  }

  @override
  String toString() {
    return 'Clinica(id: $id, nombre: $nombre, activa: $activa)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clinica && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
