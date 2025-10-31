import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/domain/logic/new_ticket_notifier.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class NewTicketScreen extends ConsumerWidget {
  final String plate;

  const NewTicketScreen({super.key, required this.plate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketState = ref.watch(newTicketNotifierProvider);

    return AppScaffold(
      title: 'Nuevo Ticket',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1️⃣ Mostrar placa
            Text('Patente: $plate', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // 2️⃣ Botón "Iniciar Ticket / Continuar"
            ElevatedButton(
              onPressed: () {
                ref.read(newTicketNotifierProvider.notifier)
                .startNewTicket(plate: plate, context: context);
              },
              child: const Text('Continuar'),
            ),
            const SizedBox(height: 16),

            // 3️⃣ Sección Vehículo
            
            if (ticketState?.vehicleId != null) ...[
              Text('Vehículo: ${ticketState!.vehicleTipo ?? "-"}'),
              Text('ID Vehículo: ${ticketState.vehicleId ?? "-"}'),
              ] else ...[
              const Text('Seleccione tipo de vehículo:'),
              // TODO: Dropdown o radio buttons con tipos: auto, moto, camioneta
              ],

            const SizedBox(height: 16),

            // 4️⃣ Sección Usuario asociado al vehículo
            if (ticketState?.userId != null) ...[
              Text('Usuario: ${ticketState!.userNombre ?? "-"} ${ticketState.userApellido ?? "-"}'),
              Text('Email: ${ticketState.userEmail ?? "-"}'),
              ],
            const SizedBox(height: 16),

            // 5️⃣ Botón Confirmar (habilitado solo si state.informacionMinima)
            ElevatedButton(
              onPressed: ticketState?.informacionMinima() ?? false
                  ? () {
                      // TODO: asignar cochera + crear ticket en Firestore
                    }
                  : null,
              child: const Text('Confirmar Ingreso'),
            ),
            const SizedBox(height: 16),

            // 6️⃣ Feedback de Slot / errores
            // TODO: mostrar mensaje si no hay slots disponibles
          ],
        ),
      ),
    );
  }
}
