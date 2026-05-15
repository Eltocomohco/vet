import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:vetmanager/models/mascota.dart';
import 'package:vetmanager/services/mascota_service.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Resultado de una operación de importación
class ImportResult {
  final int totalFilas;
  final int importadas;
  final int errores;
  final List<String> mensajesError;

  ImportResult({
    required this.totalFilas,
    required this.importadas,
    required this.errores,
    required this.mensajesError,
  });
}

/// Servicio para exportar e importar datos en formato CSV
class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exporta todas las mascotas de una clínica a CSV
  Future<String> exportarMascotasCSV(String clinicaId) async {
    final snapshot = await _firestore
        .collection(coleccionMascotas)
        .where('clinicaId', isEqualTo: clinicaId)
        .orderBy('nombre')
        .get();

    final List<List<String>> rows = [];
    rows.add([
      'nombre_mascota',
      'especie',
      'raza',
      'fecha_nacimiento',
      'peso_kg',
      'sexo',
      'chip',
      'color',
      'alergias',
      'nombre_dueno',
      'telefono_dueno',
      'email_dueno',
      'dni_dueno',
    ]);

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final prop = data['propietario'] as Map<String, dynamic>?;
      final alergias = (data['alergias'] as List<dynamic>?)?.join('; ') ?? '';
      final fechaNac = data['fechaNacimiento'] != null
          ? (data['fechaNacimiento'] as Timestamp).toDate()
          : null;

      rows.add([
        _escapeCsv(data['nombre']?.toString() ?? ''),
        _escapeCsv(data['especie']?.toString() ?? ''),
        _escapeCsv(data['raza']?.toString() ?? ''),
        _escapeCsv(fechaNac != null ? '${fechaNac.day}/${fechaNac.month}/${fechaNac.year}' : ''),
        _escapeCsv(data['peso']?.toString() ?? ''),
        _escapeCsv(data['sexo']?.toString() ?? ''),
        _escapeCsv(data['chip']?.toString() ?? ''),
        _escapeCsv(data['color']?.toString() ?? ''),
        _escapeCsv(alergias),
        _escapeCsv(prop?['nombre']?.toString() ?? ''),
        _escapeCsv(prop?['telefono']?.toString() ?? ''),
        _escapeCsv(prop?['email']?.toString() ?? ''),
        _escapeCsv(prop?['dni']?.toString() ?? ''),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exporta citas de una clínica a CSV, opcionalmente filtradas por rango
  Future<String> exportarCitasCSV(
    String clinicaId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    Query query = _firestore
        .collection(coleccionCitas)
        .where('clinicaId', isEqualTo: clinicaId)
        .orderBy('fechaHora');

    if (desde != null) {
      query = query.where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(desde));
    }
    if (hasta != null) {
      query = query.where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(hasta));
    }

    final snapshot = await query.get();

    final List<List<String>> rows = [];
    rows.add([
      'fecha_hora',
      'mascota_nombre',
      'propietario_nombre',
      'propietario_telefono',
      'motivo',
      'estado',
      'duracion_minutos',
      'notas',
    ]);

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fechaHora = data['fechaHora'] != null
          ? (data['fechaHora'] as Timestamp).toDate()
          : null;

      rows.add([
        _escapeCsv(fechaHora != null
            ? '${fechaHora.day}/${fechaHora.month}/${fechaHora.year} ${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}'
            : ''),
        _escapeCsv(data['mascotaNombre']?.toString() ?? ''),
        _escapeCsv(data['propietarioNombre']?.toString() ?? ''),
        _escapeCsv(data['propietarioTelefono']?.toString() ?? ''),
        _escapeCsv(data['motivo']?.toString() ?? ''),
        _escapeCsv(data['estado']?.toString() ?? ''),
        _escapeCsv(data['duracionMinutos']?.toString() ?? ''),
        _escapeCsv(data['notas']?.toString() ?? ''),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exporta todas las vacunas de una clínica a CSV
  Future<String> exportarVacunasCSV(String clinicaId) async {
    final mascotasSnapshot = await _firestore
        .collection(coleccionMascotas)
        .where('clinicaId', isEqualTo: clinicaId)
        .get();

    final List<List<String>> rows = [];
    rows.add([
      'mascota_nombre',
      'tipo_vacuna',
      'nombre_vacuna',
      'fecha',
      'proxima_fecha',
      'veterinario',
      'producto',
      'notas',
    ]);

    for (final mascotaDoc in mascotasSnapshot.docs) {
      final mascotaData = mascotaDoc.data();
      final mascotaNombre = mascotaData['nombre']?.toString() ?? '';

      final vacunasSnapshot = await _firestore
          .collection(coleccionMascotas)
          .doc(mascotaDoc.id)
          .collection(coleccionVacunas)
          .orderBy('fecha', descending: true)
          .get();

      for (final vacunaDoc in vacunasSnapshot.docs) {
        final data = vacunaDoc.data();
        final fecha = data['fecha'] != null
            ? (data['fecha'] as Timestamp).toDate()
            : null;
        final proximaFecha = data['proximaFecha'] != null
            ? (data['proximaFecha'] as Timestamp).toDate()
            : null;

        rows.add([
          _escapeCsv(mascotaNombre),
          _escapeCsv(data['tipo']?.toString() ?? ''),
          _escapeCsv(data['nombre']?.toString() ?? ''),
          _escapeCsv(fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : ''),
          _escapeCsv(proximaFecha != null ? '${proximaFecha.day}/${proximaFecha.month}/${proximaFecha.year}' : ''),
          _escapeCsv(data['veterinario']?.toString() ?? ''),
          _escapeCsv(data['producto']?.toString() ?? ''),
          _escapeCsv(data['notas']?.toString() ?? ''),
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Importa mascotas desde contenido CSV
  Future<ImportResult> importarMascotasCSV(String clinicaId, String csvContent) async {
    final List<String> mensajesError = [];
    int importadas = 0;
    int errores = 0;

    try {
      final List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        eol: '\n',
      ).convert(csvContent);

      if (rows.isEmpty) {
        return ImportResult(totalFilas: 0, importadas: 0, errores: 1, mensajesError: ['CSV vacío']);
      }

      final headers = rows.first.map((h) => h.toString().toLowerCase().trim()).toList();
      final dataRows = rows.skip(1).toList();

      // Mapeo flexible de headers
      int idx(String key) {
        final candidates = {
          'nombre': ['nombre', 'nombre_mascota', 'mascota', 'name'],
          'especie': ['especie', 'especie_mascota', 'species'],
          'raza': ['raza', 'raza_mascota', 'breed'],
          'fecha_nacimiento': ['fecha_nacimiento', 'fecha_nac', 'nacimiento', 'birthdate', 'fecha de nacimiento'],
          'peso': ['peso', 'peso_kg', 'weight', 'peso kg'],
          'sexo': ['sexo', 'genero', 'gender', 'sex'],
          'chip': ['chip', 'numero_chip', 'microchip', 'número chip'],
          'color': ['color', 'colour'],
          'alergias': ['alergias', 'alergia', 'allergies'],
          'nombre_dueno': ['nombre_dueno', 'nombre_propietario', 'dueno', 'propietario', 'owner_name', 'dueño'],
          'telefono_dueno': ['telefono_dueno', 'telefono_propietario', 'telefono', 'phone', 'teléfono', 'teléfono dueño'],
          'email_dueno': ['email_dueno', 'email_propietario', 'email', 'correo', 'e-mail'],
          'dni_dueno': ['dni_dueno', 'dni_propietario', 'dni', 'documento', 'nif'],
        };
        for (final candidate in candidates[key]!) {
          final index = headers.indexOf(candidate);
          if (index != -1) return index;
        }
        return -1;
      }

      final iNombre = idx('nombre');
      final iEspecie = idx('especie');
      final iRaza = idx('raza');
      final iFechaNac = idx('fecha_nacimiento');
      final iPeso = idx('peso');
      final iSexo = idx('sexo');
      final iChip = idx('chip');
      final iColor = idx('color');
      final iAlergias = idx('alergias');
      final iNombreDueno = idx('nombre_dueno');
      final iTelefonoDueno = idx('telefono_dueno');
      final iEmailDueno = idx('email_dueno');
      final iDniDueno = idx('dni_dueno');

      final mascotaService = MascotaService();

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final filaNum = i + 2; // Fila en CSV (1-based + header)

        try {
          final nombre = iNombre != -1 && iNombre < row.length ? row[iNombre].toString().trim() : '';
          final telefonoDueno = iTelefonoDueno != -1 && iTelefonoDueno < row.length
              ? row[iTelefonoDueno].toString().trim()
              : '';

          if (nombre.isEmpty) {
            errores++;
            mensajesError.add('Fila $filaNum: nombre de mascota vacío');
            continue;
          }
          if (telefonoDueno.isEmpty) {
            errores++;
            mensajesError.add('Fila $filaNum: teléfono del dueño vacío');
            continue;
          }

          final especie = (iEspecie != -1 && iEspecie < row.length ? row[iEspecie].toString().trim() : 'Otro');
          final raza = (iRaza != -1 && iRaza < row.length ? row[iRaza].toString().trim() : 'Otro');
          final fechaNacStr = iFechaNac != -1 && iFechaNac < row.length ? row[iFechaNac].toString().trim() : '';
          final pesoStr = iPeso != -1 && iPeso < row.length ? row[iPeso].toString().trim() : '0';
          final sexo = (iSexo != -1 && iSexo < row.length ? row[iSexo].toString().trim() : 'Desconocido');
          final chip = iChip != -1 && iChip < row.length ? row[iChip].toString().trim() : '';
          final color = iColor != -1 && iColor < row.length ? row[iColor].toString().trim() : '';
          final alergiasStr = iAlergias != -1 && iAlergias < row.length ? row[iAlergias].toString().trim() : '';
          final nombreDueno = iNombreDueno != -1 && iNombreDueno < row.length ? row[iNombreDueno].toString().trim() : '';
          final emailDueno = iEmailDueno != -1 && iEmailDueno < row.length ? row[iEmailDueno].toString().trim() : '';
          final dniDueno = iDniDueno != -1 && iDniDueno < row.length ? row[iDniDueno].toString().trim() : '';

          DateTime? fechaNacimiento;
          if (fechaNacStr.isNotEmpty) {
            fechaNacimiento = DateFormat('dd/MM/yyyy').tryParse(fechaNacStr)
                ?? DateFormat('yyyy-MM-dd').tryParse(fechaNacStr)
                ?? DateFormat('dd-MM-yyyy').tryParse(fechaNacStr);
          }

          final peso = double.tryParse(pesoStr.replaceAll(',', '.')) ?? 0.0;
          final alergias = alergiasStr.isNotEmpty
              ? alergiasStr.split(';').map((a) => a.trim()).where((a) => a.isNotEmpty).toList()
              : <String>[];

          final mascota = Mascota(
            id: '', // Se generará en Firestore
            clinicaId: clinicaId,
            nombre: nombre,
            especie: especie,
            raza: raza,
            fechaNacimiento: fechaNacimiento,
            peso: peso,
            alergias: alergias,
            chip: chip.isNotEmpty ? chip : null,
            color: color.isNotEmpty ? color : null,
            sexo: sexo,
            propietario: Propietario(
              nombre: nombreDueno.isNotEmpty ? nombreDueno : 'Sin nombre',
              telefono: telefonoDueno,
              email: emailDueno.isNotEmpty ? emailDueno : null,
              dni: dniDueno.isNotEmpty ? dniDueno : null,
            ),
            fotoUrl: null,
            tokenCarnet: Mascota.generarTokenCarnet(),
            creada: DateTime.now(),
          );

          await mascotaService.crearMascota(mascota);
          importadas++;
        } catch (e) {
          errores++;
          mensajesError.add('Fila $filaNum: $e');
        }
      }

      return ImportResult(
        totalFilas: dataRows.length,
        importadas: importadas,
        errores: errores,
        mensajesError: mensajesError,
      );
    } catch (e) {
      return ImportResult(
        totalFilas: 0,
        importadas: 0,
        errores: 1,
        mensajesError: ['Error parseando CSV: $e'],
      );
    }
  }

  /// Devuelve las primeras 10 filas de un CSV como lista de mapas
  Future<List<Map<String, String>>> previewImportacion(String csvContent) async {
    final List<Map<String, String>> result = [];

    try {
      final List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        eol: '\n',
      ).convert(csvContent);

      if (rows.isEmpty) return result;

      final headers = rows.first.map((h) => h.toString().trim()).toList();
      final dataRows = rows.skip(1).take(10).toList();

      for (final row in dataRows) {
        final map = <String, String>{};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          map[headers[i]] = row[i].toString();
        }
        result.add(map);
      }
    } catch (_) {
      // Silenciar errores en preview
    }

    return result;
  }

  /// Escapa comas y comillas para CSV correcto
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
