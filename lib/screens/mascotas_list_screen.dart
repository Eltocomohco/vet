import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mascotas_provider.dart';
import '../widgets/widgets.dart';
import '../utils/constantes.dart';

class MascotasListScreen extends StatefulWidget {
  const MascotasListScreen({super.key});

  @override
  State<MascotasListScreen> createState() => _MascotasListScreenState();
}

class _MascotasListScreenState extends State<MascotasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.clinicaId != null && !authProvider.modoDemo) {
        Provider.of<MascotasProvider>(context, listen: false)
            .init(authProvider.clinicaId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Mascotas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          BuscadorMascotas(
            onSearch: Provider.of<MascotasProvider>(context, listen: false).buscar,
          ),
          Expanded(
            child: Consumer<MascotasProvider>(
              builder: (context, mascotasProvider, child) {
                if (mascotasProvider.cargando && mascotasProvider.mascotasFiltradas.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (mascotasProvider.mascotasFiltradas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 64, color: kTextSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron mascotas',
                          style: TextStyle(color: kTextSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: mascotasProvider.mascotasFiltradas.length,
                  itemBuilder: (context, index) {
                    final mascota = mascotasProvider.mascotasFiltradas[index];
                    return TarjetaMascota(
                      mascota: mascota,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/mascota',
                          arguments: {'mascotaId': mascota.id},
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/mascota'),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
