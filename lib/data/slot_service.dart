import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tp3_v2/domain/models/slot_model.dart';


class SlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> hasAvailableSlot() async {
    final querySnapshot = await _firestore
        .collection('slots')
        .where('vehicleId', isNull: true)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }


  /// 🔹 Traer todos los slots (reactivo)
  Stream<List<Slot>> fetchSlots() {
    return _firestore.collection('slots').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Slot.fromFirestore(doc)).toList(),
    );
  }

  /// 🔹 Agregar un slot
  Future<String> addSlot(Slot slot) async {
    final docRef = await _firestore.collection('slots').add(slot.toFirestore());
    return docRef.id;
  }

  /// 🔹 Asignar primera cochera libre
  Future<String> assignFirstAvailableSlot(String vehicleId) async {
    final querySnapshot = await _firestore
        .collection('slots')
        .where('vehicleId', isNull: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No hay cocheras libres');
    }

    final slotDoc = querySnapshot.docs.first;
    final slotId = slotDoc.id;

    await _firestore.collection('slots').doc(slotId).update({'vehicleId': vehicleId});
    return slotId;
  }

  /// 🔹 Liberar cochera (al cerrar ticket)
  Future<void> releaseSlot(String slotId) async {
    await _firestore.collection('slots').doc(slotId).update({'vehicleId': null});
  }

  Future <Slot> getSlotById(String slotId) async{
   final doc = await _firestore.collection('slots').doc(slotId).get();
   return Slot.fromFirestore(doc);
  }
}
