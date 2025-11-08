import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parting_settings.dart'; // <- tu archivo exacto

/// Lee/guarda la configuración en la colección `parking`.
/// Se asume que hay un único documento dentro de `parking`.
class ParkingSettingsRepository {
  final FirebaseFirestore _db;

  ParkingSettingsRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('parking');

  /// Obtiene (o crea por defecto) la referencia al único doc de `parking`.
  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateDocRef() async {
    final snap = await _col.limit(1).get();
    if (snap.docs.isNotEmpty) return snap.docs.first.reference;

    final ref = await _col.add({
      'hourPrice': 0.0,
      'targetSlots': 0,
      'updatedAt': DateTime.now(),
      'updatedBy': 'system',
    });
    return ref;
  }

  /// Devuelve la configuración actual o null si no existe.
  Future<ParkingSettings?> getSettings() async {
    final ref = await _getOrCreateDocRef();
    final doc = await ref.get();
    if (!doc.exists) return null;
    return ParkingSettings.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Stream para escuchar cambios en vivo (opcional).
  Stream<ParkingSettings?> watchSettings() async* {
    final ref = await _getOrCreateDocRef();
    yield* ref.snapshots().map((d) {
      if (!d.exists) return null;
      return ParkingSettings.fromMap(d.data() as Map<String, dynamic>);
    });
  }

  /// Guarda (merge) la configuración.
  Future<void> saveSettings(
    ParkingSettings settings, {
    required String updatedBy,
  }) async {
    final ref = await _getOrCreateDocRef();
    await ref.set(
      settings.toMap(updatedBy: updatedBy),
      SetOptions(merge: true),
    );
  }
}
