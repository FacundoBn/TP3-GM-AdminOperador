import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tp3_v2/domain/models/slot_model.dart';

class SlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ==========================
  /// EXISTENTES / BÁSICOS
  /// ==========================

  /// ¿Hay al menos un slot libre?
  Future<bool> hasAvailableSlot() async {
    final querySnapshot = await _firestore
        .collection('slots')
        .where('vehicleId', isNull: true)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  /// Asignar un slot libre al vehículo dado (primer slot disponible)
  Future<String> assignSlotToVehicle(String vehicleId) async {
    final querySnapshot = await _firestore
        .collection('slots')
        .where('vehicleId', isNull: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No hay slots disponibles.');
    }

    final slotDoc = querySnapshot.docs.first;
    final slotId = slotDoc.id;

    await _firestore.collection('slots').doc(slotId).update({'vehicleId': vehicleId});
    return slotId;
  }

  /// Liberar cochera (al cerrar ticket)
  Future<void> releaseSlot(String slotId) async {
    await _firestore.collection('slots').doc(slotId).update({'vehicleId': null});
  }

  /// Obtener slot por ID
  Future<Slot> getSlotById(String slotId) async {
    final doc = await _firestore.collection('slots').doc(slotId).get();
    return Slot.fromFirestore(doc);
  }

  /// ==========================
  /// LISTADO (FUTURE y STREAM)
  /// ==========================

  /// Trae todos los slots una sola vez
  Future<List<Slot>> fetchSlots() async {
    final snap = await _firestore
        .collection('slots')
        // si Firestore pide índice por este orderBy, podés quitarlo o crear el índice sugerido
        .orderBy('garageId')
        .get();
    return snap.docs.map((d) => Slot.fromFirestore(d)).toList();
  }

  /// 🔄 Stream en tiempo real de todos los slots
  Stream<List<Slot>> watchSlots() {
    // si Firestore pide índice por este orderBy, podés quitarlo o crear el índice sugerido
    return _firestore
        .collection('slots')
        .orderBy('garageId')
        .snapshots()
        .map((qs) => qs.docs.map((d) => Slot.fromFirestore(d)).toList());
  }

  /// Usado por `new_ticket_notifier.dart`: alias del método existente
  Future<String> assignFirstAvailableSlot(String vehicleId) {
    return assignSlotToVehicle(vehicleId);
  }

  /// ==========================
  /// GENERACIÓN / CONTEO
  /// ==========================

  /// Contar documentos en `slots`
  Future<int> countSlots() async {
    try {
      final agg = await _firestore.collection('slots').count().get();
      return agg.count ?? 0; // agg.count es int?
    } catch (_) {
      final snap = await _firestore.collection('slots').get();
      return snap.docs.length;
    }
  }

  /// Extrae prefijo y número de un garageId. Acepta "A-1", "A1", "B12".
  (String prefix, int number) _splitGarageId(String? gid) {
    if (gid == null) return ('A', 0);
    final s = gid.trim();
    final dash = RegExp(r'^([A-Za-z]+)-(\d+)$');
    final nodash = RegExp(r'^([A-Za-z]+)(\d+)$');
    final m1 = dash.firstMatch(s);
    if (m1 != null) {
      return (m1.group(1)!.toUpperCase(), int.tryParse(m1.group(2)!) ?? 0);
    }
    final m2 = nodash.firstMatch(s);
    if (m2 != null) {
      return (m2.group(1)!.toUpperCase(), int.tryParse(m2.group(2)!) ?? 0);
    }
    return ('A', 0);
  }

  /// Devuelve prefijo “dominante” y el mayor índice observado.
  Future<(String prefix, int maxIndex)> _getPrefixAndMaxIndex() async {
    final snap = await _firestore.collection('slots').get();
    String chosenPrefix = 'A';
    int maxIdx = 0;

    for (final d in snap.docs) {
      final gid = (d.data()['garageId'] ?? '') as String;
      final (p, n) = _splitGarageId(gid);
      if (maxIdx == 0 && n > 0) {
        chosenPrefix = p;
        maxIdx = n;
      } else if (p == chosenPrefix && n > maxIdx) {
        maxIdx = n;
      }
    }
    return (chosenPrefix, maxIdx);
  }

  /// Crea los slots faltantes hasta alcanzar [targetTotal]
  /// - No borra ni toca los existentes.
  /// - Continúa el patrón del garageId dominante (A-1, A1, B12, etc.)
  /// - Si no hay slots, arranca como A-1
  Future<int> createMissingSlotsToReach(int targetTotal) async {
    final col = _firestore.collection('slots');
    final current = await countSlots();
    if (targetTotal <= current) return 0;

    final toCreate = targetTotal - current;
    int created = 0;

    var (prefix, startFrom) = await _getPrefixAndMaxIndex();

    // Detecta si usás guion en garageId mirando el primer doc
    final firstDocs = await col.limit(1).get();
    final useDash = firstDocs.docs.any((d) {
      final gid = (d.data()['garageId'] ?? '') as String;
      return gid.contains('-');
    });

    WriteBatch batch = _firestore.batch();

    for (int i = 1; i <= toCreate; i++) {
      final idx = startFrom + i;
      final garageId = useDash ? '$prefix-$idx' : '$prefix$idx';
      final ref = col.doc(); // ID autogenerado como en tu base

      batch.set(ref, {
        'garageId': garageId,
        'vehicleId': null,
        'createdAt': DateTime.now(),
      });

      created++;
      if (created % 400 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    await batch.commit();
    return created;
  }

  /// (Opcional) ¿Hay algún slot con vehículo asignado?
  Future<bool> anyOccupied() async {
    final snap = await _firestore
        .collection('slots')
        .where('vehicleId', isGreaterThan: null)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// (Opcional) Elimina hasta [count] slots vacíos, priorizando los últimos creados.
  Future<int> deleteLastEmpty(int count) async {
    if (count <= 0) return 0;

    final col = _firestore.collection('slots');

    final snap = await col
        .where('vehicleId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(count)
        .get();

    if (snap.docs.isEmpty) return 0;

    var batch = _firestore.batch();
    int deleted = 0;

    for (final d in snap.docs) {
      batch.delete(d.reference);
      deleted++;
      if (deleted % 400 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    await batch.commit();
    return deleted;
  }
}
