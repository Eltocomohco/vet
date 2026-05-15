import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vetmanager/models/cita.dart';
import 'package:vetmanager/services/cita_service.dart';

/// Provider que gestiona el calendario y las citas
class CalendarioProvider extends ChangeNotifier {
  final CitaService _citaService = CitaService();

  List<Cita> _citas = [];
  List<Cita> _citasDelDia = [];
  DateTime _fechaSeleccionada = DateTime.now();
  String _vista = 'month'; // 'month', 'week', 'day'

  bool _cargando = false;
  String? _error;

  StreamSubscription<List<Cita>>? _citasSubscription;

  /// Lista completa de citas de la clínica
  List<Cita> get citas => _citas;

  /// Citas del día seleccionado
  List<Cita> get citasDelDia => _citasDelDia;

  /// Fecha actualmente seleccionada en el calendario
  DateTime get fechaSeleccionada => _fechaSeleccionada;

  /// Vista actual del calendario
  String get vista => _vista;

  /// Indica si se está cargando información
  bool get cargando => _cargando;

  /// Mensaje de error si ocurrió alguno
  String? get error => _error;

  /// Total de citas del día seleccionado
  int get totalCitasHoy => _citasDelDia.length;

  /// Citas del día seleccionado que están pendientes
  int get citasPendientes => _citasDelDia
      .where((Cita c) => c.estado == 'pendiente')
      .length;

  /// Citas del día seleccionado que están confirmadas
  int get citasConfirmadas => _citasDelDia
      .where((Cita c) => c.estado == 'confirmada')
      .length;

  /// Citas del día seleccionado que están en progreso
  int get citasEnProgreso => _citasDelDia
      .where((Cita c) => c.estado == 'enProgreso')
      .length;

  /// Citas del día seleccionado completadas
  int get citasCompletadasHoy => _citasDelDia
      .where((Cita c) => c.estado == 'completada')
      .length;

  /// Citas del día seleccionado canceladas
  int get citasCanceladasHoy => _citasDelDia
      .where((Cita c) => c.estado == 'cancelada')
      .length;

  /// Total de citas de la clínica cargadas
  int get totalCitas => _citas.length;

  /// Carga datos de demo para citas
  void cargarCitasDemo() {
    _cancelarSuscripcion();
    final DateTime hoy = DateTime.now();
    final DateTime manana = hoy.add(const Duration(days: 1));
    _citas = [
      Cita(
        id: 'demo-cita-1',
        clinicaId: 'demo-clinica',
        mascotaId: 'demo-mascota-1',
        mascotaNombre: 'Luna',
        propietarioNombre: 'María García',
        propietarioTelefono: '611222333',
        fechaHora: DateTime(hoy.year, hoy.month, hoy.day, 10, 0),
        motivo: 'vacunacion',
        estado: 'confirmada',
        duracionMinutos: 30,
        notas: 'Vacuna trivalente anual',
      ),
      Cita(
        id: 'demo-cita-2',
        clinicaId: 'demo-clinica',
        mascotaId: 'demo-mascota-2',
        mascotaNombre: 'Max',
        propietarioNombre: 'Carlos Ruiz',
        propietarioTelefono: '622333444',
        fechaHora: DateTime(hoy.year, hoy.month, hoy.day, 11, 30),
        motivo: 'consultaGeneral',
        estado: 'pendiente',
        duracionMinutos: 30,
        notas: 'Revisión de piel',
      ),
      Cita(
        id: 'demo-cita-3',
        clinicaId: 'demo-clinica',
        mascotaId: 'demo-mascota-3',
        mascotaNombre: 'Mimi',
        propietarioNombre: 'Ana López',
        propietarioTelefono: '633444555',
        fechaHora: DateTime(hoy.year, hoy.month, hoy.day, 17, 0),
        motivo: 'revision',
        estado: 'confirmada',
        duracionMinutos: 20,
        notas: 'Control post-cirugía',
      ),
      Cita(
        id: 'demo-cita-4',
        clinicaId: 'demo-clinica',
        mascotaId: 'demo-mascota-4',
        mascotaNombre: 'Toby',
        propietarioNombre: 'Pedro Sánchez',
        propietarioTelefono: '644555666',
        fechaHora: DateTime(manana.year, manana.month, manana.day, 9, 0),
        motivo: 'desparasitacion',
        estado: 'pendiente',
        duracionMinutos: 15,
        notas: 'Desparasitación interna',
      ),
    ];
    _actualizarCitasDelDia();
    _cargando = false;
    _error = null;
    notifyListeners();
  }

  /// Inicializa el stream de citas para una clínica
  void init(String clinicaId) {
    _cancelarSuscripcion();
    _cargando = true;
    _error = null;
    notifyListeners();

    _citasSubscription = _citaService
        .getCitasStream(clinicaId)
        .listen(
      (List<Cita> citas) {
        _citas = citas;
        _actualizarCitasDelDia();
        _cargando = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _cargando = false;
        _error = 'Error al cargar citas: $error';
        notifyListeners();
        debugPrint('Error en stream de citas: $error');
      },
    );
  }

  /// Actualiza la lista de citas del día según la fecha seleccionada
  void _actualizarCitasDelDia() {
    _citasDelDia = _citas.where((Cita cita) {
      return cita.fechaHora.year == _fechaSeleccionada.year &&
          cita.fechaHora.month == _fechaSeleccionada.month &&
          cita.fechaHora.day == _fechaSeleccionada.day;
    }).toList();

    // Ordenar por hora
    _citasDelDia.sort(
      (Cita a, Cita b) => a.fechaHora.compareTo(b.fechaHora),
    );
  }

  /// Cambia la fecha seleccionada
  void cambiarFecha(DateTime nuevaFecha) {
    _fechaSeleccionada = nuevaFecha;
    _actualizarCitasDelDia();
    notifyListeners();
  }

  /// Cambia al día siguiente
  void diaSiguiente() {
    _fechaSeleccionada = _fechaSeleccionada.add(const Duration(days: 1));
    _actualizarCitasDelDia();
    notifyListeners();
  }

  /// Cambia al día anterior
  void diaAnterior() {
    _fechaSeleccionada = _fechaSeleccionada.subtract(const Duration(days: 1));
    _actualizarCitasDelDia();
    notifyListeners();
  }

  /// Va a la fecha de hoy
  void irAHoy() {
    _fechaSeleccionada = DateTime.now();
    _actualizarCitasDelDia();
    notifyListeners();
  }

  /// Cambia el tipo de vista del calendario
  void cambiarVista(String nuevaVista) {
    const List<String> vistasValidas = ['month', 'week', 'day'];
    if (vistasValidas.contains(nuevaVista)) {
      _vista = nuevaVista;
      notifyListeners();
    }
  }

  /// Crea una nueva cita
  Future<String> crearCita(Cita cita) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final String citaId = await _citaService.crearCita(cita);

      _cargando = false;
      notifyListeners();
      return citaId;
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al crear la cita: $e');
    }
  }

  /// Actualiza una cita existente
  Future<void> actualizarCita(Cita cita) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      await _citaService.actualizarCita(cita);

      final int index = _citas.indexWhere((Cita c) => c.id == cita.id);
      if (index >= 0) {
        _citas[index] = cita;
        _actualizarCitasDelDia();
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al actualizar la cita: $e');
    }
  }

  /// Elimina una cita
  Future<void> eliminarCita(String citaId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      await _citaService.eliminarCita(citaId);

      _citas.removeWhere((Cita c) => c.id == citaId);
      _actualizarCitasDelDia();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al eliminar la cita: $e');
    }
  }

  /// Cambia el estado de una cita
  Future<void> cambiarEstadoCita(String citaId, String nuevoEstado) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      await _citaService.cambiarEstadoCita(citaId, nuevoEstado);

      final int index = _citas.indexWhere((Cita c) => c.id == citaId);
      if (index >= 0) {
        _citas[index] = _citas[index].copyWith(estado: nuevoEstado);
        _actualizarCitasDelDia();
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al cambiar el estado de la cita: $e');
    }
  }

  /// Obtiene las citas de un día específico
  List<Cita> getCitasPorDia(DateTime fecha) {
    return _citas
        .where((Cita cita) {
          return cita.fechaHora.year == fecha.year &&
              cita.fechaHora.month == fecha.month &&
              cita.fechaHora.day == fecha.day;
        })
        .toList()
      ..sort((Cita a, Cita b) => a.fechaHora.compareTo(b.fechaHora));
  }

  /// Verifica si un día tiene citas
  bool diaTieneCitas(DateTime fecha) {
    return _citas.any((Cita cita) {
      return cita.fechaHora.year == fecha.year &&
          cita.fechaHora.month == fecha.month &&
          cita.fechaHora.day == fecha.day;
    });
  }

  /// Obtiene el número de citas de un día
  int getCantidadCitasPorDia(DateTime fecha) {
    return _citas.where((Cita cita) {
      return cita.fechaHora.year == fecha.year &&
          cita.fechaHora.month == fecha.month &&
          cita.fechaHora.day == fecha.day;
    }).length;
  }

  /// Obtiene las citas en un rango de fechas
  List<Cita> getCitasEnRango(DateTime inicio, DateTime fin) {
    return _citas
        .where((Cita cita) {
          return cita.fechaHora.isAfter(inicio) &&
              cita.fechaHora.isBefore(fin.add(const Duration(days: 1)));
        })
        .toList()
      ..sort((Cita a, Cita b) => a.fechaHora.compareTo(b.fechaHora));
  }

  /// Marca el recordatorio de una cita como enviado
  Future<void> marcarRecordatorioEnviado(String citaId) async {
    try {
      await _citaService.marcarRecordatorioEnviado(citaId);

      final int index = _citas.indexWhere((Cita c) => c.id == citaId);
      if (index >= 0) {
        _citas[index] = _citas[index].copyWith(recordatorioEnviado: true);
        _actualizarCitasDelDia();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al marcar recordatorio: $e');
    }
  }

  /// Obtiene una cita por su ID de la lista cargada
  Cita? getCitaPorId(String citaId) {
    try {
      return _citas.firstWhere((Cita c) => c.id == citaId);
    } catch (e) {
      return null;
    }
  }

  /// Limpia el estado del provider
  void clear() {
    _cancelarSuscripcion();
    _citas = [];
    _citasDelDia = [];
    _fechaSeleccionada = DateTime.now();
    _vista = 'month';
    _cargando = false;
    _error = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cancela la suscripción al stream de citas
  void _cancelarSuscripcion() {
    if (_citasSubscription != null) {
      _citasSubscription!.cancel();
      _citasSubscription = null;
    }
  }

  @override
  void dispose() {
    _cancelarSuscripcion();
    super.dispose();
  }
}
