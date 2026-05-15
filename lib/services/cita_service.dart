import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/models/cita.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Servicio que gestiona las operaciones CRUD de citas veterinarias
class CitaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene una referencia a la colección de citas
  CollectionReference get _citasCollection =>
      _firestore.collection(coleccionCitas);

  /// Obtiene un stream de citas de una clínica, opcionalmente filtradas por fecha
  Stream<List<Cita>> getCitasStream(
    String clinicaId, {
    DateTime? fecha,
  }) {
    Query query = _citasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .orderBy('fechaHora');

    if (fecha != null) {
      final DateTime inicioDia =
          DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0);
      final DateTime finDia =
          DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      query = query
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(finDia));
    }

    return query.snapshots().map((QuerySnapshot snapshot) {
      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    });
  }

  /// Obtiene una cita por su ID
  /// Retorna null si no existe
  Future<Cita?> getCita(String citaId) async {
    try {
      final DocumentSnapshot doc = await _citasCollection.doc(citaId).get();
      if (doc.exists) {
        return Cita.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la cita: $e');
    }
  }

  /// Crea una nueva cita y retorna su ID
  Future<String> crearCita(Cita cita) async {
    try {
      final DocumentReference docRef = await _citasCollection.add(
        cita.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear la cita: $e');
    }
  }

  /// Actualiza los datos de una cita existente
  Future<void> actualizarCita(Cita cita) async {
    try {
      await _citasCollection.doc(cita.id).update(cita.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar la cita: $e');
    }
  }

  /// Elimina una cita físicamente de Firestore
  Future<void> eliminarCita(String citaId) async {
    try {
      await _citasCollection.doc(citaId).delete();
    } catch (e) {
      throw Exception('Error al eliminar la cita: $e');
    }
  }

  /// Obtiene las citas del día actual para una clínica
  Future<List<Cita>> getCitasDelDia(String clinicaId) async {
    try {
      final DateTime ahora = DateTime.now();
      final DateTime inicioDia =
          DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
      final DateTime finDia =
          DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
          .orderBy('fechaHora')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las citas del día: $e');
    }
  }

  /// Obtiene las citas pendientes de confirmación
  Future<List<Cita>> getCitasPendientesConfirmacion(String clinicaId) async {
    try {
      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('estado', isEqualTo: 'pendiente')
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('fechaHora')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception(
          'Error al obtener citas pendientes de confirmación: $e');
    }
  }

  /// Cambia el estado de una cita
  Future<void> cambiarEstadoCita(
    String citaId,
    String nuevoEstado,
  ) async {
    try {
      final List<String> estadosValidos = [
        'pendiente',
        'confirmada',
        'enProgreso',
        'completada',
        'cancelada',
        'noShow',
      ];

      if (!estadosValidos.contains(nuevoEstado)) {
        throw Exception('Estado no válido: $nuevoEstado');
      }

      await _citasCollection.doc(citaId).update({
        'estado': nuevoEstado,
        'fechaActualizacion': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al cambiar el estado de la cita: $e');
    }
  }

  /// Obtiene las citas de una semana específica
  Future<List<Cita>> getCitasSemana(
    String clinicaId,
    DateTime fechaInicio,
  ) async {
    try {
      final DateTime inicioSemana = DateTime(
        fechaInicio.year,
        fechaInicio.month,
        fechaInicio.day,
        0,
        0,
        0,
      );
      final DateTime finSemana =
          inicioSemana.add(const Duration(days: 6, hours: 23, minutes: 59));

      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
          .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(finSemana))
          .orderBy('fechaHora')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las citas de la semana: $e');
    }
  }

  /// Obtiene las citas de un mes específico
  Future<List<Cita>> getCitasMes(
    String clinicaId,
    int year,
    int month,
  ) async {
    try {
      final DateTime inicioMes = DateTime(year, month, 1, 0, 0, 0);
      final DateTime finMes =
          DateTime(year, month + 1, 0, 23, 59, 59);

      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(finMes))
          .orderBy('fechaHora')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las citas del mes: $e');
    }
  }

  /// Marca el recordatorio de una cita como enviado
  Future<void> marcarRecordatorioEnviado(String citaId) async {
    try {
      await _citasCollection.doc(citaId).update({
        'recordatorioEnviado': true,
      });
    } catch (e) {
      throw Exception('Error al marcar recordatorio como enviado: $e');
    }
  }

  /// Obtiene las citas de una mascota específica
  Future<List<Cita>> getCitasPorMascota(String mascotaId) async {
    try {
      final QuerySnapshot snapshot = await _citasCollection
          .where('mascotaId', isEqualTo: mascotaId)
          .orderBy('fechaHora', descending: true)
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener citas de la mascota: $e');
    }
  }

  /// Obtiene las citas asignadas a un veterinario
  Future<List<Cita>> getCitasPorVeterinario(
    String clinicaId,
    String veterinarioId,
  ) async {
    try {
      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('veterinarioId', isEqualTo: veterinarioId)
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('fechaHora')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener citas del veterinario: $e');
    }
  }

  /// Verifica si hay conflicto de horario para una cita
  Future<bool> existeConflictoHorario(
    String clinicaId,
    DateTime fechaHora,
    int duracionMinutos, {
    String? excluirCitaId,
  }) async {
    try {
      final DateTime inicio = fechaHora;
      final DateTime fin = fechaHora.add(Duration(minutes: duracionMinutos));

      final DateTime inicioDia =
          DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0);
      final DateTime finDia =
          DateTime(inicio.year, inicio.month, inicio.day, 23, 59, 59);

      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('fechaHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
          .get();

      for (final DocumentSnapshot doc in snapshot.docs) {
        if (excluirCitaId != null && doc.id == excluirCitaId) continue;

        final Cita citaExistente = Cita.fromFirestore(doc);
        if (citaExistente.estado == 'cancelada' ||
            citaExistente.estado == 'noShow') {
          continue;
        }

        final DateTime inicioExistente = citaExistente.fechaHora;
        final DateTime finExistente = citaExistente.horaFin;

        if ((inicio.isBefore(finExistente) && fin.isAfter(inicioExistente))) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Error al verificar conflicto de horario: $e');
    }
  }

  /// Obtiene las citas filtradas por estado
  Future<List<Cita>> getCitasPorEstado(
    String clinicaId,
    String estado,
  ) async {
    try {
      final QuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('estado', isEqualTo: estado)
          .orderBy('fechaHora')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Cita.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener citas por estado: $e');
    }
  }

  /// Obtiene el total de citas de una clínica
  Future<int> getTotalCitas(String clinicaId) async {
    try {
      final AggregateQuerySnapshot snapshot = await _citasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ============ STREAMS PARA DASHBOARD ============

  /// Stream de citas de hoy para una clínica
  Stream<List<Cita>> getCitasHoyStream(String clinicaId) {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day, 0, 0, 0);
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    return _citasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Cita.fromFirestore(d)).toList());
  }

  /// Stream de citas pendientes de confirmación (próximas 7 días)
  Stream<List<Cita>> getCitasPendientesStream(String clinicaId) {
    final hoy = DateTime.now();
    final en7Dias = hoy.add(const Duration(days: 7));
    return _citasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .where('estado', isEqualTo: 'pendiente')
        .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(hoy))
        .where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(en7Dias))
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Cita.fromFirestore(d)).toList());
  }

  /// Stream de citas canceladas de esta semana
  Stream<List<Cita>> getCitasCanceladasSemanaStream(String clinicaId) {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    final inicioSemana = DateTime(lunes.year, lunes.month, lunes.day, 0, 0, 0);
    return _citasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .where('estado', isEqualTo: 'cancelada')
        .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Cita.fromFirestore(d)).toList());
  }

  /// Stream de citas por estado específico
  Stream<List<Cita>> getCitasPorEstadoStream(String clinicaId, String estado) {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day, 0, 0, 0);
    return _citasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .where('estado', isEqualTo: estado)
        .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Cita.fromFirestore(d)).toList());
  }

  /// Stream de citas del mes actual
  Stream<List<Cita>> getCitasMesStream(String clinicaId) {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1, 0, 0, 0);
    return _citasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
        .orderBy('fechaHora')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Cita.fromFirestore(d)).toList());
  }
}
