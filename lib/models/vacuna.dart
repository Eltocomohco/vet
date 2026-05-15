import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una vacuna aplicada a una mascota
class Vacuna {
  final String id;
  final String mascotaId;
  final String tipo;
  final String nombre;
  final DateTime fecha;
  final DateTime? proximaFecha;
  final String? veterinario;
  final String? producto;
  final String? notas;
  final bool recordatorioEnviado;

  const Vacuna({
    required this.id,
    required this.mascotaId,
    required this.tipo,
    required this.nombre,
    required this.fecha,
    this.proximaFecha,
    this.veterinario,
    this.producto,
    this.notas,
    this.recordatorioEnviado = false,
  });

  /// Crea una instancia de Vacuna desde un DocumentSnapshot de Firestore
  factory Vacuna.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Vacuna(
      id: doc.id,
      mascotaId: data['mascotaId'] ?? '',
      tipo: data['tipo'] ?? 'Otra',
      nombre: data['nombre'] ?? '',
      fecha: data['fecha'] != null
          ? (data['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      proximaFecha: data['proximaFecha'] != null
          ? (data['proximaFecha'] as Timestamp).toDate()
          : null,
      veterinario: data['veterinario'] as String?,
      producto: data['producto'] as String?,
      notas: data['notas'] as String?,
      recordatorioEnviado: data['recordatorioEnviado'] ?? false,
    );
  }

  /// Convierte la vacuna a un Map<String, dynamic> para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'mascotaId': mascotaId,
      'tipo': tipo,
      'nombre': nombre,
      'fecha': Timestamp.fromDate(fecha),
      'proximaFecha':
          proximaFecha != null ? Timestamp.fromDate(proximaFecha!) : null,
      'veterinario': veterinario,
      'producto': producto,
      'notas': notas,
      'recordatorioEnviado': recordatorioEnviado,
    };
  }

  /// Crea una copia de la vacuna con campos modificados
  Vacuna copyWith({
    String? id,
    String? mascotaId,
    String? tipo,
    String? nombre,
    DateTime? fecha,
    DateTime? proximaFecha,
    String? veterinario,
    String? producto,
    String? notas,
    bool? recordatorioEnviado,
  }) {
    return Vacuna(
      id: id ?? this.id,
      mascotaId: mascotaId ?? this.mascotaId,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      proximaFecha: proximaFecha ?? this.proximaFecha,
      veterinario: veterinario ?? this.veterinario,
      producto: producto ?? this.producto,
      notas: notas ?? this.notas,
      recordatorioEnviado: recordatorioEnviado ?? this.recordatorioEnviado,
    );
  }

  /// Verifica si la vacuna está vencida (la próxima fecha ya pasó)
  bool get estaVencida {
    if (proximaFecha == null) return false;
    final DateTime ahora = DateTime.now();
    return proximaFecha!.isBefore(ahora);
  }

  /// Verifica si la vacuna vence pronto (en los próximos 30 días)
  bool get vencePronto {
    if (proximaFecha == null) return false;
    if (estaVencida) return false;
    final DateTime ahora = DateTime.now();
    final DateTime limite = ahora.add(const Duration(days: 30));
    return proximaFecha!.isBefore(limite);
  }

  /// Obtiene los días restantes hasta la próxima vacuna
  int? get diasRestantes {
    if (proximaFecha == null) return null;
    final DateTime ahora = DateTime.now();
    return proximaFecha!.difference(ahora).inDays;
  }

  @override
  String toString() {
    return 'Vacuna(id: $id, tipo: $tipo, nombre: $nombre, mascotaId: $mascotaId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vacuna && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
