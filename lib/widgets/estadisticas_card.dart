import 'package:flutter/material.dart';
import '../utils/constantes.dart';

class EstadisticasCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  const EstadisticasCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
