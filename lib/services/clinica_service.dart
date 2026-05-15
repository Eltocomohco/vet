import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/models/clinica.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Servicio que gestiona las operaciones CRUD de clínicas veterinarias
class ClinicaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene una referencia a la colección de clínicas
  CollectionReference get _clinicasCollection =>
      _firestore.collection(coleccionClinicas);

  /// Obtiene una clínica por su ID
  /// Retorna null si no existe
  Future<Clinica?> getClinica(String clinicaId) async {
    try {
      final DocumentSnapshot doc =
          await _clinicasCollection.doc(clinicaId).get();
      if (doc.exists) {
        return Clinica.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la clínica: $e');
    }
  }

  /// Crea una nueva clínica y retorna su ID
  Future<String> crearClinica(Clinica clinica) async {
    try {
      final DocumentReference docRef = await _clinicasCollection.add(
        clinica.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear la clínica: $e');
    }
  }

  /// Actualiza los datos de una clínica existente
  Future<void> actualizarClinica(Clinica clinica) async {
    try {
      await _clinicasCollection
          .doc(clinica.id)
          .update(clinica.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar la clínica: $e');
    }
  }

  /// Realiza un soft delete de la clínica (marca como inactiva)
  /// No elimina físicamente los datos
  Future<void> eliminarClinica(String clinicaId) async {
    try {
      await _clinicasCollection.doc(clinicaId).update({
        'activa': false,
        'eliminada': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al eliminar la clínica: $e');
    }
  }

  /// Reactiva una clínica eliminada
  Future<void> reactivarClinica(String clinicaId) async {
    try {
      await _clinicasCollection.doc(clinicaId).update({
        'activa': true,
      });
    } catch (e) {
      throw Exception('Error al reactivar la clínica: $e');
    }
  }

  /// Obtiene todas las clínicas activas como stream
  Stream<List<Clinica>> getClinicasStream() {
    return _clinicasCollection
        .where('activa', isEqualTo: true)
        .orderBy('nombre')
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs
          .map((DocumentSnapshot doc) => Clinica.fromFirestore(doc))
          .toList();
    });
  }

  /// Actualiza la configuración de WhatsApp de una clínica
  Future<void> actualizarConfiguracionWhatsApp(
    String clinicaId,
    Map<String, dynamic> configuracion,
  ) async {
    try {
      await _clinicasCollection.doc(clinicaId).update({
        'configuracionWhatsApp': configuracion,
      });
    } catch (e) {
      throw Exception(
          'Error al actualizar la configuración de WhatsApp: $e');
    }
  }

  /// Añade un veterinario a la lista de veterinarios de la clínica
  Future<void> agregarVeterinario(String clinicaId, String veterinarioId) async {
    try {
      await _clinicasCollection.doc(clinicaId).update({
        'veterinarios': FieldValue.arrayUnion([veterinarioId]),
      });
    } catch (e) {
      throw Exception('Error al agregar veterinario: $e');
    }
  }

  /// Elimina un veterinario de la lista de veterinarios de la clínica
  Future<void> removerVeterinario(
    String clinicaId,
    String veterinarioId,
  ) async {
    try {
      await _clinicasCollection.doc(clinicaId).update({
        'veterinarios': FieldValue.arrayRemove([veterinarioId]),
      });
    } catch (e) {
      throw Exception('Error al remover veterinario: $e');
    }
  }

  /// Actualiza el plan de suscripción de una clínica
  Future<void> actualizarPlan(String clinicaId, String nuevoPlan) async {
    try {
      await _clinicasCollection.doc(clinicaId).update({
        'plan': nuevoPlan,
      });
    } catch (e) {
      throw Exception('Error al actualizar el plan: $e');
    }
  }

  /// Verifica si existe una clínica con el ID proporcionado
  Future<bool> existeClinica(String clinicaId) async {
    try {
      final DocumentSnapshot doc =
          await _clinicasCollection.doc(clinicaId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene una clínica por su ID como stream (para actualizaciones en tiempo real)
  Stream<Clinica?> getClinicaStream(String clinicaId) {
    return _clinicasCollection.doc(clinicaId).snapshots().map(
        (DocumentSnapshot doc) {
      if (doc.exists) {
        return Clinica.fromFirestore(doc);
      }
      return null;
    });
  }
}
