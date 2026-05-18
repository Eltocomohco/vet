import 'package:flutter/material.dart';
import 'screens/screens.dart';
import 'screens/import_export_screen.dart';
import 'screens/logs_screen.dart';
import 'utils/constantes.dart';

class VetClickApp extends StatelessWidget {
  const VetClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetClick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          secondary: kAccent,
        ),
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: kSurface,
        ),
        // Transiciones por defecto de Flutter (compatibles con todas las versiones)
      ),
      initialRoute: '/login',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => const RegistroClinicaScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/calendario': (_) => const CalendarioScreen(),
        '/mascotas': (_) => const MascotasListScreen(),
        '/mascota': (_) => const MascotaDetailScreen(),
        '/configuracion': (_) => const ConfiguracionScreen(),
        '/carnet': (_) => const CarnetPublicoScreen(),
        '/importar-exportar': (_) => const ImportExportScreen(),
        '/reserva': (_) => const ReservaPublicaScreen(),
        '/logs': (_) => const LogsScreen(),
      },
    );
  }
}
