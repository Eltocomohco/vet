import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clinica_provider.dart';
import '../providers/mascotas_provider.dart';
import '../providers/calendario_provider.dart';
import '../services/biometric_service.dart';
import '../utils/constantes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _cargando = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _mostrarDialogoResetPassword() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu correo' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                await authProvider.resetPassword(emailController.text.trim());
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Correo de restablecimiento enviado'), backgroundColor: kPrimary),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: kError),
                  );
                }
              }
            },
            child: const Text('Enviar', style: TextStyle(color: kPrimary)),
          ),
        ],
      ),
    );
    emailController.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await BiometricService.canCheckBiometrics();
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
    // Si hay biometría activada, intentar desbloqueo automático
    if (enabled && available) {
      final success = await BiometricService.authenticate(
        reason: 'Desbloquea VetClick',
      );
      if (success && mounted) {
        // La sesión de Firebase debería estar persistida, ir al dashboard
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.estaAutenticado) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Preguntar si quiere activar biometría (solo si el dispositivo la soporta y no está ya activada)
        if (_biometricAvailable && !await BiometricService.isBiometricEnabled()) {
          await _mostrarDialogoActivarBiometria(authProvider.usuario?.id ?? '');
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas'),
            backgroundColor: kError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: kError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _desbloquearConBiometria() async {
    final success = await BiometricService.authenticate(
      reason: 'Desbloquea VetClick para continuar',
    );
    if (success && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.estaAutenticado) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Si no hay sesión activa, intentar login silencioso no es posible sin credenciales
        // Firebase Auth persiste la sesión normalmente, así que esto es un fallback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Inicia sesión con tu correo y contraseña.'),
            backgroundColor: kError,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoActivarBiometria(String userId) async {
    final label = await BiometricService.getBiometricLabel();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbloqueo rápido'),
        content: Text(
          '¿Quieres activar el desbloqueo con $label para la próxima vez? Será más rápido y seguro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await BiometricService.setBiometricEnabled(userId, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desbloqueo biométrico activado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryDark, kPrimary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Icon(Icons.pets, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'VetClick',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Tu clínica a un click',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Ingresa tu correo'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (v) =>
                                      v == null || v.isEmpty
                                          ? 'Ingresa tu contraseña'
                                          : null,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _cargando ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: _cargando
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_biometricAvailable && _biometricEnabled)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _cargando ? null : _desbloquearConBiometria,
                                      icon: const Icon(Icons.fingerprint, size: 28),
                                      label: const Text('Desbloquear con huella'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kPrimary,
                                        side: const BorderSide(color: kPrimary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_biometricAvailable && _biometricEnabled)
                                  const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/registro');
                                  },
                                  child: const Text(
                                    '¿No tienes cuenta? Regístrate',
                                    style: TextStyle(color: kPrimary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _mostrarDialogoResetPassword(),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _cargando ? null : _entrarModoDemo,
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: const Text('Probar modo demo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _entrarModoDemo() async {
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.entrarModoDemo();

    Provider.of<ClinicaProvider>(context, listen: false).cargarClinicaDemo();
    Provider.of<MascotasProvider>(context, listen: false).cargarMascotasDemo();
    Provider.of<CalendarioProvider>(context, listen: false).cargarCitasDemo();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}
