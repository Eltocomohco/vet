import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clinica.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../providers/clinica_provider.dart';
import '../services/seed_service.dart';
import '../services/biometric_service.dart';
import '../utils/constantes.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _plantillaRecordatorioController = TextEditingController();
  final _plantillaVacunaController = TextEditingController();

  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final List<bool> _abierto = List.generate(7, (_) => true);
  final List<TextEditingController> _mananaInicio = List.generate(7, (_) => TextEditingController(text: '09:00'));
  final List<TextEditingController> _mananaFin = List.generate(7, (_) => TextEditingController(text: '14:00'));
  final List<TextEditingController> _tardeInicio = List.generate(7, (_) => TextEditingController(text: '17:00'));
  final List<TextEditingController> _tardeFin = List.generate(7, (_) => TextEditingController(text: '20:00'));

  bool _recordatorio24h = true;
  bool _recordatorio2h = true;
  bool _recordatorio7d = false;
  bool _guardando = false;
  bool _camposInicializados = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clinicaProvider = Provider.of<ClinicaProvider>(context, listen: false);
      if (authProvider.clinicaId != null) {
        clinicaProvider.cargarClinica(authProvider.clinicaId!);
      }
      if (clinicaProvider.clinica != null) {
        _inicializarCampos(clinicaProvider.clinica!);
      }
    });
  }

  void _inicializarCampos(Clinica clinica) {
    if (!mounted || _camposInicializados) return;
    _nombreController.text = clinica.nombre;
    _direccionController.text = clinica.direccion;
    _telefonoController.text = clinica.telefono;
    _emailController.text = clinica.email;
    final config = clinica.configuracionWhatsApp;
    _whatsappController.text = config['numero'] ?? '';
    _plantillaRecordatorioController.text = config['plantillaRecordatorio'] ?? '';
    _plantillaVacunaController.text = config['plantillaVacuna'] ?? '';
    final recordatorios = config['recordatorios'] as Map<String, dynamic>?;
    if (recordatorios != null) {
      _recordatorio24h = recordatorios['24h'] ?? true;
      _recordatorio2h = recordatorios['2h'] ?? true;
      _recordatorio7d = recordatorios['7d'] ?? false;
    }
    final horario = clinica.horario;
    for (int i = 0; i < 7; i++) {
      final diaKey = _dias[i].toLowerCase();
      final diaData = horario[diaKey] as Map<String, dynamic>?;
      if (diaData != null) {
        _abierto[i] = diaData['abierto'] ?? true;
        final manana = diaData['manana'] as Map<String, dynamic>?;
        if (manana != null) {
          _mananaInicio[i].text = manana['inicio'] ?? '09:00';
          _mananaFin[i].text = manana['fin'] ?? '14:00';
        }
        final tarde = diaData['tarde'] as Map<String, dynamic>?;
        if (tarde != null) {
          _tardeInicio[i].text = tarde['inicio'] ?? '17:00';
          _tardeFin[i].text = tarde['fin'] ?? '20:00';
        }
      }
    }
    _camposInicializados = true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _plantillaRecordatorioController.dispose();
    _plantillaVacunaController.dispose();
    for (var c in _mananaInicio) { c.dispose(); }
    for (var c in _mananaFin) { c.dispose(); }
    for (var c in _tardeInicio) { c.dispose(); }
    for (var c in _tardeFin) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    setState(() => _guardando = true);
    try {
      final clinicaProvider = Provider.of<ClinicaProvider>(context, listen: false);
      final horario = <String, dynamic>{};
      for (int i = 0; i < 7; i++) {
        horario[_dias[i].toLowerCase()] = {
          'abierto': _abierto[i],
          'manana': {
            'inicio': _mananaInicio[i].text,
            'fin': _mananaFin[i].text,
          },
          'tarde': {
            'inicio': _tardeInicio[i].text,
            'fin': _tardeFin[i].text,
          },
        };
      }
      final clinicaActual = clinicaProvider.clinica;
      if (clinicaActual == null) {
        throw Exception('No hay clínica cargada');
      }
      final nuevaConfig = Map<String, dynamic>.from(clinicaActual.configuracionWhatsApp);
      nuevaConfig['numero'] = _whatsappController.text.trim();
      nuevaConfig['plantillaRecordatorio'] = _plantillaRecordatorioController.text.trim();
      nuevaConfig['plantillaVacuna'] = _plantillaVacunaController.text.trim();
      nuevaConfig['recordatorios'] = {
        '24h': _recordatorio24h,
        '2h': _recordatorio2h,
        '7d': _recordatorio7d,
      };
      await clinicaProvider.actualizarClinica(
        clinicaActual.copyWith(
          nombre: _nombreController.text.trim(),
          direccion: _direccionController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          horario: horario,
          configuracionWhatsApp: nuevaConfig,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados'), backgroundColor: kPrimary),
        );
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

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión', style: TextStyle(color: kError)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicaProvider = Provider.of<ClinicaProvider>(context);
    if (clinicaProvider.clinica != null && !_camposInicializados) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inicializarCampos(clinicaProvider.clinica!);
      });
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text('Configuración', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Datos Clínica
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Datos de la Clínica', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre de la clínica', prefixIcon: Icon(Icons.business)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card Horario
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Horario de Atención', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < 7; i++) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _abierto[i],
                            onChanged: (v) => setState(() => _abierto[i] = v ?? false),
                            activeColor: kPrimary,
                          ),
                          SizedBox(width: 70, child: Text(_dias[i], style: const TextStyle(fontWeight: FontWeight.w500))),
                          if (_abierto[i]) ...[
                            Expanded(
                              child: TextField(
                                controller: _mananaInicio[i],
                                decoration: const InputDecoration(isDense: true, labelText: 'M. inicio'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Text(' - '),
                            Expanded(
                              child: TextField(
                                controller: _mananaFin[i],
                                decoration: const InputDecoration(isDense: true, labelText: 'M. fin'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Text(' | '),
                            Expanded(
                              child: TextField(
                                controller: _tardeInicio[i],
                                decoration: const InputDecoration(isDense: true, labelText: 'T. inicio'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Text(' - '),
                            Expanded(
                              child: TextField(
                                controller: _tardeFin[i],
                                decoration: const InputDecoration(isDense: true, labelText: 'T. fin'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ] else
                            const Text('Cerrado', style: TextStyle(color: kTextSecondary)),
                        ],
                      ),
                      if (i < 6) const Divider(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card WhatsApp
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.message, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Configuración WhatsApp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                        labelText: 'Número de WhatsApp',
                        prefixIcon: Icon(Icons.phone),
                        hintText: '+34123456789',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _plantillaRecordatorioController,
                      decoration: const InputDecoration(
                        labelText: 'Plantilla recordatorio de cita',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _plantillaVacunaController,
                      decoration: const InputDecoration(
                        labelText: 'Plantilla recordatorio de vacuna',
                        prefixIcon: Icon(Icons.vaccines),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const Text('Enviar recordatorios:', style: TextStyle(fontWeight: FontWeight.w500)),
                    CheckboxListTile(
                      value: _recordatorio24h,
                      onChanged: (v) => setState(() => _recordatorio24h = v ?? true),
                      title: const Text('24 horas antes'),
                      activeColor: kPrimary,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: _recordatorio2h,
                      onChanged: (v) => setState(() => _recordatorio2h = v ?? true),
                      title: const Text('2 horas antes'),
                      activeColor: kPrimary,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: _recordatorio7d,
                      onChanged: (v) => setState(() => _recordatorio7d = v ?? false),
                      title: const Text('7 días antes'),
                      activeColor: kPrimary,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card Veterinarios
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
                        const Row(
                          children: [
                            Icon(Icons.people, color: kPrimary),
                            SizedBox(width: 8),
                            Text('Veterinarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _mostrarDialogoInvitarVeterinario(),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Invitar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Admin'),
                      subtitle: Text('Administrador'),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card Seguridad
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Seguridad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<bool>(
                      future: BiometricService.canCheckBiometrics(),
                      builder: (context, snapshot) {
                        final available = snapshot.data ?? false;
                        if (!available) {
                          return const ListTile(
                            dense: true,
                            leading: Icon(Icons.fingerprint, color: Colors.grey),
                            title: Text('Biometría no disponible'),
                            subtitle: Text('Este dispositivo no soporta huella o Face ID'),
                          );
                        }
                        return FutureBuilder<bool>(
                          future: BiometricService.isBiometricEnabled(),
                          builder: (context, enabledSnap) {
                            final enabled = enabledSnap.data ?? false;
                            return SwitchListTile(
                              dense: true,
                              secondary: const Icon(Icons.fingerprint, color: kPrimary),
                              title: const Text('Desbloqueo con huella'),
                              subtitle: const Text('Accede más rápido a la app'),
                              value: enabled,
                              onChanged: (val) async {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                final userId = auth.usuario?.id ?? '';
                                if (val) {
                                  // Pedir autenticación para confirmar
                                  final success = await BiometricService.authenticate(
                                    reason: 'Confirma tu identidad para activar el desbloqueo',
                                  );
                                  if (success) {
                                    await BiometricService.setBiometricEnabled(userId, true);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Desbloqueo biométrico activado')),
                                      );
                                    }
                                  }
                                } else {
                                  await BiometricService.setBiometricEnabled(userId, false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Desbloqueo biométrico desactivado')),
                                    );
                                  }
                                }
                                setState(() {});
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card Importar/Exportar
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.import_export, color: kPrimary),
                        SizedBox(width: 8),
                        Text('Datos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.file_download, color: kPrimary),
                      title: const Text('Importar / Exportar datos'),
                      subtitle: const Text('CSV de mascotas, citas y vacunas'),
                      dense: true,
                      onTap: () => Navigator.pushNamed(context, '/importar-exportar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card Datos de prueba (solo autenticado, no demo)
            if (!Provider.of<AuthProvider>(context, listen: false).modoDemo)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.grass, color: kPrimary),
                          SizedBox(width: 8),
                          Text('Desarrollo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.playlist_add, color: kPrimary),
                        title: const Text('Cargar datos de prueba'),
                        subtitle: const Text('6 mascotas, 8 citas, vacunas'),
                        dense: true,
                        onTap: () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final clinicaId = auth.clinicaId;
                          if (clinicaId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No hay clínica asociada')),
                            );
                            return;
                          }
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cargar datos de prueba'),
                              content: const Text('Se crearán mascotas, citas y vacunas de ejemplo en tu clínica. ¿Continuar?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cargar')),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          try {
                            final resumen = await SeedService().seedClinicaDemoData(clinicaId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Datos creados: ${resumen['mascotas']} mascotas, ${resumen['citas']} citas, ${resumen['vacunas']} vacunas')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al crear datos: $e'), backgroundColor: kError),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (!Provider.of<AuthProvider>(context, listen: false).modoDemo)
              const SizedBox(height: 16),
            // Card Plan
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: kAccent),
                        SizedBox(width: 8),
                        Text('Plan Actual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: kPrimary),
                      title: Text('Plan Básico'),
                      subtitle: Text('Funciones esenciales incluidas'),
                      dense: true,
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
                onPressed: _guardando ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoInvitarVeterinario() async {
    final emailController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final clinicaId = authProvider.clinicaId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitar veterinario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Introduce el email del veterinario que quieres invitar.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Introduce un email válido';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Introduce un email válido'), backgroundColor: kError),
                );
                return;
              }
              if (clinicaId == null || clinicaId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay clínica seleccionada'), backgroundColor: kError),
                );
                return;
              }

              Navigator.pop(context);

              // Generar token
              const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
              final random = DateTime.now().millisecondsSinceEpoch.toString();
              final token = List.generate(20, (i) => chars[(random.codeUnitAt(i % random.length) + i) % chars.length]).join();

              try {
                await FirebaseFirestore.instance.collection('invitations').doc(token).set({
                  'email': email,
                  'clinicaId': clinicaId,
                  'creada': FieldValue.serverTimestamp(),
                  'usado': false,
                });

                final url = 'https://vetclick-b0f5e.web.app/registro?token=$token&clinicaId=$clinicaId';

                await Clipboard.setData(ClipboardData(text: url));

                if (mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Enlace copiado al portapapeles para $email'),
                      backgroundColor: kPrimary,
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error generando invitación: $e'), backgroundColor: kError),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            child: const Text('Generar enlace'),
          ),
        ],
      ),
    );

    emailController.dispose();
  }
}
