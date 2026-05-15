import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/clinica_provider.dart';
import 'providers/calendario_provider.dart';
import 'providers/mascotas_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ClinicaProvider()),
          ChangeNotifierProvider(create: (_) => CalendarioProvider()),
          ChangeNotifierProvider(create: (_) => MascotasProvider()),
        ],
        child: const VetClickApp(),
      ),
    );
  } catch (e, stack) {
    runApp(ErrorApp(error: e.toString(), stack: stack.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const ErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Error al iniciar VetClick', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Error: $error', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(stack, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
