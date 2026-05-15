import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/mascota.dart';
import '../models/vacuna.dart';
import '../providers/auth_provider.dart';
import '../providers/mascotas_provider.dart';
import '../services/mascota_service.dart';
import '../services/vacuna_service.dart';
import '../services/storage_service.dart';
import '../widgets/widgets.dart';
import '../utils/constantes.dart';

class MascotaDetailScreen extends StatefulWidget {
  const MascotaDetailScreen({super.key});

  @override
  State<MascotaDetailScreen> createState() => _MascotaDetailScreenState();
}

class _MascotaDetailScreenState extends State<MascotaDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _razaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _chipController = TextEditingController();
  final _colorController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _propNombreController = TextEditingController();
  final _propTelefonoController = TextEditingController();
  final _propEmailController = TextEditingController();
  final _propDniController = TextEditingController();

  String? _mascotaId;
  String? _fotoUrl;
  String? _tokenCarnet;
  DateTime? _fechaNacimiento;
  DateTime? _fechaCreada;
  String _especie = 'Perro';
  String _sexo = 'Macho';
  bool _cargando = false;
  bool _guardando = false;
  List<Vacuna> _vacunas = [];
  StreamSubscription<List<Vacuna>>? _vacunasSubscription;

  final List<String> _especies = ['Perro', 'Gato', 'Conejo', 'Ave', 'Reptil', 'Otro'];
  final List<String> _sexos = ['Macho', 'Hembra', 'Desconocido'];

  bool get _modoEdicion => _mascotaId != null;

  String get _carnetUrl => 'https://vetclick-b0f5e.web.app/carnet/${_tokenCarnet ?? _mascotaId}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['mascotaId'] != null) {
      _mascotaId = args['mascotaId'] as String;
      _cargarMascota();
    }
  }

  Future<void> _cargarMascota() async {
    if (_mascotaId == null) return;
    setState(() => _cargando = true);
    try {
      final mascotaService = MascotaService();
      final mascota = await mascotaService.getMascota(_mascotaId!);
      if (mascota != null && mounted) {
        setState(() {
          _nombreController.text = mascota.nombre;
          _razaController.text = mascota.raza;
          _pesoController.text = mascota.peso.toString();
          _chipController.text = mascota.numeroChip ?? '';
          _colorController.text = mascota.color ?? '';
          _alergiasController.text = mascota.alergias.join(', ');
          _propNombreController.text = mascota.propietario.nombre;
          _propTelefonoController.text = mascota.propietario.telefono;
          _propEmailController.text = mascota.propietario.email ?? '';
          _propDniController.text = mascota.propietario.dni ?? '';
          _especie = mascota.especie;
          _sexo = mascota.sexo;
          _fechaNacimiento = mascota.fechaNacimiento;
          _fotoUrl = mascota.fotoUrl;
          _fechaCreada = mascota.creada;
          _tokenCarnet = mascota.tokenCarnet;
          _suscribirVacunas(mascota.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mascota: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  void _suscribirVacunas(String mascotaId) {
    _vacunasSubscription?.cancel();
    _vacunasSubscription = VacunaService().getVacunasStream(mascotaId).listen((vacunas) {
      if (mounted) setState(() => _vacunas = vacunas);
    });
  }

  Future<void> _subirFoto() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (imagen == null) return;

    if (_mascotaId == null) return;

    try {
      if (kIsWeb) {
        final bytes = await imagen.readAsBytes();
        final url = await StorageService().subirFotoMascotaWeb(bytes, mascotaId: _mascotaId!, extension: 'jpg');
        setState(() => _fotoUrl = url);
      } else {
        final file = File(imagen.path);
        final url = await StorageService().subirFotoMascota(file, mascotaId: _mascotaId!);
        setState(() => _fotoUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: kError),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mascotasProvider = Provider.of<MascotasProvider>(context, listen: false);

      final propietario = Propietario(
        nombre: _propNombreController.text.trim(),
        telefono: _propTelefonoController.text.trim(),
        email: _propEmailController.text.trim().isEmpty ? null : _propEmailController.text.trim(),
        dni: _propDniController.text.trim().isEmpty ? null : _propDniController.text.trim(),
      );

      final mascota = Mascota(
        id: _mascotaId ?? '',
        clinicaId: authProvider.clinicaId ?? '',
        nombre: _nombreController.text.trim(),
        especie: _especie,
        raza: _razaController.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        peso: _pesoController.text.trim().isEmpty ? 0.0 : double.tryParse(_pesoController.text.trim()) ?? 0.0,
        chip: _chipController.text.trim().isEmpty ? null : _chipController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        sexo: _sexo,
        alergias: _alergiasController.text.trim().isEmpty ? [] : _alergiasController.text.trim().split(',').map((e) => e.trim()).toList(),
        propietario: propietario,
        fotoUrl: _fotoUrl,
        creada: _fechaCreada ?? DateTime.now(),
      );

      if (_modoEdicion) {
        await mascotasProvider.actualizarMascota(mascota);
      } else {
        await mascotasProvider.crearMascota(mascota);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_modoEdicion ? 'Mascota actualizada' : 'Mascota creada'),
            backgroundColor: kPrimary,
          ),
        );
        if (!_modoEdicion) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    if (_mascotaId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: kError)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        final mascotasProvider = Provider.of<MascotasProvider>(context, listen: false);
        await mascotasProvider.eliminarMascota(_mascotaId!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: kError),
          );
        }
      }
    }
  }

  Future<void> _eliminarVacuna(Vacuna vacuna) async {
    if (_modoEdicion && _mascotaId != null) {
      try {
        await VacunaService().eliminarVacuna(_mascotaId!, vacuna.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar vacuna: $e'), backgroundColor: kError),
          );
        }
      }
    } else {
      setState(() => _vacunas.removeWhere((v) => v.id == vacuna.id));
    }
  }

  void _agregarVacuna() {
    final nombreController = TextEditingController();
    final fechaController = TextEditingController();
    final proximaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Vacuna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre de la vacuna'),
            ),
            TextField(
              controller: fechaController,
              decoration: const InputDecoration(labelText: 'Fecha (dd/mm/yyyy)', hintText: 'dd/mm/yyyy'),
            ),
            TextField(
              controller: proximaController,
              decoration: const InputDecoration(labelText: 'Próxima dosis (dd/mm/yyyy)', hintText: 'dd/mm/yyyy'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (nombreController.text.isNotEmpty) {
                final fecha = DateFormat('dd/MM/yyyy').tryParse(fechaController.text) ?? DateTime.now();
                final proxima = DateFormat('dd/MM/yyyy').tryParse(proximaController.text);
                final nuevaVacuna = Vacuna(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  mascotaId: _mascotaId ?? '',
                  tipo: 'Otra',
                  nombre: nombreController.text.trim(),
                  fecha: fecha,
                  proximaFecha: proxima,
                );
                if (_modoEdicion && _mascotaId != null) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await VacunaService().crearVacuna(_mascotaId!, nuevaVacuna);
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error al guardar vacuna: $e'), backgroundColor: kError),
                      );
                    }
                  }
                  if (mounted) navigator.pop();
                } else {
                  setState(() => _vacunas.add(nuevaVacuna));
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
    _chipController.dispose();
    _colorController.dispose();
    _alergiasController.dispose();
    _propNombreController.dispose();
    _propTelefonoController.dispose();
    _propEmailController.dispose();
    _propDniController.dispose();
    _vacunasSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _modoEdicion ? 'Editar Mascota' : 'Nueva Mascota',
        actions: [
          if (_modoEdicion)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: _cargando && _modoEdicion
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: kPrimaryLight.withAlpha(77),
                            backgroundImage: _fotoUrl != null && _fotoUrl!.isNotEmpty
                                ? NetworkImage(_fotoUrl!)
                                : null,
                            child: _fotoUrl == null || _fotoUrl!.isEmpty
                                ? const Icon(Icons.pets, size: 50, color: kPrimary)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: kPrimary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                onPressed: _subirFoto,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Card Datos
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Datos de la Mascota', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.pets)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _especie,
                              decoration: const InputDecoration(labelText: 'Especie', prefixIcon: Icon(Icons.category)),
                              items: _especies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => _especie = v ?? 'Perro'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _razaController,
                              decoration: const InputDecoration(labelText: 'Raza *', prefixIcon: Icon(Icons.label)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _seleccionarFecha,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de nacimiento',
                                  prefixIcon: Icon(Icons.cake),
                                ),
                                child: Text(
                                  _fechaNacimiento != null
                                      ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                                      : 'Seleccionar fecha',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pesoController,
                              decoration: const InputDecoration(labelText: 'Peso (kg)', prefixIcon: Icon(Icons.monitor_weight)),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _chipController,
                              decoration: const InputDecoration(labelText: 'Número de chip', prefixIcon: Icon(Icons.memory)),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _colorController,
                              decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.color_lens)),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _sexo,
                              decoration: const InputDecoration(labelText: 'Sexo', prefixIcon: Icon(Icons.wc)),
                              items: _sexos.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _sexo = v ?? 'Macho'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _alergiasController,
                              decoration: const InputDecoration(labelText: 'Alergias / Notas médicas', prefixIcon: Icon(Icons.healing)),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card Propietario
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Propietario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _propNombreController,
                              decoration: const InputDecoration(labelText: 'Nombre *', prefixIcon: Icon(Icons.person)),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _propTelefonoController,
                              decoration: const InputDecoration(labelText: 'Teléfono *', prefixIcon: Icon(Icons.phone)),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _propEmailController,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _propDniController,
                              decoration: const InputDecoration(labelText: 'DNI', prefixIcon: Icon(Icons.badge)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card Vacunas
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vacunas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                TextButton.icon(
                                  onPressed: _agregarVacuna,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Vacuna'),
                                ),
                              ],
                            ),
                            if (_vacunas.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Sin vacunas registradas', style: TextStyle(color: kTextSecondary)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _vacunas.length,
                                itemBuilder: (context, index) {
                                  final vacuna = _vacunas[index];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.vaccines, color: kPrimary),
                                    title: Text(vacuna.nombre),
                                    subtitle: Text(
                                      'Fecha: ${vacuna.fecha.day}/${vacuna.fecha.month}/${vacuna.fecha.year}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (vacuna.proximaFecha != null)
                                          Text(
                                            'Próx: ${vacuna.proximaFecha!.day}/${vacuna.proximaFecha!.month}/${vacuna.proximaFecha!.year}',
                                            style: const TextStyle(fontSize: 12, color: kAccent),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18, color: kError),
                                          onPressed: () => _eliminarVacuna(vacuna),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card Carnet
                    if (_modoEdicion)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('Carnet Digital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                _carnetUrl,
                                style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              QrCarnet(url: _carnetUrl, size: 180),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _carnetUrl));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('URL copiada al portapapeles')),
                                      );
                                    },
                                    icon: const Icon(Icons.copy, size: 18),
                                    label: const Text('Copiar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => Share.share(_carnetUrl),
                                    icon: const Icon(Icons.share, size: 18),
                                    label: const Text('Compartir'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : Text(
                                _modoEdicion ? 'Guardar Cambios' : 'Guardar Mascota',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
