import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../providers/auth_provider.dart';
import '../providers/calendario_provider.dart';
import '../providers/mascotas_provider.dart';
import '../models/cita.dart';
import '../widgets/widgets.dart';
import '../utils/constantes.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  CalendarView _calendarView = CalendarView.week;
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.clinicaId != null) {
        Provider.of<CalendarioProvider>(context, listen: false)
            .init(authProvider.clinicaId!);
      }
    });
  }

  void _irAHoy() {
    _calendarController.displayDate = DateTime.now();
    _calendarController.selectedDate = DateTime.now();
  }

  void _mostrarDetalleCita(Cita cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cita.mascotaNombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motivo: ${cita.motivo}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text('Dueño: ${cita.propietarioNombre}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text('Teléfono: ${cita.propietarioTelefono}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text('Estado: ${cita.estado}', style: TextStyle(fontSize: 15, color: cita.getColorPorEstado(), fontWeight: FontWeight.w600)),
            if (cita.notas != null && cita.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notas: ${cita.notas}', style: const TextStyle(fontSize: 14, color: kTextSecondary)),
            ],
          ],
        ),
        actions: [
          if (cita.estado != 'completada' && cita.estado != 'cancelada')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final calendario = Provider.of<CalendarioProvider>(context, listen: false);
                await calendario.cambiarEstadoCita(cita.id, 'completada');
              },
              child: const Text('Completar', style: TextStyle(color: kStatusConfirmada)),
            ),
          if (cita.estado != 'cancelada' && cita.estado != 'completada')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final calendario = Provider.of<CalendarioProvider>(context, listen: false);
                await calendario.cambiarEstadoCita(cita.id, 'cancelada');
              },
              child: const Text('Cancelar', style: TextStyle(color: kStatusCancelada)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _abrirNuevaCita(DateTime? fecha) {
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
        fechaInicial: fecha,
        onSave: (cita) async {
          await calendarioProvider.crearCita(cita);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            DropdownButton<CalendarView>(
              value: _calendarView,
              dropdownColor: kPrimary,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              onChanged: (view) {
                if (view != null) {
                  setState(() {
                    _calendarView = view;
                    _calendarController.view = view;
                  });
                }
              },
              items: const [
                DropdownMenuItem(value: CalendarView.day, child: Text('Día', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: CalendarView.week, child: Text('Semana', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: CalendarView.month, child: Text('Mes', style: TextStyle(color: Colors.white))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _irAHoy,
            child: const Text('Hoy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Consumer<CalendarioProvider>(
        builder: (context, calendario, child) {
          if (calendario.cargando && calendario.citas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SfCalendar(
            controller: _calendarController,
            view: _calendarView,
            firstDayOfWeek: 1,
            dataSource: _CitaDataSource(calendario.citas),
            initialDisplayDate: DateTime.now(),
            onTap: (CalendarTapDetails details) {
              if (details.targetElement == CalendarElement.appointment && details.appointments != null && details.appointments!.isNotEmpty) {
                final appointment = details.appointments!.first as Appointment;
                final cita = calendario.citas.firstWhere(
                  (c) => c.id == appointment.id,
                  orElse: () => Cita(
                    id: '',
                    clinicaId: '',
                    mascotaId: '',
                    mascotaNombre: appointment.subject,
                    propietarioNombre: '',
                    propietarioTelefono: '',
                    fechaHora: appointment.startTime,
                    motivo: appointment.notes ?? '',
                    estado: 'pendiente',
                  ),
                );
                _mostrarDetalleCita(cita);
              } else if (details.targetElement == CalendarElement.calendarCell && details.date != null) {
                _abrirNuevaCita(details.date);
              }
            },
            onLongPress: (CalendarLongPressDetails details) {
              if (details.date != null) {
                _abrirNuevaCita(details.date);
              }
            },
            appointmentBuilder: (context, details) {
              final appointment = details.appointments.first;
              return Container(
                decoration: BoxDecoration(
                  color: appointment.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(4),
                child: Text(
                  appointment.subject,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            timeSlotViewSettings: const TimeSlotViewSettings(
              startHour: 8,
              endHour: 21,
              timeIntervalHeight: 50,
            ),
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
              showAgenda: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirNuevaCita(DateTime.now()),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CitaDataSource extends CalendarDataSource {
  _CitaDataSource(List<Cita> citas) {
    appointments = citas.map((cita) {
      return Appointment(
        id: cita.id,
        subject: cita.mascotaNombre,
        startTime: cita.fechaHora,
        endTime: cita.fechaHora.add(const Duration(minutes: 30)),
        color: cita.getColorPorEstado(),
        notes: cita.motivo,
      );
    }).toList();
  }
}
