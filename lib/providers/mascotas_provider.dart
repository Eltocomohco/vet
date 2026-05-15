import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vetmanager/models/mascota.dart';
import 'package:vetmanager/services/mascota_service.dart';

/// Provider que gestiona el estado de la lista de mascotas
class MascotasProvider extends ChangeNotifier {
  final MascotaService _mascotaService = MascotaService();

  List<Mascota> _mascotas = [];
  List<Mascota> _mascotasFiltradas = [];
  bool _cargando = false;
  String? _error;
  String _queryBusqueda = '';

  StreamSubscription<List<Mascota>>? _mascotasSubscription;

  /// Lista completa de mascotas
  List<Mascota> get mascotas => _mascotas;

  /// Lista de mascotas filtradas por búsqueda
  List<Mascota> get mascotasFiltradas => _mascotasFiltradas;

  /// Indica si se está cargando información
  bool get cargando => _cargando;

  /// Mensaje de error si ocurrió alguno
  String? get error => _error;

  /// Query actual de búsqueda
  String get queryBusqueda => _queryBusqueda;

  /// Total de mascotas cargadas
  int get totalMascotas => _mascotas.length;

  /// Total de mascotas filtradas
  int get totalMascotasFiltradas => _mascotasFiltradas.length;

  /// Indica si hay mascotas cargadas
  bool get hayMascotas => _mascotas.isNotEmpty;

  /// Carga datos de demo para mascotas
  void cargarMascotasDemo() {
    _cancelarSuscripcion();
    _mascotas = [
      Mascota(
        id: 'demo-mascota-1',
        clinicaId: 'demo-clinica',
        nombre: 'Luna',
        especie: 'Perro',
        raza: 'Labrador',
        fechaNacimiento: DateTime(2019, 5, 12),
        peso: 28.5,
        alergias: const ['Polen'],
        chip: '123456789012345',
        color: 'Dorado',
        sexo: 'Hembra',
        propietario: const Propietario(
          nombre: 'María García',
          telefono: '611222333',
          email: 'maria@email.com',
        ),
        creada: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Mascota(
        id: 'demo-mascota-2',
        clinicaId: 'demo-clinica',
        nombre: 'Max',
        especie: 'Perro',
        raza: 'Bulldog Frances',
        fechaNacimiento: DateTime(2021, 3, 8),
        peso: 12.3,
        alergias: const [],
        chip: '987654321098765',
        color: 'Blanco y Negro',
        sexo: 'Macho',
        propietario: const Propietario(
          nombre: 'Carlos Ruiz',
          telefono: '622333444',
          email: 'carlos@email.com',
        ),
        creada: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Mascota(
        id: 'demo-mascota-3',
        clinicaId: 'demo-clinica',
        nombre: 'Mimi',
        especie: 'Gato',
        raza: 'Siames',
        fechaNacimiento: DateTime(2020, 8, 20),
        peso: 4.2,
        alergias: const ['Marisco'],
        chip: null,
        color: 'Cream',
        sexo: 'Hembra',
        propietario: const Propietario(
          nombre: 'Ana López',
          telefono: '633444555',
          email: 'ana@email.com',
        ),
        creada: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Mascota(
        id: 'demo-mascota-4',
        clinicaId: 'demo-clinica',
        nombre: 'Toby',
        especie: 'Perro',
        raza: 'Beagle',
        fechaNacimiento: DateTime(2018, 11, 3),
        peso: 18.0,
        alergias: const ['Penicilina'],
        chip: '555666777888999',
        color: 'Tricolor',
        sexo: 'Macho',
        propietario: const Propietario(
          nombre: 'Pedro Sánchez',
          telefono: '644555666',
          email: 'pedro@email.com',
        ),
        creada: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];
    _aplicarFiltro();
    _cargando = false;
    _error = null;
    notifyListeners();
  }

  /// Inicializa el stream de mascotas para una clínica
  void init(String clinicaId) {
    _cancelarSuscripcion();
    _cargando = true;
    _error = null;
    notifyListeners();

    _mascotasSubscription = _mascotaService
        .getMascotasStream(clinicaId)
        .listen(
      (List<Mascota> mascotas) {
        _mascotas = mascotas;
        _aplicarFiltro();
        _cargando = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _cargando = false;
        _error = 'Error al cargar mascotas: $error';
        notifyListeners();
        debugPrint('Error en stream de mascotas: $error');
      },
    );
  }

  /// Aplica el filtro de búsqueda actual a la lista de mascotas
  void _aplicarFiltro() {
    if (_queryBusqueda.trim().isEmpty) {
      _mascotasFiltradas = List<Mascota>.from(_mascotas);
    } else {
      final String queryLower = _queryBusqueda.toLowerCase().trim();
      _mascotasFiltradas = _mascotas.where((Mascota mascota) {
        return mascota.nombre.toLowerCase().contains(queryLower) ||
            mascota.raza.toLowerCase().contains(queryLower) ||
            mascota.especie.toLowerCase().contains(queryLower) ||
            mascota.propietario.nombre.toLowerCase().contains(queryLower) ||
            mascota.propietario.telefono.contains(queryLower) ||
            (mascota.chip != null &&
                mascota.chip!.toLowerCase().contains(queryLower)) ||
            (mascota.propietario.email != null &&
                mascota.propietario.email!
                    .toLowerCase()
                    .contains(queryLower));
      }).toList();
    }
  }

  /// Filtra las mascotas en memoria por nombre, raza, dueño, teléfono o chip
  void buscar(String query) {
    _queryBusqueda = query;
    _aplicarFiltro();
    notifyListeners();
  }

  /// Filtra mascotas por especie
  void filtrarPorEspecie(String especie) {
    if (especie.isEmpty) {
      _mascotasFiltradas = List<Mascota>.from(_mascotas);
    } else {
      _mascotasFiltradas = _mascotas
          .where((Mascota m) => m.especie == especie)
          .toList();
    }
    notifyListeners();
  }

  /// Filtra mascotas por sexo
  void filtrarPorSexo(String sexo) {
    if (sexo.isEmpty) {
      _mascotasFiltradas = List<Mascota>.from(_mascotas);
    } else {
      _mascotasFiltradas = _mascotas
          .where((Mascota m) => m.sexo == sexo)
          .toList();
    }
    notifyListeners();
  }

  /// Ordena las mascotas alfabéticamente por nombre
  void ordenarPorNombre({bool ascendente = true}) {
    _mascotasFiltradas.sort((Mascota a, Mascota b) {
      return ascendente
          ? a.nombre.compareTo(b.nombre)
          : b.nombre.compareTo(a.nombre);
    });
    notifyListeners();
  }

  /// Ordena las mascotas por nombre del propietario
  void ordenarPorPropietario({bool ascendente = true}) {
    _mascotasFiltradas.sort((Mascota a, Mascota b) {
      return ascendente
          ? a.propietario.nombre.compareTo(b.propietario.nombre)
          : b.propietario.nombre.compareTo(a.propietario.nombre);
    });
    notifyListeners();
  }

  /// Ordena las mascotas por fecha de creación
  void ordenarPorFecha({bool ascendente = true}) {
    _mascotasFiltradas.sort((Mascota a, Mascota b) {
      return ascendente
          ? a.creada.compareTo(b.creada)
          : b.creada.compareTo(a.creada);
    });
    notifyListeners();
  }

  /// Crea una nueva mascota
  Future<String> crearMascota(Mascota mascota) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      final String mascotaId =
          await _mascotaService.crearMascota(mascota);

      _cargando = false;
      notifyListeners();
      return mascotaId;
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al crear la mascota: $e');
    }
  }

  /// Actualiza una mascota existente
  Future<void> actualizarMascota(Mascota mascota) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      await _mascotaService.actualizarMascota(mascota);

      final int index = _mascotas.indexWhere((Mascota m) => m.id == mascota.id);
      if (index >= 0) {
        _mascotas[index] = mascota;
        _aplicarFiltro();
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al actualizar la mascota: $e');
    }
  }

  /// Elimina una mascota
  Future<void> eliminarMascota(String mascotaId) async {
    try {
      _cargando = true;
      _error = null;
      notifyListeners();

      await _mascotaService.eliminarMascota(mascotaId);

      _mascotas.removeWhere((Mascota m) => m.id == mascotaId);
      _aplicarFiltro();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Error al eliminar la mascota: $e');
    }
  }

  /// Actualiza la foto de una mascota
  Future<void> actualizarFotoMascota(
    String mascotaId,
    String? fotoUrl,
  ) async {
    try {
      await _mascotaService.actualizarFotoMascota(mascotaId, fotoUrl);

      final int index = _mascotas.indexWhere((Mascota m) => m.id == mascotaId);
      if (index >= 0) {
        _mascotas[index] = _mascotas[index].copyWith(fotoUrl: fotoUrl);
        _aplicarFiltro();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al actualizar la foto: $e');
    }
  }

  /// Agrega una alergia a una mascota
  Future<void> agregarAlergia(String mascotaId, String alergia) async {
    try {
      await _mascotaService.agregarAlergia(mascotaId, alergia);

      final int index = _mascotas.indexWhere((Mascota m) => m.id == mascotaId);
      if (index >= 0) {
        final List<String> nuevasAlergias =
            List<String>.from(_mascotas[index].alergias);
        if (!nuevasAlergias.contains(alergia)) {
          nuevasAlergias.add(alergia);
          _mascotas[index] =
              _mascotas[index].copyWith(alergias: nuevasAlergias);
          _aplicarFiltro();
          notifyListeners();
        }
      }
    } catch (e) {
      throw Exception('Error al agregar alergia: $e');
    }
  }

  /// Elimina una alergia de una mascota
  Future<void> eliminarAlergia(String mascotaId, String alergia) async {
    try {
      await _mascotaService.eliminarAlergia(mascotaId, alergia);

      final int index = _mascotas.indexWhere((Mascota m) => m.id == mascotaId);
      if (index >= 0) {
        final List<String> nuevasAlergias =
            List<String>.from(_mascotas[index].alergias);
        nuevasAlergias.remove(alergia);
        _mascotas[index] =
            _mascotas[index].copyWith(alergias: nuevasAlergias);
        _aplicarFiltro();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al eliminar alergia: $e');
    }
  }

  /// Obtiene una mascota por su ID de la lista cargada
  Mascota? getMascotaPorId(String mascotaId) {
    try {
      return _mascotas.firstWhere((Mascota m) => m.id == mascotaId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene una mascota por su token de carnet
  Future<Mascota?> getMascotaPorToken(String token) async {
    try {
      return await _mascotaService.getMascotaPorToken(token);
    } catch (e) {
      debugPrint('Error al buscar mascota por token: $e');
      return null;
    }
  }

  /// Limpia el filtro de búsqueda
  void limpiarBusqueda() {
    _queryBusqueda = '';
    _mascotasFiltradas = List<Mascota>.from(_mascotas);
    notifyListeners();
  }

  /// Limpia el estado del provider
  void clear() {
    _cancelarSuscripcion();
    _mascotas = [];
    _mascotasFiltradas = [];
    _cargando = false;
    _error = null;
    _queryBusqueda = '';
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cancela la suscripción al stream de mascotas
  void _cancelarSuscripcion() {
    if (_mascotasSubscription != null) {
      _mascotasSubscription!.cancel();
      _mascotasSubscription = null;
    }
  }

  @override
  void dispose() {
    _cancelarSuscripcion();
    super.dispose();
  }
}
