import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Modelo que representa una cita veterinaria
class Cita {
  final String id;
  final String clinicaId;
  final String mascotaId;
  final String mascotaNombre;
  final String propietarioNombre;
  final String propietarioTelefono;
  final DateTime fechaHora;
  final String motivo;
  final String estado;
  final String? veterinarioId;
  final String? notas;
  final int duracionMinutos;
  final bool recordatorioEnviado;

  const Cita({
    required this.id,
    required this.clinicaId,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.propietarioNombre,
    required this.propietarioTelefono,
    required this.fechaHora,
    required this.motivo,
    this.estado = 'pendiente',
    this.veterinarioId,
    this.notas,
    this.duracionMinutos = 30,
    this.recordatorioEnviado = false,
  });

  /// Crea una instancia de Cita desde un DocumentSnapshot de Firestore
  factory Cita.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Cita(
      id: doc.id,
      clinicaId: data['clinicaId'] ?? '',
      mascotaId: data['mascotaId'] ?? '',
      mascotaNombre: data['mascotaNombre'] ?? '',
      propietarioNombre: data['propietarioNombre'] ?? '',
      propietarioTelefono: data['propietarioTelefono'] ?? '',
      fechaHora: data['fechaHora'] != null
          ? (data['fechaHora'] as Timestamp).toDate()
          : DateTime.now(),
      motivo: data['motivo'] ?? 'consultaGeneral',
      estado: data['estado'] ?? 'pendiente',
      veterinarioId: data['veterinarioId'] as String?,
      notas: data['notas'] as String?,
      duracionMinutos: data['duracionMinutos'] ?? 30,
      recordatorioEnviado: data['recordatorioEnviado'] ?? false,
    );
  }

  /// Convierte la cita a un Map<String, dynamic> para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'clinicaId': clinicaId,
      'mascotaId': mascotaId,
      'mascotaNombre': mascotaNombre,
      'propietarioNombre': propietarioNombre,
      'propietarioTelefono': propietarioTelefono,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'motivo': motivo,
      'estado': estado,
      'veterinarioId': veterinarioId,
      'notas': notas,
      'duracionMinutos': duracionMinutos,
      'recordatorioEnviado': recordatorioEnviado,
    };
  }

  /// Crea una copia de la cita con campos modificados
  Cita copyWith({
    String? id,
    String? clinicaId,
    String? mascotaId,
    String? mascotaNombre,
    String? propietarioNombre,
    String? propietarioTelefono,
    DateTime? fechaHora,
    String? motivo,
    String? estado,
    String? veterinarioId,
    String? notas,
    int? duracionMinutos,
    bool? recordatorioEnviado,
  }) {
    return Cita(
      id: id ?? this.id,
      clinicaId: clinicaId ?? this.clinicaId,
      mascotaId: mascotaId ?? this.mascotaId,
      mascotaNombre: mascotaNombre ?? this.mascotaNombre,
      propietarioNombre: propietarioNombre ?? this.propietarioNombre,
      propietarioTelefono: propietarioTelefono ?? this.propietarioTelefono,
      fechaHora: fechaHora ?? this.fechaHora,
      motivo: motivo ?? this.motivo,
      estado: estado ?? this.estado,
      veterinarioId: veterinarioId ?? this.veterinarioId,
      notas: notas ?? this.notas,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      recordatorioEnviado: recordatorioEnviado ?? this.recordatorioEnviado,
    );
  }

  /// Obtiene el color asociado al estado de la cita
  Color getColorPorEstado() {
    return coloresEstado[estado] ?? colorEstadoPendiente;
  }

  /// Obtiene el color de fondo asociado al estado de la cita
  Color getColorFondoPorEstado() {
    return coloresEstadoFondo[estado] ?? colorAdvertenciaClaro;
  }

  /// Obtiene el nombre legible del motivo de la cita
  String get motivoDisplay {
    final Map<String, String> motivos = {
      'consultaGeneral': 'Consulta General',
      'vacunacion': 'Vacunación',
      'desparasitacion': 'Desparasitación',
      'cirugia': 'Cirugía',
      'urgencia': 'Urgencia',
      'revision': 'Revisión',
      'peluqueria': 'Peluquería',
      'analisis': 'Análisis',
      'otros': 'Otros',
    };
    return motivos[motivo] ?? 'Otro';
  }

  /// Obtiene el nombre legible del estado de la cita
  String get estadoDisplay {
    final Map<String, String> estados = {
      'pendiente': 'Pendiente',
      'confirmada': 'Confirmada',
      'enProgreso': 'En Progreso',
      'completada': 'Completada',
      'cancelada': 'Cancelada',
      'noShow': 'No Asistió',
    };
    return estados[estado] ?? 'Pendiente';
  }

  /// Verifica si la cita está programada para hoy
  bool get esHoy {
    final DateTime ahora = DateTime.now();
    return fechaHora.year == ahora.year &&
        fechaHora.month == ahora.month &&
        fechaHora.day == ahora.day;
  }

  /// Verifica si la cita es futura
  bool get esFutura {
    return fechaHora.isAfter(DateTime.now());
  }

  /// Verifica si la cita está activa (pendiente o confirmada)
  bool get estaActiva {
    return estado == 'pendiente' || estado == 'confirmada';
  }

  /// Obtiene la hora de fin de la cita basada en la duración
  DateTime get horaFin {
    return fechaHora.add(Duration(minutes: duracionMinutos));
  }

  /// Obtiene el nombre del motivo capitalizado
  String get motivoCapitalizado {
    if (motivo.isEmpty) return 'Otro';
    return motivo[0].toUpperCase() + motivo.substring(1);
  }

  @override
  String toString() {
    return 'Cita(id: $id, mascota: $mascotaNombre, fecha: $fechaHora, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cita && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
