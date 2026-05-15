import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../utils/constantes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Esperar a que AuthProvider termine de inicializar
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (authProvider.estaAutenticado) {
      // Si hay sesión, verificar si biometría está activada
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      if (biometricEnabled && mounted) {
        setState(() => _checkingBiometric = true);
        final success = await BiometricService.authenticate(
          reason: 'Desbloquea VetClick para continuar',
        );
        if (!mounted) return;
        if (success) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          // Si falla biometría, ir a login
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      // No hay sesión, verificar si hay biometría configurada para login rápido
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      if (biometricEnabled && mounted) {
        setState(() => _checkingBiometric = true);
        final success = await BiometricService.authenticate(
          reason: 'Desbloquea VetClick',
        );
        if (!mounted) return;
        if (success) {
          // Biometría validada, pero no hay sesión Firebase activa
          // Necesitamos ir a login para que Firebase Auth recupere la sesión persistente
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'VetClick',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            if (_checkingBiometric)
              const Icon(Icons.fingerprint, size: 48, color: Colors.white70)
            else
              const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
