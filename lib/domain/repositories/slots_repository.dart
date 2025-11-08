import 'package:cloud_firestore/cloud_firestore.dart';

/// Operaciones sobre la colección `slots`:
/// - contar
/// - generar faltantes hasta alcanzar un total objetivo
class SlotsRepository {
  final FirebaseFirestore _db;

  SlotsRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('slots');

  /// Cuenta documentos en `slots`. Usa agregación si está disponible.
  Future<int> countSlots() async {
    try {
      final agg = await _col.count().get(); // requiere cloud_firestore reciente
      return agg.count;
    } catch (_) {
      final snap = await _col.get(); // fallback
      return snap.docs.length;
    }
  }

  /// Obtiene el mayor índice encontrado en `garageId` con formato "A-<n>".
  Future<int> _getMaxIndex({String prefix = 'A'}) async {
    final snap = await _col.get();
    int maxIdx = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final gid = (data['garageId'] ?? '') as String;
      final parts = gid.split('-');
      if (parts.length == 2 && parts[0] == prefix) {
        final n = int.tryParse(parts[1]);
        if (n != null && n > maxIdx) maxIdx = n;
      }
    }
    return maxIdx;
  }

  /// Crea los slots faltantes hasta llegar a [targetTotal].
  /// - No borra ni modifica existentes.
  /// - Genera `garageId` como "A-<n>" siguiendo el mayor actual.
  /// - `vehicleId` arranca en null.
  Future<int> createMissingSlotsToReach(
    int targetTotal, {
    String prefix = 'A',
  }) async {
    final current = await countSlots();
    if (targetTotal <= current) return 0;

    final toCreate = targetTotal - current;
    int created = 0;
    var batch = _db.batch();
    int startFrom = await _getMaxIndex(prefix: prefix);

    for (int i = 1; i <= toCreate; i++) {
      final idx = startFrom + i;
      final garageId = '$prefix-$idx';

      // Si preferís usar docId == garageId, cambiá a: _col.doc(garageId)
      final ref = _col.doc();

      batch.set(ref, {
        'garageId': garageId,
        'vehicleId': null,
        'createdAt': DateTime.now(),
      });

      created++;

      // Commit por tandas para evitar límites de tamaño
      if (created % 400 == 0) {
        await batch.commit();
        batch = _db.batch();
      }
    }

    await batch.commit();
    return created;
  }

  /// (Opcional) ¿Hay algún slot con vehículo asignado?
  Future<bool> anyOccupied() async {
    final snap = await _col.where('vehicleId', isGreaterThan: null).limit(1).get();
    return snap.docs.isNotEmpty;
  }
}
