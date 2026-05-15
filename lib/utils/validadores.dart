/// Valida que un email tenga formato correcto
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarEmail(String? valor) {
  if (valor == null || valor.trim().isEmpty) {
    return 'El email es obligatorio';
  }

  final String email = valor.trim();
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(email)) {
    return 'Ingrese un email válido';
  }

  return null;
}

/// Valida que un número de teléfono tenga formato correcto
/// Acepta formatos: 612345678, +34612345678, 912345678
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarTelefono(String? valor, {bool obligatorio = true}) {
  if (valor == null || valor.trim().isEmpty) {
    if (obligatorio) {
      return 'El teléfono es obligatorio';
    }
    return null;
  }

  final String telefono = valor.trim().replaceAll(RegExp(r'\s+'), '');

  final RegExp telefonoRegex = RegExp(
    r'^(\+34|0034)?[6789]\d{8}$',
  );

  if (!telefonoRegex.hasMatch(telefono)) {
    return 'Ingrese un teléfono válido (9 dígitos)';
  }

  return null;
}

/// Valida que un campo no esté vacío
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarNoVacio(String? valor, {String campo = 'Este campo'}) {
  if (valor == null || valor.trim().isEmpty) {
    return '$campo es obligatorio';
  }

  if (valor.trim().length < 2) {
    return '$campo debe tener al menos 2 caracteres';
  }

  return null;
}

/// Valida que un valor sea un número positivo mayor que cero
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarNumeroPositivo(String? valor, {String campo = 'Este campo'}) {
  if (valor == null || valor.trim().isEmpty) {
    return '$campo es obligatorio';
  }

  final double? numero = double.tryParse(valor.replaceAll(',', '.'));

  if (numero == null) {
    return '$campo debe ser un número válido';
  }

  if (numero <= 0) {
    return '$campo debe ser mayor que cero';
  }

  return null;
}

/// Valida que un DNI/NIE tenga formato correcto español
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarDNI(String? valor) {
  if (valor == null || valor.trim().isEmpty) {
    return null;
  }

  final String dni = valor.trim().toUpperCase();

  final RegExp dniRegex = RegExp(r'^\d{8}[A-Z]$');
  final RegExp nieRegex = RegExp(r'^[XYZ]\d{7}[A-Z]$');

  if (!dniRegex.hasMatch(dni) && !nieRegex.hasMatch(dni)) {
    return 'Formato de DNI/NIE no válido';
  }

  if (dniRegex.hasMatch(dni)) {
    final String numeroStr = dni.substring(0, 8);
    final String letra = dni.substring(8);
    const String letrasDNI = 'TRWAGMYFPDXBNJZSQVHLCKE';
    final int numero = int.parse(numeroStr);
    final int resto = numero % 23;
    if (letrasDNI[resto] != letra) {
      return 'DNI no válido (letra incorrecta)';
    }
  }

  return null;
}

/// Valida que un nombre tenga formato correcto
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarNombre(String? valor, {String campo = 'El nombre'}) {
  if (valor == null || valor.trim().isEmpty) {
    return '$campo es obligatorio';
  }

  if (valor.trim().length < 2) {
    return '$campo debe tener al menos 2 caracteres';
  }

  final RegExp nombreRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\-\'.]+$");
  if (!nombreRegex.hasMatch(valor.trim())) {
    return '$campo solo puede contener letras';
  }

  return null;
}

/// Valida que una fecha de nacimiento sea razonable
/// (no futura, no anterior a 50 años para mascotas)
/// Retorna null si es válida, o un mensaje de error si no lo es
String? validarFechaNacimiento(DateTime? valor) {
  if (valor == null) {
    return null;
  }

  final DateTime ahora = DateTime.now();

  if (valor.isAfter(ahora)) {
    return 'La fecha no puede ser futura';
  }

  final DateTime fechaMinima = DateTime(ahora.year - 50, ahora.month, ahora.day);
  if (valor.isBefore(fechaMinima)) {
    return 'La fecha no es válida (demasiado antigua)';
  }

  return null;
}

/// Valida que un código postal español tenga formato correcto
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarCodigoPostal(String? valor) {
  if (valor == null || valor.trim().isEmpty) {
    return null;
  }

  final RegExp cpRegex = RegExp(r'^\d{5}$');
  if (!cpRegex.hasMatch(valor.trim())) {
    return 'Código postal no válido (5 dígitos)';
  }

  return null;
}

/// Valida que un valor esté dentro de un rango numérico
/// Retorna null si es válido, o un mensaje de error si no lo es
String? validarRango(double? valor, double min, double max,
    {String campo = 'El valor'}) {
  if (valor == null) {
    return '$campo es obligatorio';
  }

  if (valor < min || valor > max) {
    return '$campo debe estar entre $min y $max';
  }

  return null;
}
