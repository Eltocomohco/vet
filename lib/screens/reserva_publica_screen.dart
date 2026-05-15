import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/cita.dart';
import '../models/mascota.dart';
import '../services/cita_service.dart';
import '../services/mascota_service.dart';
import '../utils/constantes.dart';

/// Pantalla pública para reservar citas online sin necesidad de login.
class ReservaPublicaScreen extends StatefulWidget {
  const ReservaPublicaScreen({super.key});

  @override
  State<ReservaPublicaScreen> createState() => _ReservaPublicaScreenState();
}

class _ReservaPublicaScreenState extends State<ReservaPublicaScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // --- Paso 1: Clínica ---
  List<Map<String, dynamic>> _clinicas = [];
  String? _clinicaId;
  String? _clinicaNombre;
  bool _cargandoClinicas = true;
  String? _errorClinicas;

  // --- Paso 2: Fecha y hora ---
  DateTime _mesSeleccionado = DateTime.now();
  DateTime? _diaSeleccionado;
  TimeOfDay? _horaSeleccionada;
  List<Cita> _citasDelDia = [];
  bool _cargandoCitas = false;

  // --- Paso 3: Datos ---
  final _formKey = GlobalKey<FormState>();
  final _nombreMascotaCtrl = TextEditingController();
  final _nombreDuenoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  String _especie = 'Perro';
  String _motivo = 'consultaGeneral';

  final DateFormat _fechaFmt = DateFormat('EEEE, d MMMM', 'es');
  final DateFormat _horaFmt = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _cargarClinicas();
  }

  @override
  void dispose() {
    _nombreMascotaCtrl.dispose();
    _nombreDuenoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClinicas() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('clinicas')
          .where('activa', isEqualTo: true)
          .orderBy('nombre')
          .get();
      final clinics = snap.docs.map((d) => {
        'id': d.id,
        'nombre': (d.data()['nombre'] ?? 'Clínica sin nombre') as String,
      }).toList();
      if (mounted) {
        setState(() {
          _clinicas = clinics;
          _cargandoClinicas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorClinicas =
              'No se pudieron cargar las clínicas. Es posible que necesites iniciar sesión o que las reglas de seguridad no permitan acceso público.';
          _cargandoClinicas = false;
        });
      }
    }
  }

  Future<void> _cargarCitasDelDia(DateTime dia) async {
    if (_clinicaId == null) return;
    setState(() => _cargandoCitas = true);
    try {
      final citas = await CitaService()
          .getCitasStream(_clinicaId!, fecha: dia)
          .first;
      if (mounted) {
        setState(() {
          _citasDelDia = citas;
          _cargandoCitas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _citasDelDia = [];
          _cargandoCitas = false;
        });
      }
    }
  }

  List<TimeOfDay> _generarSlots() {
    final List<TimeOfDay> slots = [];
    for (int h = 9; h < 19; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 30));
    }
    return slots;
  }

  bool _slotOcupado(TimeOfDay slot) {
    if (_diaSeleccionado == null) return false;
    final inicio = DateTime(
      _diaSeleccionado!.year,
      _diaSeleccionado!.month,
      _diaSeleccionado!.day,
      slot.hour,
      slot.minute,
    );
    final fin = inicio.add(const Duration(minutes: 30));
    for (final cita in _citasDelDia) {
      if (cita.estado == 'cancelada' || cita.estado == 'noShow') continue;
      final citaInicio = cita.fechaHora;
      final citaFin = cita.horaFin;
      if (inicio.isBefore(citaFin) && fin.isAfter(citaInicio)) {
        return true;
      }
    }
    return false;
  }

  bool _slotPasado(TimeOfDay slot) {
    if (_diaSeleccionado == null) return false;
    final ahora = DateTime.now();
    final slotDt = DateTime(
      _diaSeleccionado!.year,
      _diaSeleccionado!.month,
      _diaSeleccionado!.day,
      slot.hour,
      slot.minute,
    );
    return slotDt.isBefore(ahora);
  }

  Future<void> _confirmarReserva() async {
    if (_clinicaId == null || _diaSeleccionado == null || _horaSeleccionada == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Crear mascota temporal
      final mascota = Mascota(
        id: '',
        clinicaId: _clinicaId!,
        nombre: _nombreMascotaCtrl.text.trim(),
        especie: _especie,
        raza: 'Desconocida',
        propietario: Propietario(
          nombre: _nombreDuenoCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
        ),
        sexo: 'Desconocido',
        creada: DateTime.now(),
      );
      final mascotaId = await MascotaService().crearMascota(mascota);
      await FirebaseFirestore.instance.collection('mascotas').doc(mascotaId).update({'esReservaPublica': true});

      // 2. Crear cita
      final fechaHora = DateTime(
        _diaSeleccionado!.year,
        _diaSeleccionado!.month,
        _diaSeleccionado!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );

      final cita = Cita(
        id: '',
        clinicaId: _clinicaId!,
        mascotaId: mascotaId,
        mascotaNombre: _nombreMascotaCtrl.text.trim(),
        propietarioNombre: _nombreDuenoCtrl.text.trim(),
        propietarioTelefono: _telefonoCtrl.text.trim(),
        fechaHora: fechaHora,
        motivo: _motivo,
        estado: 'pendiente',
        duracionMinutos: 30,
      );
      final citaId = await CitaService().crearCita(cita);
      await FirebaseFirestore.instance.collection('citas').doc(citaId).update({'esReservaPublica': true});

      if (mounted) {
        setState(() => _isSubmitting = false);
        _mostrarDialogoExito(citaId, fechaHora);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reservar: $e')),
        );
      }
    }
  }

  void _mostrarDialogoExito(String citaId, DateTime fechaHora) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: colorExito, size: 64),
            const SizedBox(height: 16),
            const Text(
              '¡Reserva confirmada!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu cita ha sido registrada en $_clinicaNombre.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: colorTextoSecundario),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorExitoClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _filaResumen(Icons.calendar_today, 'Fecha',
                      DateFormat('EEEE, d MMMM yyyy', 'es').format(fechaHora)),
                  const SizedBox(height: 8),
                  _filaResumen(Icons.access_time, 'Hora',
                      DateFormat('HH:mm').format(fechaHora)),
                  const SizedBox(height: 8),
                  _filaResumen(Icons.pets, 'Mascota', _nombreMascotaCtrl.text.trim()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ref: $citaId',
              style: const TextStyle(fontSize: 11, color: colorTextoHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed('/reserva');
            },
            child: const Text('Nueva reserva'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
            },
            child: const Text('Ir al inicio'),
          ),
        ],
      ),
    );
  }

  Widget _filaResumen(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorPrimario),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _clinicaId != null;
      case 1:
        return _diaSeleccionado != null && _horaSeleccionada != null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _onStepContinue() {
    if (_currentStep == 2) {
      _confirmarReserva();
      return;
    }
    if (_canContinue && _currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar cita'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: _isSubmitting ? null : _onStepContinue,
          onStepCancel: _isSubmitting ? null : _onStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Atrás'),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_canContinue && !_isSubmitting) ? details.onStepContinue : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_currentStep == 2 ? 'Confirmar reserva' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Clínica'),
              isActive: _currentStep >= 0,
              state: _clinicaId != null ? StepState.complete : StepState.indexed,
              content: _buildPasoClinica(),
            ),
            Step(
              title: const Text('Fecha'),
              isActive: _currentStep >= 1,
              state: _diaSeleccionado != null && _horaSeleccionada != null
                  ? StepState.complete
                  : StepState.indexed,
              content: _buildPasoFechaHora(),
            ),
            Step(
              title: const Text('Datos'),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: _buildPasoDatos(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PASO 1: CLÍNICA ====================
  Widget _buildPasoClinica() {
    if (_cargandoClinicas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorClinicas != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: colorError, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorClinicas!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: colorTextoSecundario),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _cargarClinicas,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (_clinicas.isEmpty) {
      return const Text('No hay clínicas disponibles en este momento.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona la clínica veterinaria donde deseas atender a tu mascota:',
          style: TextStyle(color: colorTextoSecundario),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _clinicaId,
          decoration: const InputDecoration(
            labelText: 'Clínica',
            prefixIcon: Icon(Icons.local_hospital),
          ),
          items: _clinicas.map((c) {
            return DropdownMenuItem<String>(
              value: c['id'] as String,
              child: Text(c['nombre'] as String),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _clinicaId = val;
              _clinicaNombre = _clinicas.firstWhere((c) => c['id'] == val)['nombre'] as String?;
            });
          },
          validator: (v) => v == null ? 'Selecciona una clínica' : null,
        ),
      ],
    );
  }

  // ==================== PASO 2: FECHA Y HORA ====================
  Widget _buildPasoFechaHora() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navegador de mes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _mesSeleccionado = DateTime(
                    _mesSeleccionado.year,
                    _mesSeleccionado.month - 1,
                  );
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM yyyy', 'es').format(_mesSeleccionado).toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _mesSeleccionado = DateTime(
                    _mesSeleccionado.year,
                    _mesSeleccionado.month + 1,
                  );
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Calendario
        _buildCalendarioMensual(),
        const SizedBox(height: 16),
        // Slots de hora
        if (_diaSeleccionado != null) ...[
          Text(
            'Horarios disponibles para ${_fechaFmt.format(_diaSeleccionado!)}:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_cargandoCitas)
            const Center(child: CircularProgressIndicator())
          else
            _buildSlotsHorario(),
        ],
      ],
    );
  }

  Widget _buildCalendarioMensual() {
    final primerDiaMes = DateTime(_mesSeleccionado.year, _mesSeleccionado.month, 1);
    final diasEnMes = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0).day;
    final primerWeekday = primerDiaMes.weekday % 7; // 0 = domingo

    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    return Column(
      children: [
        // Cabecera días
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('D', style: TextStyle(fontWeight: FontWeight.bold, color: colorTextoHint)),
            Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('X', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('J', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('V', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.1,
          children: List.generate(primerWeekday + diasEnMes, (index) {
            if (index < primerWeekday) return const SizedBox.shrink();
            final dia = index - primerWeekday + 1;
            final fecha = DateTime(_mesSeleccionado.year, _mesSeleccionado.month, dia);
            final esPasado = fecha.isBefore(hoySinHora);
            final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
            final seleccionado = _diaSeleccionado != null &&
                fecha.year == _diaSeleccionado!.year &&
                fecha.month == _diaSeleccionado!.month &&
                fecha.day == _diaSeleccionado!.day;

            return Center(
              child: InkWell(
                onTap: esPasado
                    ? null
                    : () {
                        setState(() {
                          _diaSeleccionado = fecha;
                          _horaSeleccionada = null;
                        });
                        _cargarCitasDelDia(fecha);
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? colorPrimario
                        : esHoy
                            ? colorPrimarioClaro.withAlpha(51)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dia',
                    style: TextStyle(
                      color: esPasado
                          ? colorTextoHint
                          : seleccionado
                              ? Colors.white
                              : colorTextoPrimario,
                      fontWeight: esHoy || seleccionado ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSlotsHorario() {
    final slots = _generarSlots();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final ocupado = _slotOcupado(slot);
        final pasado = _slotPasado(slot);
        final seleccionado = _horaSeleccionada == slot;
        final deshabilitado = ocupado || pasado;

        return ChoiceChip(
          label: Text(_horaFmt.format(DateTime(2024, 1, 1, slot.hour, slot.minute))),
          selected: seleccionado,
          onSelected: deshabilitado
              ? null
              : (selected) {
                  setState(() {
                    _horaSeleccionada = selected ? slot : null;
                  });
                },
          selectedColor: colorPrimario,
          disabledColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: deshabilitado
                ? Colors.grey
                : seleccionado
                    ? Colors.white
                    : colorTextoPrimario,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }

  // ==================== PASO 3: DATOS ====================
  Widget _buildPasoDatos() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nombreMascotaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la mascota',
              prefixIcon: Icon(Icons.pets),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _especie,
            decoration: const InputDecoration(
              labelText: 'Especie',
              prefixIcon: Icon(Icons.category),
            ),
            items: listaEspecies.map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
            onChanged: (v) => setState(() => _especie = v ?? 'Perro'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreDuenoCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del dueño',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa un teléfono';
              if (v.trim().length < 7) return 'Teléfono demasiado corto';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _motivo,
            decoration: const InputDecoration(
              labelText: 'Motivo de la consulta',
              prefixIcon: Icon(Icons.medical_services),
            ),
            items: const [
              DropdownMenuItem(value: 'consultaGeneral', child: Text('Consulta General')),
              DropdownMenuItem(value: 'vacunacion', child: Text('Vacunación')),
              DropdownMenuItem(value: 'desparasitacion', child: Text('Desparasitación')),
              DropdownMenuItem(value: 'cirugia', child: Text('Cirugía')),
              DropdownMenuItem(value: 'urgencia', child: Text('Urgencia')),
              DropdownMenuItem(value: 'revision', child: Text('Revisión')),
              DropdownMenuItem(value: 'peluqueria', child: Text('Peluquería')),
              DropdownMenuItem(value: 'analisis', child: Text('Análisis')),
              DropdownMenuItem(value: 'otros', child: Text('Otros')),
            ],
            onChanged: (v) => setState(() => _motivo = v ?? 'consultaGeneral'),
          ),
          const SizedBox(height: 16),
          if (_clinicaNombre != null && _diaSeleccionado != null && _horaSeleccionada != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorFondoOscuro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumen de tu reserva:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _filaResumen(Icons.local_hospital, 'Clínica', _clinicaNombre!),
                  _filaResumen(
                    Icons.calendar_today,
                    'Fecha',
                    _fechaFmt.format(_diaSeleccionado!),
                  ),
                  _filaResumen(
                    Icons.access_time,
                    'Hora',
                    _horaFmt.format(DateTime(
                      2024,
                      1,
                      1,
                      _horaSeleccionada!.hour,
                      _horaSeleccionada!.minute,
                    )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
