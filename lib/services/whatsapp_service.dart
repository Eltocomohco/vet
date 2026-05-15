import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vetmanager/models/cita.dart';

/// Servicio que gestiona el envío de mensajes de WhatsApp
/// Soporta dos métodos: CallMeBot y Twilio
class WhatsAppService {
  /// Envía un mensaje de WhatsApp usando CallMeBot API
  /// Requiere: apiKey del usuario en CallMeBot, número de teléfono y mensaje
  Future<bool> enviarWhatsAppCallMeBot({
    required String apiKey,
    required String telefono,
    required String mensaje,
  }) async {
    try {
      final String telefonoLimpio = _limpiarTelefono(telefono);
      final String mensajeCodificado = Uri.encodeComponent(mensaje);

      final Uri url = Uri.parse(
        'https://api.callmebot.com/whatsapp.php?phone=$telefonoLimpio&text=$mensajeCodificado&apikey=$apiKey',
      );

      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final String body = response.body.toLowerCase();
        return body.contains('success') ||
            body.contains('mensaje enviado') ||
            body.contains('message queued');
      }

      return false;
    } catch (e) {
      throw Exception('Error al enviar WhatsApp con CallMeBot: $e');
    }
  }

  /// Envía un mensaje de WhatsApp usando Twilio API
  /// Requiere: accountSid, authToken, número de origen de Twilio,
  /// número destino y mensaje
  Future<bool> enviarWhatsAppTwilio({
    required String accountSid,
    required String authToken,
    required String fromNumber,
    required String toNumber,
    required String mensaje,
  }) async {
    try {
      final String telefonoDestino = _formatearTwilio(_limpiarTelefono(toNumber));
      final String telefonoOrigen = _formatearTwilio(fromNumber);

      final Uri url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
      );

      final String credentials =
          base64Encode(utf8.encode('$accountSid:$authToken'));

      final http.Response response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': 'whatsapp:$telefonoOrigen',
          'To': 'whatsapp:$telefonoDestino',
          'Body': mensaje,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al enviar WhatsApp con Twilio: $e');
    }
  }

  /// Envía un recordatorio de forma unificada
  /// Selecciona automáticamente el método según la configuración de la clínica
  Future<bool> enviarRecordatorio({
    required Map<String, dynamic> configuracion,
    required String telefono,
    required String mensaje,
  }) async {
    try {
      final String telefonoLimpio = _limpiarTelefono(telefono);
      final String metodo =
          configuracion['metodo']?.toString().toLowerCase() ?? 'callmebot';

      if (telefonoLimpio.isEmpty) {
        throw Exception('El número de teléfono está vacío');
      }

      if (metodo == 'twilio') {
        final String accountSid = configuracion['accountSid'] ?? '';
        final String authToken = configuracion['authToken'] ?? '';
        final String fromNumber = configuracion['fromNumber'] ?? '';

        if (accountSid.isEmpty || authToken.isEmpty || fromNumber.isEmpty) {
          throw Exception('Faltan credenciales de Twilio');
        }

        return await enviarWhatsAppTwilio(
          accountSid: accountSid,
          authToken: authToken,
          fromNumber: fromNumber,
          toNumber: telefonoLimpio,
          mensaje: mensaje,
        );
      } else {
        final String apiKey = configuracion['apiKey'] ?? '';

        if (apiKey.isEmpty) {
          throw Exception('Falta el API Key de CallMeBot');
        }

        return await enviarWhatsAppCallMeBot(
          apiKey: apiKey,
          telefono: telefonoLimpio,
          mensaje: mensaje,
        );
      }
    } catch (e) {
      throw Exception('Error al enviar recordatorio: $e');
    }
  }

  /// Genera el mensaje de recordatorio para una cita
  String generarMensajeRecordatorioCita(
    Cita cita, {
    String nombreClinica = 'VetClick',
  }) {
    final StringBuffer mensaje = StringBuffer();
    mensaje.writeln('👋 *Recordatorio de Cita*');
    mensaje.writeln();
    mensaje.writeln('¡Hola ${cita.propietarioNombre}!');
    mensaje.writeln();
    mensaje.writeln(
        'Le recordamos que tiene una cita programada para *${cita.mascotaNombre}*:');
    mensaje.writeln();
    mensaje.writeln('📅 *Fecha:* ${cita.fechaHora.day}/${cita.fechaHora.month}/${cita.fechaHora.year}');
    mensaje.writeln('🕐 *Hora:* ${_formatearHora(cita.fechaHora)}');
    mensaje.writeln('📝 *Motivo:* ${cita.motivoDisplay}');
    mensaje.writeln();
    mensaje.writeln('Por favor, confirme su asistencia respondiendo a este mensaje.');
    mensaje.writeln();
    mensaje.writeln('_$nombreClinica');
    mensaje.writeln('Gracias por confiar en nosotros. 🐾');

    return mensaje.toString();
  }

  /// Genera el mensaje de recordatorio para una vacuna próxima
  String generarMensajeRecordatorioVacuna({
    required String nombreMascota,
    required String tipoVacuna,
    required DateTime fechaProxima,
    String nombreClinica = 'VetClick',
  }) {
    final StringBuffer mensaje = StringBuffer();
    mensaje.writeln('💉 *Recordatorio de Vacuna*');
    mensaje.writeln();
    mensaje.writeln('¡Hola!');
    mensaje.writeln();
    mensaje.writeln(
        'Le recordamos que *$nombreMascota* tiene próxima su vacuna de *$tipoVacuna*:');
    mensaje.writeln();
    mensaje.writeln('📅 *Fecha prevista:* ${fechaProxima.day}/${fechaProxima.month}/${fechaProxima.year}');
    mensaje.writeln();
    mensaje.writeln('Póngase en contacto con nosotros para agendar la cita.');
    mensaje.writeln();
    mensaje.writeln('_$nombreClinica');
    mensaje.writeln('Cuidamos de tu mascota. 🐾');

    return mensaje.toString();
  }

  /// Genera un mensaje de bienvenida para nuevo registro
  String generarMensajeBienvenida({
    required String nombrePropietario,
    required String nombreMascota,
    String nombreClinica = 'VetClick',
  }) {
    final StringBuffer mensaje = StringBuffer();
    mensaje.writeln('🐾 *¡Bienvenido a $nombreClinica!*');
    mensaje.writeln();
    mensaje.writeln('Hola $nombrePropietario,');
    mensaje.writeln();
    mensaje.writeln(
        'Le confirmamos que *$nombreMascota* ha sido registrado correctamente en nuestro sistema.');
    mensaje.writeln();
    mensaje.writeln('Puede consultar el historial de su mascota en cualquier momento.');
    mensaje.writeln();
    mensaje.writeln('Gracias por confiar en nosotros.');
    mensaje.writeln('_$nombreClinica');

    return mensaje.toString();
  }

  /// Genera mensaje de confirmación de cita
  String generarMensajeConfirmacionCita(
    Cita cita, {
    String nombreClinica = 'VetClick',
  }) {
    final StringBuffer mensaje = StringBuffer();
    mensaje.writeln('✅ *Cita Confirmada*');
    mensaje.writeln();
    mensaje.writeln('¡Hola ${cita.propietarioNombre}!');
    mensaje.writeln();
    mensaje.writeln('Su cita para *${cita.mascotaNombre}* ha sido confirmada:');
    mensaje.writeln();
    mensaje.writeln('📅 *Fecha:* ${cita.fechaHora.day}/${cita.fechaHora.month}/${cita.fechaHora.year}');
    mensaje.writeln('🕐 *Hora:* ${_formatearHora(cita.fechaHora)}');
    mensaje.writeln('📝 *Motivo:* ${cita.motivoDisplay}');
    mensaje.writeln();
    mensaje.writeln('Le esperamos. No olvide traer la cartilla de vacunación.');
    mensaje.writeln();
    mensaje.writeln('_$nombreClinica');

    return mensaje.toString();
  }

  /// Genera mensaje de cita cancelada
  String generarMensajeCitaCancelada({
    required String nombrePropietario,
    required String nombreMascota,
    required DateTime fechaHora,
    String nombreClinica = 'VetClick',
    String? motivoCancelacion,
  }) {
    final StringBuffer mensaje = StringBuffer();
    mensaje.writeln('❌ *Cita Cancelada*');
    mensaje.writeln();
    mensaje.writeln('Hola $nombrePropietario,');
    mensaje.writeln();
    mensaje.writeln('Lamentamos informarle que la cita de *$nombreMascota* programada para:');
    mensaje.writeln('📅 ${fechaHora.day}/${fechaHora.month}/${fechaHora.year} a las ${_formatearHora(fechaHora)}');
    mensaje.writeln('ha sido cancelada.');
    if (motivoCancelacion != null && motivoCancelacion.isNotEmpty) {
      mensaje.writeln();
      mensaje.writeln('Motivo: $motivoCancelacion');
    }
    mensaje.writeln();
    mensaje.writeln('Póngase en contacto con nosotros para reagendar.');
    mensaje.writeln();
    mensaje.writeln('_$nombreClinica');

    return mensaje.toString();
  }

  /// Limpia el número de teléfono eliminando espacios y añadiendo prefijo si es necesario
  String _limpiarTelefono(String telefono) {
    String limpio = telefono.replaceAll(RegExp(r'\s+'), '');

    if (limpio.startsWith('+')) {
      return limpio;
    }

    if (limpio.startsWith('00')) {
      limpio = '+${limpio.substring(2)}';
    } else if (limpio.startsWith('34')) {
      limpio = '+$limpio';
    } else if (limpio.length == 9) {
      limpio = '+34$limpio';
    }

    return limpio;
  }

  /// Formatea el número de teléfono para Twilio (requiere formato internacional)
  String _formatearTwilio(String telefono) {
    if (telefono.startsWith('+')) {
      return telefono;
    }
    if (telefono.length == 9) {
      return '+34$telefono';
    }
    return telefono;
  }

  /// Formatea una hora en formato HH:mm
  String _formatearHora(DateTime fecha) {
    final String hora = fecha.hour.toString().padLeft(2, '0');
    final String minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  /// Verifica si un número de teléfono es válido para WhatsApp
  bool esTelefonoValido(String telefono) {
    final String limpio = _limpiarTelefono(telefono);
    final RegExp regex = RegExp(r'^\+[0-9]{11,15}$');
    return regex.hasMatch(limpio);
  }
}
