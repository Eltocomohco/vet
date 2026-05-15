import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../utils/constantes.dart';

class TarjetaCita extends StatelessWidget {
  final Cita cita;
  final VoidCallback? onTap;

  const TarjetaCita({
    super.key,
    required this.cita,
    this.onTap,
  });

  String _obtenerLabelEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'cancelada':
        return 'Cancelada';
      case 'completada':
        return 'Completada';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horaStr =
        '${cita.fechaHora.hour.toString().padLeft(2, '0')}:${cita.fechaHora.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Hora
              Text(
                horaStr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 16),
              // Info cita
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.mascotaNombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cita.motivo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cita.propietarioNombre,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Chip estado
              Chip(
                label: Text(
                  _obtenerLabelEstado(cita.estado),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: cita.getColorPorEstado(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
