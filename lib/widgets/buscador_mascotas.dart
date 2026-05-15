import 'package:flutter/material.dart';

class BuscadorMascotas extends StatelessWidget {
  final Function(String) onSearch;
  final String hintText;

  const BuscadorMascotas({
    super.key,
    required this.onSearch,
    this.hintText = 'Buscar mascota por nombre, raza o dueño...',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: onSearch,
      ),
    );
  }
}
