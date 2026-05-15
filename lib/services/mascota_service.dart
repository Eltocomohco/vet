import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/models/mascota.dart';
import 'package:vetmanager/utils/constantes.dart';

/// Servicio que gestiona las operaciones CRUD de mascotas
class MascotaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene una referencia a la colección de mascotas
  CollectionReference get _mascotasCollection =>
      _firestore.collection(coleccionMascotas);

  /// Obtiene un stream de mascotas de una clínica (actualizaciones en tiempo real)
  Stream<List<Mascota>> getMascotasStream(String clinicaId) {
    return _mascotasCollection
        .where('clinicaId', isEqualTo: clinicaId)
        .orderBy('nombre')
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs
          .map((DocumentSnapshot doc) => Mascota.fromFirestore(doc))
          .toList();
    });
  }

  /// Obtiene una mascota por su ID
  /// Retorna null si no existe
  Future<Mascota?> getMascota(String mascotaId) async {
    try {
      final DocumentSnapshot doc =
          await _mascotasCollection.doc(mascotaId).get();
      if (doc.exists) {
        return Mascota.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la mascota: $e');
    }
  }

  /// Obtiene una mascota por su ID como stream
  Stream<Mascota?> getMascotaStream(String mascotaId) {
    return _mascotasCollection.doc(mascotaId).snapshots().map(
        (DocumentSnapshot doc) {
      if (doc.exists) {
        return Mascota.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Crea una nueva mascota y retorna su ID
  Future<String> crearMascota(Mascota mascota) async {
    try {
      final DocumentReference docRef = await _mascotasCollection.add(
        mascota.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear la mascota: $e');
    }
  }

  /// Actualiza los datos de una mascota existente
  Future<void> actualizarMascota(Mascota mascota) async {
    try {
      await _mascotasCollection
          .doc(mascota.id)
          .update(mascota.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar la mascota: $e');
    }
  }

  /// Actualiza campos específicos de una mascota
  Future<void> actualizarCamposMascota(
    String mascotaId,
    Map<String, dynamic> campos,
  ) async {
    try {
      await _mascotasCollection.doc(mascotaId).update(campos);
    } catch (e) {
      throw Exception('Error al actualizar campos de la mascota: $e');
    }
  }

  /// Elimina una mascota físicamente de Firestore
  Future<void> eliminarMascota(String mascotaId) async {
    try {
      await _mascotasCollection.doc(mascotaId).delete();
    } catch (e) {
      throw Exception('Error al eliminar la mascota: $e');
    }
  }

  /// Busca mascotas por nombre, raza, nombre de dueño, teléfono o número de chip
  /// El filtrado se hace en memoria después de obtener los datos
  Future<List<Mascota>> buscarMascotas(
    String clinicaId,
    String query,
  ) async {
    try {
      if (query.trim().isEmpty) {
        final QuerySnapshot snapshot = await _mascotasCollection
            .where('clinicaId', isEqualTo: clinicaId)
            .orderBy('nombre')
            .get();
        return snapshot.docs
            .map((DocumentSnapshot doc) => Mascota.fromFirestore(doc))
            .toList();
      }

      final String queryLower = query.toLowerCase().trim();

      final QuerySnapshot snapshot = await _mascotasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .get();

      final List<Mascota> todasMascotas = snapshot.docs
          .map((DocumentSnapshot doc) => Mascota.fromFirestore(doc))
          .toList();

      return todasMascotas.where((Mascota mascota) {
        return mascota.nombre.toLowerCase().contains(queryLower) ||
            mascota.raza.toLowerCase().contains(queryLower) ||
            mascota.especie.toLowerCase().contains(queryLower) ||
            mascota.propietario.nombre.toLowerCase().contains(queryLower) ||
            mascota.propietario.telefono.contains(queryLower) ||
            (mascota.chip != null &&
                mascota.chip!.toLowerCase().contains(queryLower)) ||
            (mascota.propietario.email != null &&
                mascota.propietario.email!
                    .toLowerCase()
                    .contains(queryLower));
      }).toList();
    } catch (e) {
      throw Exception('Error al buscar mascotas: $e');
    }
  }

  /// Obtiene una mascota por su token de carnet único
  /// Usa una collectionGroup query para buscar en toda la colección
  Future<Mascota?> getMascotaPorToken(String token) async {
    try {
      final QuerySnapshot snapshot = await _mascotasCollection
          .where('tokenCarnet', isEqualTo: token)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Mascota.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al buscar mascota por token: $e');
    }
  }

  /// Obtiene mascotas por especie
  Future<List<Mascota>> getMascotasPorEspecie(
    String clinicaId,
    String especie,
  ) async {
    try {
      final QuerySnapshot snapshot = await _mascotasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('especie', isEqualTo: especie)
          .orderBy('nombre')
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Mascota.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al filtrar mascotas por especie: $e');
    }
  }

  /// Obtiene las mascotas de un propietario por su teléfono
  Future<List<Mascota>> getMascotasPorTelefonoPropietario(
    String clinicaId,
    String telefono,
  ) async {
    try {
      final QuerySnapshot snapshot = await _mascotasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .where('propietario.telefono', isEqualTo: telefono)
          .get();

      return snapshot.docs
          .map((DocumentSnapshot doc) => Mascota.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar mascotas por teléfono: $e');
    }
  }

  /// Actualiza la URL de la foto de una mascota
  Future<void> actualizarFotoMascota(
    String mascotaId,
    String? fotoUrl,
  ) async {
    try {
      await _mascotasCollection.doc(mascotaId).update({
        'fotoUrl': fotoUrl,
      });
    } catch (e) {
      throw Exception('Error al actualizar la foto de la mascota: $e');
    }
  }

  /// Agrega una alergia a una mascota
  Future<void> agregarAlergia(String mascotaId, String alergia) async {
    try {
      await _mascotasCollection.doc(mascotaId).update({
        'alergias': FieldValue.arrayUnion([alergia]),
      });
    } catch (e) {
      throw Exception('Error al agregar alergia: $e');
    }
  }

  /// Elimina una alergia de una mascota
  Future<void> eliminarAlergia(String mascotaId, String alergia) async {
    try {
      await _mascotasCollection.doc(mascotaId).update({
        'alergias': FieldValue.arrayRemove([alergia]),
      });
    } catch (e) {
      throw Exception('Error al eliminar alergia: $e');
    }
  }

  /// Obtiene el total de mascotas de una clínica
  Future<int> getTotalMascotas(String clinicaId) async {
    try {
      final AggregateQuerySnapshot snapshot = await _mascotasCollection
          .where('clinicaId', isEqualTo: clinicaId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
