import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cita.dart';
import '../models/mascota.dart';
import '../models/vacuna.dart';

/// Servicio para poblar Firestore con datos de prueba.
/// Útil para demos y testing.
class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  /// Crea datos de prueba completos para una clínica.
  /// Retorna un resumen de lo creado.
  Future<Map<String, dynamic>> seedClinicaDemoData(String clinicaId) async {
    final batch = _firestore.batch();
    final resumen = <String, dynamic>{
      'mascotas': 0,
      'citas': 0,
      'vacunas': 0,
    };

    // --- Mascotas ---
    final mascotasData = _generarMascotas(clinicaId);
    final Map<String, String> mascotaIds = {};

    for (final entry in mascotasData.entries) {
      final ref = _firestore.collection('mascotas').doc();
      batch.set(ref, entry.value.toFirestore()..['clinicaId'] = clinicaId);
      mascotaIds[entry.key] = ref.id;
      resumen['mascotas'] = (resumen['mascotas'] as int) + 1;
    }

    // --- Citas ---
    final hoy = DateTime.now();
    final citas = _generarCitas(clinicaId, mascotaIds, hoy);

    for (final cita in citas) {
      final ref = _firestore.collection('citas').doc();
      batch.set(ref, cita.toFirestore()..['clinicaId'] = clinicaId);
      resumen['citas'] = (resumen['citas'] as int) + 1;
    }

    // --- Vacunas (subcolección de mascotas) ---
    for (final entry in mascotasData.entries) {
      final mascotaId = mascotaIds[entry.key]!;
      final vacunas = _generarVacunas(mascotaId, hoy);
      for (final vacuna in vacunas) {
        final ref = _firestore
            .collection('mascotas')
            .doc(mascotaId)
            .collection('vacunas')
            .doc();
        batch.set(ref, vacuna.toFirestore()..['mascotaId'] = mascotaId);
        resumen['vacunas'] = (resumen['vacunas'] as int) + 1;
      }
    }

    await batch.commit();
    return resumen;
  }

  Map<String, Mascota> _generarMascotas(String clinicaId) {
    return {
      'luna': Mascota(
        id: '',
        clinicaId: clinicaId,
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
      'max': Mascota(
        id: '',
        clinicaId: clinicaId,
        nombre: 'Max',
        especie: 'Perro',
        raza: 'Bulldog Francés',
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
      'mimi': Mascota(
        id: '',
        clinicaId: clinicaId,
        nombre: 'Mimi',
        especie: 'Gato',
        raza: 'Siamés',
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
      'toby': Mascota(
        id: '',
        clinicaId: clinicaId,
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
      'nala': Mascota(
        id: '',
        clinicaId: clinicaId,
        nombre: 'Nala',
        especie: 'Gato',
        raza: 'Maine Coon',
        fechaNacimiento: DateTime(2022, 1, 15),
        peso: 6.8,
        alergias: const [],
        chip: '111222333444555',
        color: 'Gris',
        sexo: 'Hembra',
        propietario: const Propietario(
          nombre: 'Laura Martínez',
          telefono: '655666777',
          email: 'laura@email.com',
        ),
        creada: DateTime.now().subtract(const Duration(days: 5)),
      ),
      'rocky': Mascota(
        id: '',
        clinicaId: clinicaId,
        nombre: 'Rocky',
        especie: 'Perro',
        raza: 'Pastor Alemán',
        fechaNacimiento: DateTime(2017, 7, 22),
        peso: 35.0,
        alergias: const ['Polvo'],
        chip: '999888777666555',
        color: 'Negro y Fuego',
        sexo: 'Macho',
        propietario: const Propietario(
          nombre: 'Juan Torres',
          telefono: '666777888',
          email: 'juan@email.com',
        ),
        creada: DateTime.now().subtract(const Duration(days: 90)),
      ),
    };
  }

  List<Cita> _generarCitas(String clinicaId, Map<String, String> mascotaIds, DateTime hoy) {
    final manana = hoy.add(const Duration(days: 1));
    final pasado = hoy.add(const Duration(days: 2));
    final ayer = hoy.subtract(const Duration(days: 1));
    final semanaPasada = hoy.subtract(const Duration(days: 5));

    return [
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['luna']!,
        mascotaNombre: 'Luna', propietarioNombre: 'María García', propietarioTelefono: '611222333',
        fechaHora: DateTime(hoy.year, hoy.month, hoy.day, 10, 0),
        motivo: 'vacunacion', estado: 'confirmada', duracionMinutos: 30, notas: 'Vacuna trivalente anual',
      ),
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['max']!,
        mascotaNombre: 'Max', propietarioNombre: 'Carlos Ruiz', propietarioTelefono: '622333444',
        fechaHora: DateTime(hoy.year, hoy.month, hoy.day, 11, 30),
        motivo: 'consultaGeneral', estado: 'pendiente', duracionMinutos: 30, notas: 'Revisión de piel',
      ),
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['mimi']!,
        mascotaNombre: 'Mimi', propietarioNombre: 'Ana López', propietarioTelefono: '633444555',
        fechaHora: DateTime(hoy.year, hoy.month, hoy.day, 17, 0),
        motivo: 'revision', estado: 'confirmada', duracionMinutos: 20, notas: 'Control post-cirugía',
      ),
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['toby']!,
        mascotaNombre: 'Toby', propietarioNombre: 'Pedro Sánchez', propietarioTelefono: '644555666',
        fechaHora: DateTime(manana.year, manana.month, manana.day, 9, 0),
        motivo: 'desparasitacion', estado: 'pendiente', duracionMinutos: 15, notas: 'Desparasitación interna',
      ),
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['nala']!,
        mascotaNombre: 'Nala', propietarioNombre: 'Laura Martínez', propietarioTelefono: '655666777',
        fechaHora: DateTime(manana.year, manana.month, manana.day, 12, 0),
        motivo: 'peluqueria', estado: 'confirmada', duracionMinutos: 60, notas: 'Baño y corte',
      ),
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['rocky']!,
        mascotaNombre: 'Rocky', propietarioNombre: 'Juan Torres', propietarioTelefono: '666777888',
        fechaHora: DateTime(pasado.year, pasado.month, pasado.day, 16, 30),
        motivo: 'analisis', estado: 'pendiente', duracionMinutos: 30, notas: 'Análisis de sangre pre-operatorio',
      ),
      // Citas pasadas (para historial)
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['luna']!,
        mascotaNombre: 'Luna', propietarioNombre: 'María García', propietarioTelefono: '611222333',
        fechaHora: DateTime(ayer.year, ayer.month, ayer.day, 10, 0),
        motivo: 'consultaGeneral', estado: 'completada', duracionMinutos: 30, notas: 'Revisión general OK',
      ),
      Cita(
        id: '', clinicaId: clinicaId, mascotaId: mascotaIds['max']!,
        mascotaNombre: 'Max', propietarioNombre: 'Carlos Ruiz', propietarioTelefono: '622333444',
        fechaHora: DateTime(semanaPasada.year, semanaPasada.month, semanaPasada.day, 11, 0),
        motivo: 'vacunacion', estado: 'cancelada', duracionMinutos: 30, notas: 'Canceló el dueño',
      ),
    ];
  }

  List<Vacuna> _generarVacunas(String mascotaId, DateTime hoy) {
    final vacunas = <Vacuna>[];

    // Generar algunas vacunas según la mascota
    if (mascotaId.isNotEmpty) {
      vacunas.add(Vacuna(
        id: '', mascotaId: mascotaId, tipo: 'Obligatoria', nombre: 'Rabia',
        fecha: hoy.subtract(const Duration(days: 365)),
        proximaFecha: hoy.add(const Duration(days: 30)),
        veterinario: 'Dr. García', producto: 'Rabix', notas: 'Primera dosis',
      ));
      vacunas.add(Vacuna(
        id: '', mascotaId: mascotaId, tipo: 'Obligatoria', nombre: 'Trivalente',
        fecha: hoy.subtract(const Duration(days: 400)),
        proximaFecha: hoy.subtract(const Duration(days: 35)), // vencida/próxima
        veterinario: 'Dra. López', producto: 'Canigen', notas: 'Refuerzo anual',
      ));
    }

    return vacunas;
  }
}
