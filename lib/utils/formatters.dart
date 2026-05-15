import 'package:intl/intl.dart';

/// Formatea una fecha en formato completo: "lunes, 15 de enero de 2024"
String formatearFecha(DateTime fecha) {
  final DateFormat formatter = DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es_ES');
  return formatter.format(fecha);
}

/// Formatea una hora en formato 24h: "14:30"
String formatearHora(DateTime fecha) {
  final DateFormat formatter = DateFormat('HH:mm', 'es_ES');
  return formatter.format(fecha);
}

/// Formatea una fecha en formato corto: "15/01/2024"
String formatearFechaCorta(DateTime fecha) {
  final DateFormat formatter = DateFormat('dd/MM/yyyy', 'es_ES');
  return formatter.format(fecha);
}

/// Formatea un número de teléfono a formato legible
/// Ejemplo: "+34612345678" -> "+34 612 345 678"
/// Ejemplo: "912345678" -> "912 345 678"
String formatearTelefono(String telefono) {
  if (telefono.isEmpty) return telefono;

  final String limpio = telefono.replaceAll(RegExp(r'\s+'), '');

  if (limpio.startsWith('+')) {
    if (limpio.length >= 12) {
      final String prefijo = limpio.substring(0, 3);
      final String parte1 = limpio.substring(3, 6);
      final String parte2 = limpio.substring(6, 9);
      final String parte3 = limpio.substring(9);
      return '$prefijo $parte1 $parte2 $parte3';
    }
    return limpio;
  }

  if (limpio.length == 9) {
    final String parte1 = limpio.substring(0, 3);
    final String parte2 = limpio.substring(3, 6);
    final String parte3 = limpio.substring(6);
    return '$parte1 $parte2 $parte3';
  }

  return limpio;
}

/// Calcula la edad a partir de una fecha de nacimiento
/// Retorna un string como "3 años y 2 meses" o "8 meses"
String calcularEdad(DateTime? fechaNacimiento) {
  if (fechaNacimiento == null) {
    return 'Edad desconocida';
  }

  final DateTime ahora = DateTime.now();
  int years = ahora.year - fechaNacimiento.year;
  int months = ahora.month - fechaNacimiento.month;
  int days = ahora.day - fechaNacimiento.day;

  if (days < 0) {
    months -= 1;
    days += 30;
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years > 0 && months > 0) {
    return '$years ${years == 1 ? 'año' : 'años'} y $months ${months == 1 ? 'mes' : 'meses'}';
  } else if (years > 0) {
    return '$years ${years == 1 ? 'año' : 'años'}';
  } else if (months > 0) {
    return '$months ${months == 1 ? 'mes' : 'meses'}';
  } else if (days > 0) {
    return '$days ${days == 1 ? 'día' : 'días'}';
  } else {
    return 'Recién nacido';
  }
}

/// Calcula la edad en meses (útil para mascotas jóvenes)
int calcularEdadEnMeses(DateTime? fechaNacimiento) {
  if (fechaNacimiento == null) return 0;

  final DateTime ahora = DateTime.now();
  int years = ahora.year - fechaNacimiento.year;
  int months = ahora.month - fechaNacimiento.month;

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  return years * 12 + months;
}

/// Capitaliza la primera letra de un string
/// Ejemplo: "hola mundo" -> "Hola mundo"
String capitalizar(String texto) {
  if (texto.isEmpty) return texto;
  if (texto.length == 1) return texto.toUpperCase();
  return texto[0].toUpperCase() + texto.substring(1);
}

/// Capitaliza cada palabra de un string
/// Ejemplo: "hola mundo" -> "Hola Mundo"
String capitalizarPalabras(String texto) {
  if (texto.isEmpty) return texto;
  return texto
      .split(' ')
      .map((palabra) => palabra.isEmpty ? palabra : capitalizar(palabra))
      .join(' ');
}

/// Formatea un peso en kg
/// Ejemplo: 5.5 -> "5.50 kg"
String formatearPeso(double? peso) {
  if (peso == null) return 'Peso no registrado';
  return '${peso.toStringAsFixed(2)} kg';
}

/// Formatea un monto en euros
/// Ejemplo: 25.5 -> "25,50 €"
String formatearEuros(double monto) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );
  return formatter.format(monto);
}
