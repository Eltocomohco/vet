import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/clinica_service.dart';
import '../models/clinica.dart';
import '../utils/constantes.dart';

class RegistroClinicaScreen extends StatefulWidget {
  const RegistroClinicaScreen({super.key});

  @override
  State<RegistroClinicaScreen> createState() => _RegistroClinicaScreenState();
}

class _RegistroClinicaScreenState extends State<RegistroClinicaScreen> {
  int _currentStep = 0;
  bool _cargando = false;

  // Paso 1: Clínica
  final _nombreClinicaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailClinicaController = TextEditingController();

  // Paso 2: Admin
  final _nombreAdminController = TextEditingController();
  final _emailAdminController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Paso 3: Horario
  final List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];
  final List<bool> _abierto = List.generate(7, (_) => true);
  final List<TextEditingController> _mananaInicio = List.generate(
    7,
    (_) => TextEditingController(text: '09:00'),
  );
  final List<TextEditingController> _mananaFin = List.generate(
    7,
    (_) => TextEditingController(text: '14:00'),
  );
  final List<TextEditingController> _tardeInicio = List.generate(
    7,
    (_) => TextEditingController(text: '17:00'),
  );
  final List<TextEditingController> _tardeFin = List.generate(
    7,
    (_) => TextEditingController(text: '20:00'),
  );

  final _formPaso1 = GlobalKey<FormState>();
  final _formPaso2 = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreClinicaController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailClinicaController.dispose();
    _nombreAdminController.dispose();
    _emailAdminController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _mananaInicio) { c.dispose(); }
    for (var c in _mananaFin) { c.dispose(); }
    for (var c in _tardeInicio) { c.dispose(); }
    for (var c in _tardeFin) { c.dispose(); }
    super.dispose();
  }

  Future<void> _completarRegistro() async {
    setState(() => _cargando = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Crear auth
      final authService = AuthService();
      final UserCredential userCredential = await authService.registerWithEmail(
        _emailAdminController.text.trim(),
        _passwordController.text,
        _nombreAdminController.text.trim(),
      );

      if (userCredential.user == null) {
        throw Exception('Error al crear el usuario');
      }

      // 2. Crear clínica
      final horario = <String, dynamic>{};
      for (int i = 0; i < 7; i++) {
        horario[_dias[i].toLowerCase()] = {
          'abierto': _abierto[i],
          'manana': {
            'inicio': _mananaInicio[i].text,
            'fin': _mananaFin[i].text,
          },
          'tarde': {
            'inicio': _tardeInicio[i].text,
            'fin': _tardeFin[i].text,
          },
        };
      }

      final clinica = Clinica(
        id: '',
        nombre: _nombreClinicaController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailClinicaController.text.trim(),
        horario: horario,
        veterinarios: [],
        plan: 'basico',
        activa: true,
        configuracionWhatsApp: {},
        creada: DateTime.now(),
      );

      final clinicaService = ClinicaService();
      final String clinicaId = await clinicaService.crearClinica(clinica);

      // 3. Crear usuario en Firestore
      await authProvider.crearUsuarioEnFirestore(
        userId: userCredential.user!.uid,
        nombre: _nombreAdminController.text.trim(),
        email: _emailAdminController.text.trim(),
        clinicaId: clinicaId,
        rol: 'admin',
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _buildPaso1() {
    return Form(
      key: _formPaso1,
      child: Column(
        children: [
          TextFormField(
            controller: _nombreClinicaController,
            decoration: _inputDecoration('Nombre de la clínica *', Icons.business),
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccionController,
            decoration: _inputDecoration('Dirección *', Icons.location_on),
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoController,
            decoration: _inputDecoration('Teléfono *', Icons.phone),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailClinicaController,
            decoration: _inputDecoration('Email de la clínica', Icons.email),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2() {
    return Form(
      key: _formPaso2,
      child: Column(
        children: [
          TextFormField(
            controller: _nombreAdminController,
            decoration: _inputDecoration('Nombre del administrador *', Icons.person),
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailAdminController,
            decoration: _inputDecoration('Email *', Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: _inputDecoration('Contraseña *', Icons.lock),
            obscureText: true,
            validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _inputDecoration('Confirmar contraseña *', Icons.lock_outline),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (v != _passwordController.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaso3() {
    return Column(
      children: [
        for (int i = 0; i < 7; i++) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _abierto[i],
                        onChanged: (v) => setState(() => _abierto[i] = v ?? false),
                        activeColor: kPrimary,
                      ),
                      Text(
                        _dias[i],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        _abierto[i] ? 'Abierto' : 'Cerrado',
                        style: TextStyle(
                          color: _abierto[i] ? kPrimary : kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (_abierto[i]) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Mañana:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _mananaInicio[i],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('-'),
                        ),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _mananaFin[i],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Tarde:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _tardeInicio[i],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('-'),
                        ),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _tardeFin[i],
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _cargando ? null : _completarRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Text('Completar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
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
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'VetClick',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Registro de Clínica',
                        style: TextStyle(fontSize: 14, color: kTextSecondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A Coruña',
                        style: TextStyle(fontSize: 12, color: kPrimary),
                      ),
                      const SizedBox(height: 16),
                      Stepper(
                        currentStep: _currentStep,
                        onStepTapped: (step) => setState(() => _currentStep = step),
                        onStepContinue: () {
                          if (_currentStep == 0) {
                            if (_formPaso1.currentState!.validate()) {
                              setState(() => _currentStep = 1);
                            }
                          } else if (_currentStep == 1) {
                            if (_formPaso2.currentState!.validate()) {
                              setState(() => _currentStep = 2);
                            }
                          }
                        },
                        onStepCancel: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          }
                        },
                        controlsBuilder: (context, details) {
                          if (_currentStep == 2) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                ElevatedButton(
                                  onPressed: details.onStepContinue,
                                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                                  child: const Text('Continuar'),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Atrás'),
                                ),
                              ],
                            ),
                          );
                        },
                        steps: [
                          Step(
                            title: const Text('Clínica'),
                            content: _buildPaso1(),
                            isActive: _currentStep >= 0,
                          ),
                          Step(
                            title: const Text('Administrador'),
                            content: _buildPaso2(),
                            isActive: _currentStep >= 1,
                          ),
                          Step(
                            title: const Text('Horario'),
                            content: _buildPaso3(),
                            isActive: _currentStep >= 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: kPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
