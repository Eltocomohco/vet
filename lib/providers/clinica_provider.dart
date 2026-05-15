import 'package:flutter/material.dart';
import 'package:vetmanager/models/clinica.dart';
import 'package:vetmanager/services/clinica_service.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Provider que gestiona el estado de la clínica actual
class ClinicaProvider extends ChangeNotifier {
  final ClinicaService _clinicaService = ClinicaService();

  Clinica? _clinica;
  bool _cargando = false;
  String? _error;

  /// Clínica actualmente seleccionada/cargada
  Clinica? get clinica => _clinica;

  /// Indica si se está cargando información
  bool get cargando => _cargando;

  /// Mensaje de error si ocurrió alguno
  String? get error => _error;

  /// ID de la clínica
  String? get clinicaId => _clinica?.id;

  /// Nombre de la clínica
  String? get nombreClinica => _clinica?.nombre;

  /// Dirección de la clínica
  String? get direccion => _clinica?.direccion;

  /// Teléfono de la clínica
  String? get telefono => _clinica?.telefono;

  /// Email de la clínica
  String? get email => _clinica?.email;

  /// Plan de suscripción de la clínica
  String? get plan => _clinica?.plan;

  /// Horario de atención de la clínica
  Map<String, dynamic> get horario => _clinica?.horario ?? {};

  /// Lista de IDs de veterinarios de la clínica
  List<String> get veterinarios => _clinica?.veterinarios ?? [];

  /// Configuración de WhatsApp de la clínica
  Map<String, dynamic> get configuracionWhatsApp =>
      _clinica?.configuracionWhatsApp ?? {};

  /// Indica si la clínica está activa
  bool get activa => _clinica?.activa ?? false;

  /// Carga datos de demo para la clínica
  void cargarClinicaDemo() {
    _clinica = Clinica(
      id: 'demo-clinica',
      nombre: 'Clínica Demo VetClick',
      direccion: 'Calle Prueba 123',
      telefono: '600123456',
      email: 'demo@vetclick.app',
      horario: const {
        'lunes': '09:00 - 18:00',
        'martes': '09:00 - 18:00',
        'miercoles': '09:00 - 18:00',
        'jueves': '09:00 - 18:00',
        'viernes': '09:00 - 14:00',
        'sabado': 'Cerrado',
        'domingo': 'Cerrado',
      },
      plan: planBasico,
      veterinarios: const ['demo'],
      configuracionWhatsApp: const {},
      activa: true,
      creada: DateTime.now(),
    );
    _error = null;
    notifyListeners();
  }

  /// Carga la información de una clínica por su ID
  Future<void> cargarClinica(String clinicaId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final Clinica? clinicaObtenida =
          await _clinicaService.getClinica(clinicaId);

      if (clinicaObtenida != null) {
        _clinica = clinicaObtenida;
        _error = null;
      } else {
        _error = 'No se encontró la clínica';
        _clinica = null;
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      _clinica = null;
      notifyListeners();
    }
  }

  /// Crea una nueva clínica y la establece como clínica actual
  Future<String> crearClinica(Clinica clinica) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final String clinicaId =
          await _clinicaService.crearClinica(clinica);

      await cargarClinica(clinicaId);

      _cargando = false;
      notifyListeners();
      return clinicaId;
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al crear la clínica: $e');
    }
  }

  /// Actualiza los datos de la clínica actual
  Future<void> actualizarClinica(Clinica clinica) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      await _clinicaService.actualizarClinica(clinica);
      _clinica = clinica;

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al actualizar la clínica: $e');
    }
  }

  /// Actualiza la configuración de WhatsApp de la clínica
  Future<void> actualizarConfiguracion(
    Map<String, dynamic> configuracion,
  ) async {
    try {
      if (_clinica == null) {
        throw Exception('No hay clínica cargada');
      }

      _cargando = true;
      _error = null;
      notifyListeners();

      await _clinicaService.actualizarConfiguracionWhatsApp(
        _clinica!.id,
        configuracion,
      );

      final Map<String, dynamic> nuevaConfig = Map<String, dynamic>.from(
        _clinica!.configuracionWhatsApp,
      );
      nuevaConfig.addAll(configuracion);

      _clinica = _clinica!.copyWith(configuracionWhatsApp: nuevaConfig);

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al actualizar la configuración: $e');
    }
  }

  /// Actualiza el horario de atención de la clínica
  Future<void> actualizarHorario(Map<String, dynamic> horario) async {
    try {
      if (_clinica == null) {
        throw Exception('No hay clínica cargada');
      }

      _cargando = true;
      notifyListeners();

      await _clinicaService.actualizarClinica(
        _clinica!.copyWith(horario: horario),
      );

      _clinica = _clinica!.copyWith(horario: horario);

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      notifyListeners();
      throw Exception('Error al actualizar el horario: $e');
    }
  }

  /// Agrega un veterinario a la clínica
  Future<void> agregarVeterinario(String veterinarioId) async {
    try {
      if (_clinica == null) {
        throw Exception('No hay clínica cargada');
      }

      await _clinicaService.agregarVeterinario(
        _clinica!.id,
        veterinarioId,
      );

      final List<String> nuevaLista =
          List<String>.from(_clinica!.veterinarios);
      if (!nuevaLista.contains(veterinarioId)) {
        nuevaLista.add(veterinarioId);
        _clinica = _clinica!.copyWith(veterinarios: nuevaLista);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al agregar veterinario: $e');
    }
  }

  /// Elimina un veterinario de la clínica
  Future<void> removerVeterinario(String veterinarioId) async {
    try {
      if (_clinica == null) {
        throw Exception('No hay clínica cargada');
      }

      await _clinicaService.removerVeterinario(
        _clinica!.id,
        veterinarioId,
      );

      final List<String> nuevaLista =
          List<String>.from(_clinica!.veterinarios);
      nuevaLista.remove(veterinarioId);
      _clinica = _clinica!.copyWith(veterinarios: nuevaLista);
      notifyListeners();
    } catch (e) {
      throw Exception('Error al remover veterinario: $e');
    }
  }

  /// Cambia el plan de suscripción de la clínica
  Future<void> cambiarPlan(String nuevoPlan) async {
    try {
      if (_clinica == null) {
        throw Exception('No hay clínica cargada');
      }

      _cargando = true;
      notifyListeners();

      await _clinicaService.actualizarPlan(_clinica!.id, nuevoPlan);
      _clinica = _clinica!.copyWith(plan: nuevoPlan);

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      notifyListeners();
      throw Exception('Error al cambiar el plan: $e');
    }
  }

  /// Establece la clínica directamente (útil cuando ya se tiene la instancia)
  void setClinica(Clinica clinica) {
    _clinica = clinica;
    _error = null;
    notifyListeners();
  }

  /// Limpia el estado del provider
  void clear() {
    _clinica = null;
    _cargando = false;
    _error = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
