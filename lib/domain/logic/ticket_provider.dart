import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/data/ticket_service.dart';
import 'package:tp3_v2/domain/models/ticket_model.dart';

final ticketServiceProvider = Provider<TicketService>((ref){
   return TicketService();
});

final ticketsProviderById = StreamProvider.autoDispose.family<List<Ticket>, String> ((ref, userId){
  final ticketService = ref.watch(ticketServiceProvider);
  return ticketService.watchActiveTicketsByUser(userId);
});

final ticketsProviderByVehicleId = StreamProvider.autoDispose.family<List<Ticket>, String> ((ref, vehId){
  final ticketService = ref.watch(ticketServiceProvider);
  return ticketService.watchActiveTicketsByVehicle(vehId);
});

