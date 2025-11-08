import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/data/slot_service.dart';
import 'package:tp3_v2/domain/models/slot_model.dart';

final slotServiceProvider = Provider<SlotService>((ref) => SlotService());

final slotsProvider = StreamProvider<List<Slot>>((ref) {
  final service = ref.watch(slotServiceProvider);
  // Usamos el stream para tener la lista en tiempo real
  return service.watchSlots();
});
