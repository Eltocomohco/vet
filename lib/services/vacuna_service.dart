import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vetmanager/models/vacuna.dart';
import 'package:vetmanager/utils/constantes.dart';

class VacunaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Vacuna>> getVacunasStream(String mascotaId) {
    return _firestore
        .collection(coleccionMascotas)
        .doc(mascotaId)
        .collection(coleccionVacunas)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Vacuna.fromFirestore(doc)).toList());
  }

  Future<String> crearVacuna(String mascotaId, Vacuna vacuna) async {
    final doc = await _firestore
        .collection(coleccionMascotas)
        .doc(mascotaId)
        .collection(coleccionVacunas)
        .add(vacuna.toFirestore());
    return doc.id;
  }

  Future<void> eliminarVacuna(String mascotaId, String vacunaId) async {
    await _firestore
        .collection(coleccionMascotas)
        .doc(mascotaId)
        .collection(coleccionVacunas)
        .doc(vacunaId)
        .delete();
  }
}
