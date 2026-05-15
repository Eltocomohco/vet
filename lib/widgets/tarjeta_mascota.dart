import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../utils/constantes.dart';

class TarjetaMascota extends StatelessWidget {
  final Mascota mascota;
  final VoidCallback? onTap;

  const TarjetaMascota({
    super.key,
    required this.mascota,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: kPrimaryLight.withAlpha(77),
          backgroundImage: mascota.fotoUrl != null && mascota.fotoUrl!.isNotEmpty
              ? NetworkImage(mascota.fotoUrl!)
              : null,
          child: mascota.fotoUrl == null || mascota.fotoUrl!.isEmpty
              ? const Icon(Icons.pets, color: kPrimary, size: 28)
              : null,
        ),
        title: Text(
          mascota.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${mascota.raza} · ${mascota.especie}',
              style: const TextStyle(fontSize: 13, color: kTextSecondary),
            ),
            const SizedBox(height: 1),
            Text(
              '${mascota.propietario.nombre} · ${mascota.propietario.telefono}',
              style: const TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            mascota.especie,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          backgroundColor: kPrimaryLight.withAlpha(77),
          labelStyle: const TextStyle(color: kPrimaryDark),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onTap: onTap,
      ),
    );
  }
}
