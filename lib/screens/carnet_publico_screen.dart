import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mascota.dart';
import '../models/vacuna.dart';
import '../services/mascota_service.dart';
import '../services/vacuna_service.dart';
import '../widgets/qr_carnet.dart';
import '../utils/constantes.dart';

class CarnetPublicoScreen extends StatefulWidget {
  const CarnetPublicoScreen({super.key});

  @override
  State<CarnetPublicoScreen> createState() => _CarnetPublicoScreenState();
}

class _CarnetPublicoScreenState extends State<CarnetPublicoScreen> {
  String? _token;
  Mascota? _mascota;
  bool _cargando = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    if (args == null || args['token'] == null) {
      setState(() {
        _error = 'Carnet no encontrado';
        _cargando = false;
      });
      return;
    }
    _token = args['token'];
    _buscarMascota();
  }

  Future<void> _buscarMascota() async {
    if (_token == null) return;
    try {
      final mascotaService = MascotaService();
      final mascota = await mascotaService.getMascotaPorToken(_token!);
      if (mounted) {
        setState(() {
          _mascota = mascota;
          _cargando = false;
          if (mascota == null) {
            _error = 'No se encontró la mascota con este carnet';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar el carnet: $e';
          _cargando = false;
        });
      }
    }
  }

  int? _calcularEdad(DateTime? fechaNacimiento) {
    if (fechaNacimiento == null) return null;
    final ahora = DateTime.now();
    int edad = ahora.year - fechaNacimiento.year;
    if (ahora.month < fechaNacimiento.month ||
        (ahora.month == fechaNacimiento.month && ahora.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  Future<void> _llamarTelefono(String telefono) async {
    final url = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        body: Container(
          color: kPrimaryLight.withAlpha(38),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Container(
          color: kPrimaryLight.withAlpha(38),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: kError),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final mascota = _mascota!;
    final edad = _calcularEdad(mascota.fechaNacimiento);
    final carnetUrl = 'https://vetclick-b0f5e.web.app/carnet/${mascota.tokenCarnet}';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryLight.withAlpha(77),
              kPrimaryLight.withAlpha(26),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Nombre clínica
                    const Text(
                      'VetClick',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Carnet Digital de Mascota',
                      style: TextStyle(fontSize: 14, color: kTextSecondary),
                    ),
                    const SizedBox(height: 24),
                    // Card principal
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Foto
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: kPrimaryLight.withAlpha(77),
                              backgroundImage: mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty
                                  ? NetworkImage(mascota.fotoUrl!)
                                  : null,
                              child: mascota.fotoUrl == null || mascota.fotoUrl!.isEmpty
                                  ? const Icon(Icons.pets, size: 60, color: kPrimary)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            // Nombre mascota
                            Text(
                              mascota.nombre,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Info rápida
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                _infoChip(Icons.pets, mascota.raza),
                                if (edad != null) _infoChip(Icons.cake, '$edad años'),
                                if (mascota.peso > 0) _infoChip(Icons.monitor_weight, '${mascota.peso} kg'),
                                _infoChip(Icons.wc, mascota.sexo),
                              ],
                            ),
                            if (mascota.numeroChip != null && mascota.numeroChip!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Chip: ${mascota.numeroChip}',
                                style: const TextStyle(fontSize: 13, color: kTextSecondary),
                              ),
                            ],
                            const Divider(height: 32),
                            // Vacunas
                            StreamBuilder<List<Vacuna>>(
                              stream: VacunaService().getVacunasStream(mascota.id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final vacunas = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Vacunas',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...vacunas.map((vacuna) {
                                      final estaAlDia = vacuna.proximaFecha == null ||
                                          vacuna.proximaFecha!.isAfter(DateTime.now());
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          estaAlDia ? Icons.check_circle : Icons.warning,
                                          color: estaAlDia ? kStatusConfirmada : kStatusPendiente,
                                        ),
                                        title: Text(vacuna.nombre, style: const TextStyle(fontSize: 14)),
                                        subtitle: Text(
                                          'Aplicada: ${vacuna.fecha.day}/${vacuna.fecha.month}/${vacuna.fecha.year}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: vacuna.proximaFecha != null
                                            ? Text(
                                                'Próx: ${vacuna.proximaFecha!.day}/${vacuna.proximaFecha!.month}/${vacuna.proximaFecha!.year}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: estaAlDia ? kTextSecondary : kError,
                                                ),
                                              )
                                            : null,
                                      );
                                    }),
                                    const Divider(height: 32),
                                  ],
                                );
                              },
                            ),
                            // QR
                            QrCarnet(url: carnetUrl, size: 160),
                            const SizedBox(height: 8),
                            Text(
                              carnetUrl,
                              style: const TextStyle(fontSize: 11, color: kTextSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Contacto
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contacto',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.person, color: kPrimary),
                              title: Text(mascota.propietario.nombre),
                            ),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.phone, color: kPrimary),
                              title: Text(mascota.propietario.telefono),
                              onTap: () => _llamarTelefono(mascota.propietario.telefono),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botón reservar cita
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/reserva'),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Reservar cita'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: kPrimary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: kPrimaryLight.withAlpha(51),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
