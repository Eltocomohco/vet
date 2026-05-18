import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mascota.dart';
import '../models/cita.dart';
import '../providers/clinica_provider.dart';
import '../services/cita_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/constantes.dart';
import 'selector_hora.dart';

class ModalNuevaCita extends StatefulWidget {
  final String clinicaId;
  final List<Mascota> mascotas;
  final DateTime? fechaInicial;
  final Function(Cita) onSave;

  const ModalNuevaCita({
    super.key,
    required this.clinicaId,
    required this.mascotas,
    this.fechaInicial,
    required this.onSave,
  });

  @override
  State<ModalNuevaCita> createState() => _ModalNuevaCitaState();
}

class _ModalNuevaCitaState extends State<ModalNuevaCita> {
  final _formKey = GlobalKey<FormState>();
  Mascota? _mascotaSeleccionada;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  String? _motivo;
  final _notasController = TextEditingController();
  bool _enviarWhatsApp = true;
  bool _guardando = false;

  final List<String> _motivos = [
    'Vacunación',
    'Revisión',
    'Urgencia',
    'Peluquería',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fechaInicial != null) {
      _fecha = widget.fechaInicial!;
      _hora = TimeOfDay.fromDateTime(widget.fechaInicial!);
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.clinicaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes una clínica asociada. Crea una clínica primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_mascotaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una mascota'),
          backgroundColor: kError,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final fechaHora = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    final cita = Cita(
      id: '',
      clinicaId: widget.clinicaId,
      mascotaId: _mascotaSeleccionada!.id,
      mascotaNombre: _mascotaSeleccionada!.nombre,
      propietarioNombre: _mascotaSeleccionada!.propietario.nombre,
      propietarioTelefono: _mascotaSeleccionada!.propietario.telefono,
      fechaHora: fechaHora,
      motivo: _motivo!,
      estado: 'pendiente',
      notas: _notasController.text.trim(),
    );

    try {
      final tieneConflicto = await CitaService().existeConflictoHorario(
        widget.clinicaId,
        fechaHora,
        30,
      );
      if (tieneConflicto) {
        if (mounted) {
          setState(() => _guardando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya existe una cita en ese horario'), backgroundColor: kError),
          );
        }
        return;
      }

      await widget.onSave(cita);

      if (_enviarWhatsApp && mounted) {
        try {
          final clinicaProvider = Provider.of<ClinicaProvider>(context, listen: false);
          final config = clinicaProvider.configuracionWhatsApp;
          final telefono = cita.propietarioTelefono;
          final mensaje = 'Hola ${cita.propietarioNombre}, le recordamos que tiene cita para ${cita.mascotaNombre} el ${cita.fechaHora.day}/${cita.fechaHora.month}/${cita.fechaHora.year} a las ${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}.';
          await WhatsAppService().enviarRecordatorio(
            configuracion: config,
            telefono: telefono,
            mensaje: mensaje,
          );
        } catch (e) {
          debugPrint('Error enviando WhatsApp: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Nueva Cita',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Mascota
                      DropdownButtonFormField<Mascota>(
                        initialValue: _mascotaSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Mascota *',
                          prefixIcon: const Icon(Icons.pets),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: kSurface,
                        ),
                        hint: const Text('Selecciona una mascota'),
                        items: widget.mascotas.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text('${m.nombre} - ${m.propietario.nombre}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _mascotaSeleccionada = v),
                        validator: (v) => v == null ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      // Fecha
                      InkWell(
                        onTap: _seleccionarFecha,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: kPrimary),
                              const SizedBox(width: 12),
                              Text(
                                '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down,
                                  color: kTextSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Hora
                      SelectorHora(
                        hora: _hora,
                        onChanged: (h) => setState(() => _hora = h),
                      ),
                      const SizedBox(height: 16),
                      // Motivo
                      DropdownButtonFormField<String>(
                        initialValue: _motivo,
                        decoration: InputDecoration(
                          labelText: 'Motivo *',
                          prefixIcon: const Icon(Icons.medical_services),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: kSurface,
                        ),
                        hint: const Text('Selecciona el motivo'),
                        items: _motivos.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (v) => setState(() => _motivo = v),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      // Notas
                      TextFormField(
                        controller: _notasController,
                        decoration: InputDecoration(
                          labelText: 'Notas adicionales',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: kSurface,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // WhatsApp
                      CheckboxListTile(
                        value: _enviarWhatsApp,
                        onChanged: (v) =>
                            setState(() => _enviarWhatsApp = v ?? true),
                        title: const Text('Enviar recordatorio por WhatsApp'),
                        subtitle: const Text(
                          'Se enviará un mensaje al propietario',
                          style: TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                        activeColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _guardando
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Guardar Cita',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
