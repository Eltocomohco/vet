import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Servicio que gestiona el almacenamiento de archivos en Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una foto de mascota desde un archivo (móvil/desktop)
  /// Retorna la URL de descarga de la imagen subida
  Future<String> subirFotoMascota(
    File archivo, {
    String? mascotaId,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('subirFotoMascota(File) no está disponible en web. Usa subirFotoMascotaWeb(bytes).');
    }
    try {
      final String nombreArchivo = _generarNombreArchivo(
        mascotaId: mascotaId,
        extension: path.extension(archivo.path).isNotEmpty
            ? path.extension(archivo.path).replaceFirst('.', '')
            : 'jpg',
      );

      final Reference ref = _storage.ref().child('mascotas/$nombreArchivo');

      final UploadTask uploadTask = ref.putFile(
        archivo,
        SettableMetadata(
          contentType: 'image/${path.extension(archivo.path).replaceFirst('.', '') == 'png' ? 'png' : 'jpeg'}',
          customMetadata: {
            'subido': DateTime.now().toIso8601String(),
            if (mascotaId != null) 'mascotaId': mascotaId,
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Error de Firebase Storage: ${e.message}');
    } catch (e) {
      throw Exception('Error al subir la foto de la mascota: $e');
    }
  }

  /// Sube una foto de mascota desde bytes (web)
  /// Retorna la URL de descarga de la imagen subida
  Future<String> subirFotoMascotaWeb(
    Uint8List bytes, {
    String extension = 'png',
    String? mascotaId,
  }) async {
    try {
      final String nombreArchivo = _generarNombreArchivo(
        mascotaId: mascotaId,
        extension: extension,
      );

      final Reference ref = _storage.ref().child('mascotas/$nombreArchivo');

      final String contentType = extension.toLowerCase() == 'png'
          ? 'image/png'
          : extension.toLowerCase() == 'gif'
              ? 'image/gif'
              : 'image/jpeg';

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'subido': DateTime.now().toIso8601String(),
            if (mascotaId != null) 'mascotaId': mascotaId,
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Error de Firebase Storage: ${e.message}');
    } catch (e) {
      throw Exception('Error al subir la foto de la mascota (web): $e');
    }
  }

  /// Elimina una foto de mascota por su URL
  Future<void> eliminarFoto(String? fotoUrl) async {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return;
    }

    try {
      final Reference ref = _storage.refFromURL(fotoUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      throw Exception('Error al eliminar la foto: ${e.message}');
    } catch (e) {
      throw Exception('Error al eliminar la foto: $e');
    }
  }

  /// Sube un documento PDF (por ejemplo, historial médico)
  Future<String> subirDocumento(
    File archivo, {
    String? mascotaId,
    String tipo = 'documentos',
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('subirDocumento(File) no está disponible en web. Usa subirDocumentoWeb(bytes).');
    }
    try {
      final String extension = path.extension(archivo.path).isNotEmpty
          ? path.extension(archivo.path).replaceFirst('.', '')
          : 'pdf';

      final String nombreArchivo = _generarNombreArchivo(
        mascotaId: mascotaId,
        extension: extension,
        prefijo: tipo,
      );

      final Reference ref = _storage.ref().child('$tipo/$nombreArchivo');

      final UploadTask uploadTask = ref.putFile(
        archivo,
        SettableMetadata(
          contentType: 'application/$extension',
          customMetadata: {
            'subido': DateTime.now().toIso8601String(),
            if (mascotaId != null) 'mascotaId': mascotaId,
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Error de Firebase Storage: ${e.message}');
    } catch (e) {
      throw Exception('Error al subir el documento: $e');
    }
  }

  /// Sube un documento desde bytes (web)
  Future<String> subirDocumentoWeb(
    Uint8List bytes, {
    String extension = 'pdf',
    String? mascotaId,
    String tipo = 'documentos',
  }) async {
    try {
      final String nombreArchivo = _generarNombreArchivo(
        mascotaId: mascotaId,
        extension: extension,
        prefijo: tipo,
      );

      final Reference ref = _storage.ref().child('$tipo/$nombreArchivo');

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'application/$extension',
          customMetadata: {
            'subido': DateTime.now().toIso8601String(),
            if (mascotaId != null) 'mascotaId': mascotaId,
          },
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Error de Firebase Storage: ${e.message}');
    } catch (e) {
      throw Exception('Error al subir el documento (web): $e');
    }
  }

  /// Obtiene la URL de descarga de un archivo por su path
  Future<String> getDownloadUrl(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Error al obtener URL de descarga: ${e.message}');
    } catch (e) {
      throw Exception('Error al obtener URL de descarga: $e');
    }
  }

  /// Lista los archivos de una carpeta
  Future<List<Reference>> listarArchivos(String carpeta) async {
    try {
      final ListResult result = await _storage.ref().child(carpeta).listAll();
      return result.items;
    } catch (e) {
      throw Exception('Error al listar archivos: $e');
    }
  }

  /// Elimina un archivo por su path en Storage
  Future<void> eliminarArchivo(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      throw Exception('Error al eliminar el archivo: ${e.message}');
    } catch (e) {
      throw Exception('Error al eliminar el archivo: $e');
    }
  }

  /// Genera un nombre único para el archivo
  String _generarNombreArchivo({
    String? mascotaId,
    required String extension,
    String prefijo = '',
  }) {
    final String timestamp =
        DateTime.now().millisecondsSinceEpoch.toString();
    final String id = mascotaId ?? 'general';
    final String prefijoStr = prefijo.isNotEmpty ? '${prefijo}_' : '';
    return '$prefijoStr${id}_$timestamp.$extension';
  }

  /// Obtiene los metadatos de un archivo
  Future<FullMetadata> getMetadata(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Error al obtener metadatos: $e');
    }
  }
}
