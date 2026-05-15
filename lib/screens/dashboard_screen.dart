import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/calendario_provider.dart';
import '../providers/clinica_provider.dart';
import '../providers/mascotas_provider.dart';
import '../services/cita_service.dart';
import '../services/mascota_service.dart';
import '../widgets/widgets.dart';
import '../utils/constantes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final CitaService _citaService = CitaService();
  final MascotaService _mascotaService = MascotaService();

  String? get _clinicaId {
    return Provider.of<AuthProvider>(context, listen: false).clinicaId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.modoDemo) {
      Provider.of<ClinicaProvider>(context, listen: false).cargarClinicaDemo();
      Provider.of<CalendarioProvider>(context, listen: false).cargarCitasDemo();
      Provider.of<MascotasProvider>(context, listen: false).cargarMascotasDemo();
    } else if (authProvider.clinicaId != null) {
      Provider.of<CalendarioProvider>(context, listen: false)
          .init(authProvider.clinicaId!);
      Provider.of<MascotasProvider>(context, listen: false)
          .init(authProvider.clinicaId!);
    }
  }

  void _navegar(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/calendario');
        break;
      case 2:
        Navigator.pushNamed(context, '/mascotas');
        break;
      case 3:
        Navigator.pushNamed(context, '/configuracion');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'VetClick',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'config') {
                Navigator.pushNamed(context, '/configuracion');
              } else if (value == 'logout') {
                final navigator = Navigator.of(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Cerrar sesión', style: TextStyle(color: kError)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await authProvider.logout();
                  if (mounted) {
                    navigator.pushReplacementNamed('/login');
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'config', child: Text('Configuración')),
              const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StreamStatCard(
                            icono: Icons.calendar_today_rounded,
                            titulo: 'Citas Hoy',
                            stream: _citaService.getCitasHoyStream(_clinicaId ?? ''),
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StreamStatCard(
                            icono: Icons.pending_actions_rounded,
                            titulo: 'Pendientes',
                            stream: _citaService.getCitasPendientesStream(_clinicaId ?? ''),
                            color: kStatusPendiente,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StreamStatCard(
                            icono: Icons.check_circle_rounded,
                            titulo: 'Confirmadas',
                            stream: _citaService.getCitasPorEstadoStream(_clinicaId ?? '', 'confirmada'),
                            color: kStatusConfirmada,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StreamStatCard(
                            icono: Icons.cancel_rounded,
                            titulo: 'Canceladas sem.',
                            stream: _citaService.getCitasCanceladasSemanaStream(_clinicaId ?? ''),
                            color: kStatusCancelada,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FutureStatCard(
                            icono: Icons.pets,
                            titulo: 'Mascotas',
                            future: _mascotaService.getTotalMascotas(_clinicaId ?? ''),
                            color: kPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StreamStatCard(
                            icono: Icons.date_range,
                            titulo: 'Citas mes',
                            stream: _citaService.getCitasMesStream(_clinicaId ?? ''),
                            color: kAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Próximas citas
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Próximas Citas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                ),
              ),
              Consumer<CalendarioProvider>(
                builder: (context, calendario, child) {
                  if (calendario.citasDelDia.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 56,
                              color: kTextSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '¡Buen día!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: kTextSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No tienes citas programadas para hoy.',
                              style: TextStyle(
                                fontSize: 14,
                                color: kTextSecondary.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: calendario.citasDelDia.length,
                    itemBuilder: (context, index) {
                      final cita = calendario.citasDelDia[index];
                      return TarjetaCita(
                        cita: cita,
                        onTap: () {
                          // Mostrar detalles
                        },
                      );
                    },
                  );
                },
              ),
            // Acceso rápido
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Acceso Rápido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final mascotasProvider = Provider.of<MascotasProvider>(context, listen: false);
                        final calendarioProvider = Provider.of<CalendarioProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ModalNuevaCita(
                            clinicaId: authProvider.clinicaId ?? '',
                            mascotas: mascotasProvider.mascotas,
                            onSave: (cita) async {
                              await calendarioProvider.crearCita(cita);
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Cita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/mascota'),
                      icon: const Icon(Icons.pets),
                      label: const Text('Nueva Mascota'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/mascotas'),
                      icon: const Icon(Icons.list),
                      label: const Text('Ver Mascotas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _navegar,
        selectedItemColor: kPrimary,
        unselectedItemColor: kTextSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Mascotas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}

// Widget auxiliar para estadísticas con Stream
class _StreamStatCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Stream<List<dynamic>> stream;
  final Color color;

  const _StreamStatCard({
    required this.icono,
    required this.titulo,
    required this.stream,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        final valor = snapshot.hasData ? '${snapshot.data!.length}' : '...';
        return EstadisticasCard(
          icono: icono,
          titulo: titulo,
          valor: valor,
          color: color,
        );
      },
    );
  }
}

// Widget auxiliar para estadísticas con Future
class _FutureStatCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Future<int> future;
  final Color color;

  const _FutureStatCard({
    required this.icono,
    required this.titulo,
    required this.future,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final valor = snapshot.hasData ? '${snapshot.data}' : '...';
        return EstadisticasCard(
          icono: icono,
          titulo: titulo,
          valor: valor,
          color: color,
        );
      },
    );
  }
}
