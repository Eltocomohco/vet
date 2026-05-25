import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/utils/formatters.dart';

/// Modelo que representa al propietario de una mascota
class Propietario {
  final String nombre;
  final String telefono;
  final String? email;
  final String? dni;

  const Propietario({
    required this.nombre,
    required this.telefono,
    this.email,
    this.dni,
  });

  /// Crea un Propietario desde un Map
  factory Propietario.fromMap(Map<String, dynamic> map) {
    return Propietario(
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] as String?,
      dni: map['dni'] as String?,
    );
  }

  /// Convierte el propietario a un Map
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'dni': dni,
    };
  }

  /// Crea una copia con campos modificados
  Propietario copyWith({
    String? nombre,
    String? telefono,
    String? email,
    String? dni,
  }) {
    return Propietario(
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      dni: dni ?? this.dni,
    );
  }
}

/// Modelo que representa una mascota
class Mascota {
  final String id;
  final String clinicaId;
  final String nombre;
  final String especie;
  final String raza;
  final DateTime? fechaNacimiento;
  final double peso;
  final List<String> alergias;
  final String? chip;
  final String? color;
  final String sexo;
  final Propietario propietario;
  final String? fotoUrl;
  final String tokenCarnet;
  final DateTime creada;

  Mascota({
    required this.id,
    required this.clinicaId,
    required this.nombre,
    required this.especie,
    required this.raza,
    this.fechaNacimiento,
    this.peso = 0.0,
    this.alergias = const [],
    this.chip,
    this.color,
    this.sexo = 'Desconocido',
    required this.propietario,
    this.fotoUrl,
    this.tokenCarnet = '',
    required this.creada,
  });

  /// Genera un token único para el carnet de vacunación
  static String generarTokenCarnet() {
    const String caracteres =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random.secure();
    final StringBuffer token = StringBuffer();
    for (int i = 0; i < 12; i++) {
      token.write(caracteres[random.nextInt(caracteres.length)]);
    }
    return token.toString();
  }

  /// Crea una instancia de Mascota desde un DocumentSnapshot de Firestore
  factory Mascota.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final String rawToken = data['tokenCarnet'] ?? '';
    final String finalToken = rawToken.isEmpty ? generarTokenCarnet() : rawToken;

    return Mascota(
      id: doc.id,
      clinicaId: data['clinicaId'] ?? '',
      nombre: data['nombre'] ?? '',
      especie: data['especie'] ?? 'Otro',
      raza: data['raza'] ?? 'Otro',
      fechaNacimiento: data['fechaNacimiento'] != null
          ? (data['fechaNacimiento'] as Timestamp).toDate()
          : null,
      peso: (data['peso'] as num?)?.toDouble() ?? 0.0,
      alergias: data['alergias'] != null
          ? List<String>.from(data['alergias'] as List)
          : [],
      chip: data['chip'] as String?,
      color: data['color'] as String?,
      sexo: data['sexo'] ?? 'Desconocido',
      propietario: data['propietario'] is Map
          ? Propietario.fromMap(
              Map<String, dynamic>.from(data['propietario'] as Map))
          : const Propietario(nombre: '', telefono: ''),
      fotoUrl: data['fotoUrl'] as String?,
      tokenCarnet: finalToken,
      creada: data['creada'] != null
          ? (data['creada'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convierte la mascota a un Map<String, dynamic> para Firestore
  Map<String, dynamic> toFirestore() {
    final String tokenToSave = tokenCarnet.isEmpty ? generarTokenCarnet() : tokenCarnet;
    return {
      'clinicaId': clinicaId,
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'fechaNacimiento':
          fechaNacimiento != null ? Timestamp.fromDate(fechaNacimiento!) : null,
      'peso': peso,
      'alergias': alergias,
      'chip': chip,
      'color': color,
      'sexo': sexo,
      'propietario': propietario.toMap(),
      'fotoUrl': fotoUrl,
      'tokenCarnet': tokenToSave,
      'creada': Timestamp.fromDate(creada),
    };
  }

  /// Crea una copia de la mascota con campos modificados
  Mascota copyWith({
    String? id,
    String? clinicaId,
    String? nombre,
    String? especie,
    String? raza,
    DateTime? fechaNacimiento,
    double? peso,
    List<String>? alergias,
    String? chip,
    String? color,
    String? sexo,
    Propietario? propietario,
    String? fotoUrl,
    String? tokenCarnet,
    DateTime? creada,
  }) {
    return Mascota(
      id: id ?? this.id,
      clinicaId: clinicaId ?? this.clinicaId,
      nombre: nombre ?? this.nombre,
      especie: especie ?? this.especie,
      raza: raza ?? this.raza,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      peso: peso ?? this.peso,
      alergias: alergias ?? this.alergias,
      chip: chip ?? this.chip,
      color: color ?? this.color,
      sexo: sexo ?? this.sexo,
      propietario: propietario ?? this.propietario,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      tokenCarnet: tokenCarnet ?? this.tokenCarnet,
      creada: creada ?? this.creada,
    );
  }

  /// Obtiene la edad formateada de la mascota
  String get edad => calcularEdad(fechaNacimiento);

  /// Obtiene la edad en meses
  int get edadEnMeses => calcularEdadEnMeses(fechaNacimiento);

  /// Obtiene el nombre del propietario
  String get nombrePropietario => propietario.nombre;

  /// Obtiene el teléfono del propietario
  String get telefonoPropietario => propietario.telefono;

  /// Obtiene el email del propietario
  String? get emailPropietario => propietario.email;

  @override
  String toString() {
    return 'Mascota(id: $id, nombre: $nombre, especie: $especie, propietario: ${propietario.nombre})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mascota && other.id == id;
  }

  /// Alias para compatibilidad con UI generada
  String? get numeroChip => chip;

  /// Historial de vacunas (placeholder para compatibilidad)
  List<dynamic>? get historialVacunas => null;

  @override
  int get hashCode => id.hashCode;
}
