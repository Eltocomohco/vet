import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../services/export_service.dart';
import '../utils/constantes.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _csvController = TextEditingController();
  final ExportService _exportService = ExportService();

  bool _exportando = false;
  bool _importando = false;
  bool _previewCargando = false;

  List<Map<String, String>> _previewRows = [];
  ImportResult? _ultimoResultado;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  String? get _clinicaId {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.clinicaId;
  }

  Future<void> _exportarMascotas() async {
    final clinicaId = _clinicaId;
    if (clinicaId == null || clinicaId.isEmpty) {
      _mostrarError('No hay clínica seleccionada');
      return;
    }
    setState(() => _exportando = true);
    try {
      final csv = await _exportService.exportarMascotasCSV(clinicaId);
      await _descargarOCompartir(csv, 'mascotas_vetclick.csv');
      _mostrarExito('Mascotas exportadas correctamente');
    } catch (e) {
      _mostrarError('Error exportando mascotas: $e');
    } finally {
      setState(() => _exportando = false);
    }
  }

  Future<void> _exportarCitas() async {
    final clinicaId = _clinicaId;
    if (clinicaId == null || clinicaId.isEmpty) {
      _mostrarError('No hay clínica seleccionada');
      return;
    }
    setState(() => _exportando = true);
    try {
      final csv = await _exportService.exportarCitasCSV(clinicaId);
      await _descargarOCompartir(csv, 'citas_vetclick.csv');
      _mostrarExito('Citas exportadas correctamente');
    } catch (e) {
      _mostrarError('Error exportando citas: $e');
    } finally {
      setState(() => _exportando = false);
    }
  }

  Future<void> _exportarVacunas() async {
    final clinicaId = _clinicaId;
    if (clinicaId == null || clinicaId.isEmpty) {
      _mostrarError('No hay clínica seleccionada');
      return;
    }
    setState(() => _exportando = true);
    try {
      final csv = await _exportService.exportarVacunasCSV(clinicaId);
      await _descargarOCompartir(csv, 'vacunas_vetclick.csv');
      _mostrarExito('Vacunas exportadas correctamente');
    } catch (e) {
      _mostrarError('Error exportando vacunas: $e');
    } finally {
      setState(() => _exportando = false);
    }
  }

  Future<void> _descargarOCompartir(String contenido, String nombreArchivo) async {
    if (kIsWeb) {
      final bytes = Uint8List.fromList(contenido.codeUnits);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Share.share(
        contenido,
        subject: nombreArchivo,
      );
    }
  }

  Future<void> _vistaPrevia() async {
    final contenido = _csvController.text.trim();
    if (contenido.isEmpty) {
      _mostrarError('Pega el contenido CSV primero');
      return;
    }
    setState(() => _previewCargando = true);
    try {
      final preview = await _exportService.previewImportacion(contenido);
      setState(() {
        _previewRows = preview;
        _ultimoResultado = null;
      });
    } catch (e) {
      _mostrarError('Error en vista previa: $e');
    } finally {
      setState(() => _previewCargando = false);
    }
  }

  Future<void> _importar() async {
    final contenido = _csvController.text.trim();
    if (contenido.isEmpty) {
      _mostrarError('Pega el contenido CSV primero');
      return;
    }
    final clinicaId = _clinicaId;
    if (clinicaId == null || clinicaId.isEmpty) {
      _mostrarError('No hay clínica seleccionada');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar importación'),
        content: const Text('Se importarán las mascotas del CSV. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Importar', style: TextStyle(color: kPrimary))),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _importando = true);
    try {
      final resultado = await _exportService.importarMascotasCSV(clinicaId, contenido);
      setState(() => _ultimoResultado = resultado);
      if (resultado.errores == 0) {
        _mostrarExito('${resultado.importadas} mascotas importadas correctamente');
      } else {
        _mostrarAdvertencia('${resultado.importadas} importadas, ${resultado.errores} errores');
      }
    } catch (e) {
      _mostrarError('Error importando: $e');
    } finally {
      setState(() => _importando = false);
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: kPrimary),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: kError),
    );
  }

  void _mostrarAdvertencia(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: kStatusPendiente),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar / Exportar'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCION EXPORTAR
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.download, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Exportar datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_exportando)
                      const Center(child: CircularProgressIndicator())
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _exportarMascotas,
                              icon: const Icon(Icons.pets),
                              label: const Text('Exportar Mascotas CSV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _exportarCitas,
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Exportar Citas CSV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _exportarVacunas,
                              icon: const Icon(Icons.vaccines),
                              label: const Text('Exportar Vacunas CSV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryLight,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // SECCION IMPORTAR
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.upload, color: kAccent),
                        SizedBox(width: 8),
                        Text('Importar mascotas desde CSV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pega el contenido CSV con headers. Formatos aceptados: nombre, especie, raza, fecha_nacimiento, peso, sexo, chip, color, alergias, nombre_dueno, telefono_dueno, email_dueno, dni_dueno',
                      style: TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _csvController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'nombre,especie,raza,telefono_dueno...\nLuna,Perro,Labrador,+34600123456\nMimi,Gato,Siames,+34600987654',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _previewCargando ? null : _vistaPrevia,
                            icon: _previewCargando
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.preview),
                            label: const Text('Vista previa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryLight,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _importando ? null : _importar,
                            icon: _importando
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.upload_file),
                            label: const Text('Importar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Vista previa
                    if (_previewRows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Vista previa (primeras 10 filas):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(colorFondoOscuro),
                          columns: _previewRows.first.keys.map((k) => DataColumn(label: Text(k, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
                          rows: _previewRows.map((row) {
                            return DataRow(
                              cells: row.values.map((v) => DataCell(Text(v, style: const TextStyle(fontSize: 12)))).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    // Resultado importación
                    if (_ultimoResultado != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: _ultimoResultado!.errores == 0 ? colorExitoClaro : colorAdvertenciaClaro,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_ultimoResultado!.importadas} mascotas importadas de ${_ultimoResultado!.totalFilas}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _ultimoResultado!.errores == 0 ? colorExito : colorAdvertencia,
                                ),
                              ),
                              if (_ultimoResultado!.errores > 0) ...[
                                const SizedBox(height: 4),
                                Text('${_ultimoResultado!.errores} errores:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                ..._ultimoResultado!.mensajesError.take(5).map((e) => Text('• $e', style: const TextStyle(fontSize: 11))),
                                if (_ultimoResultado!.mensajesError.length > 5)
                                  Text('... y ${_ultimoResultado!.mensajesError.length - 5} errores más', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
