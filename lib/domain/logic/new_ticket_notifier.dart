import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/data/slot_service.dart';
import 'package:tp3_v2/data/ticket_service.dart';
import 'package:tp3_v2/data/user_service.dart';
import 'package:tp3_v2/data/vehicle_service.dart';
import 'package:tp3_v2/domain/logic/current_user_provider.dart';
import 'package:tp3_v2/domain/logic/slot_provider.dart';
import 'package:tp3_v2/domain/logic/ticket_provider.dart';
import 'package:tp3_v2/domain/logic/vehicle_provider.dart';
import 'package:tp3_v2/domain/models/ticket_model.dart';
import 'package:tp3_v2/domain/models/vehicle_model.dart';

final newTicketNotifierProvider =
    NotifierProvider<NewTicketNotifier, Ticket?>(() => NewTicketNotifier());

class NewTicketNotifier extends Notifier<Ticket?> {
  late final UserService _userService;
  late final TicketService _ticketService;
  late final SlotService _slotService;
  late final VehicleService _vehicleService;

  
  @override
  Ticket? build() {
    // 🔹 Estado inicial: sin ticket cargado
    _slotService = ref.read(slotServiceProvider);
    _ticketService = ref.read(ticketServiceProvider);
    _userService = ref.read(userServiceProvider);
    _vehicleService = ref.watch(vehicleServiceProvider);

    return null;
  }
  

  /// Crear un nuevo Ticket temporal (sin escribir en DB)
  Future<void> startNewTicket({
  required String plate,
  required BuildContext context,
}) async {
  try {
    // 1️⃣ Chequear cocheras disponibles
    final haySlot = await _slotService.hasAvailableSlot();
    if (!haySlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cocheras disponibles')),
      );
      return; // sale sin inicializar state
    }

    // 2️⃣ Inicializar state parcial con la patente
    state = Ticket(
      vehiclePlate: plate,
      ingreso: null,
      slotId: null,
    );
    debugPrint('State inicial con patente: $state');

    // 3️⃣ Buscar vehículo existente
    final vehicle = await _vehicleService.findByPlate(plate);
    if (vehicle != null) {
      final String tipo = Vehicle.vehicleTypeToString(vehicle.tipo);
      state = state!.copyWith(
        vehicleId: vehicle.uid,
        vehicleTipo: tipo,
        userId: vehicle.userId,
      );
      debugPrint('State tras asignar vehículo: $state');
    }

    // 4️⃣ Traer datos del usuario si existe
    if (state!.userId != null) {
      final user = await _userService.findByUserId(state!.userId!);
      if (user!=null) debugPrint('${user.apellido} - ${user.nombre}');
      state = state!.copyWith(
        userNombre: user?.nombre,
        userApellido: user?.apellido,
        userEmail: user?.email,
      );
      debugPrint('State tras asignar usuario: $state');
    }

    // 5️⃣ En este punto, la UI puede mostrar los datos
    debugPrint('State final antes de mostrar UI: $state');

  } catch (e, st) {
    // Manejo general de errores
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al iniciar ticket: $e')),
    );
    debugPrint('startNewTicket error: $e\n$st');
  }
}

  /// 🔹 Actualizar campos del ticket dinámicamente
  void updateTicket(Ticket updated) {
    state = updated;
  }

  // 🔹 Actualiza solo los campos provistos, dejando los demás intactos
  void updatePartial({
    String? uid,
    String? vehicleId,
    String? userId,
    String? guestId,
    String? slotId,
    DateTime? ingreso,
    String? vehiclePlate,
    String? vehicleTipo,
    String? userNombre,
    String? userApellido,
    String? userEmail,
    String? slotGarageId,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      uid: uid ?? state!.uid,
      vehicleId: vehicleId ?? state!.vehicleId,
      userId: userId ?? state!.userId,
      guestId: guestId ?? state!.guestId,
      slotId: slotId ?? state!.slotId,
      ingreso: ingreso ?? state!.ingreso,
      vehiclePlate: vehiclePlate ?? state!.vehiclePlate,
      vehicleTipo: vehicleTipo ?? state!.vehicleTipo,
      userNombre: userNombre ?? state!.userNombre,
      userApellido: userApellido ?? state!.userApellido,
      userEmail: userEmail ?? state!.userEmail,
      slotGarageId: slotGarageId ?? state!.slotGarageId,
    );
  }

    Future<void> checkSlotAvailableOrThrow() async {
      final free = await _slotService.hasAvailableSlot();
      if (!free) {
        throw Exception('No hay cocheras libres');
      }
    }

  /// 🔹 Asignar cochera automáticamente (ejemplo placeholder)
  Future<void> assignSlot() async {
    if (state == null || state!.vehicleId==null || state!.vehicleId!.isEmpty) return;
    // TODO: usar slotService para obtener cochera disponible
    final slotId = await _slotService.assignFirstAvailableSlot(state!.vehicleId!);
    final slot = await _slotService.getSlotById(slotId);
    
    if (slotId != null && slotId.isNotEmpty)
    {updatePartial(slotId: slotId, slotGarageId: slot.garageId ?? 'sin identificar');}
  }

  /// 🔹 Asociar un vehículo existente o crear uno nuevo
  Future<void> attachVehicle() async {
    if (state == null) return;
    // TODO: buscar o crear vehículo usando vehicleService
    final fakeVehicleId = 'VEHICLE_XYZ';
    updatePartial(vehicleId: fakeVehicleId);
  }

  /// 🔹 Confirmar ingreso (cierra la preparación y escribe en Firestore)
  Future<String> confirmIngreso() async {
    if (state == null || !state!.informacionMinima()) {
      throw Exception('Datos incompletos para registrar ticket.');
    }
    if (state!.ingreso == null) {
    state = state!.copyWith(ingreso: DateTime.now());
    }    
    final ref= await _ticketService.create(state!);
    updatePartial(uid: ref);
    return ref;
  }

  /// 🔹 Resetear ticket actual (volver al estado nulo)
  void clear() {
    state = null;
  }

  Future<void> registerNewVehicle(String tipo) async {
    debugPrint('newTicketNotifier.registerNewVehicle state antes de ejecutar ${state}');
    if (state == null || state!.vehiclePlate == null) return;

    try {
      // 1️⃣ Crear el nuevo vehículo en Firestore
      final newVehicle = Vehicle(
        uid: null,
        plate: state!.vehiclePlate!,
        tipo: Vehicle.stringToVehicleType(tipo),
        userId: null, // por ahora sin usuario
      );

      final newVehicleId = await _vehicleService.addVehicle(newVehicle);

      // 2️⃣ Actualizar el ticket actual
      updatePartial(
        vehicleId: newVehicleId,
        vehicleTipo: tipo,
        userId: null,
      );

      debugPrint('Vehículo creado y asignado al ticket: $newVehicleId');

    } catch (e, st) {
      debugPrint('Error al registrar vehículo: $e\n$st');
      // Mostrar feedback en pantalla
      // ScaffoldMessenger.of(globalContext!).showSnackBar(
      //   SnackBar(content: Text('Error al registrar vehículo: $e')),
      // );
    }
  }

  Future<void> assignUser(String userUid) async {
    try{
    await _vehicleService.assignUser(state!.vehicleId!, userUid);
    debugPrint('usuario asignado a Ticket: state: ${state}');
    } catch(e,st){
      debugPrint ('Error asignando usuario: ${e} - stack: $st');
    }
  }
}