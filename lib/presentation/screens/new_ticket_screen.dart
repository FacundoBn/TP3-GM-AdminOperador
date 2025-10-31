import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/domain/logic/new_ticket_notifier.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';
import 'package:tp3_v2/presentation/widgets/assign_driver.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  final String plate;
  const NewTicketScreen({super.key, required this.plate});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  bool assignUser = false; // controla si se despliega AssignDriverSection

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(newTicketNotifierProvider);

    return AppScaffold(
      title: 'Nuevo Ticket',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1️⃣ Mostrar placa
            Text('Patente: ${widget.plate}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // 2️⃣ Botón "Iniciar Ticket / Continuar"
            ElevatedButton(
              onPressed: () {
                ref.read(newTicketNotifierProvider.notifier)
                .startNewTicket(plate: widget.plate, context: context);
              },
              child: const Text('Continuar'),
            ),
            const SizedBox(height: 16),

            // 3️⃣ Sección Vehículo
            
            if (ticketState?.vehicleId != null) ...[
              // ✅ Caso: ya existe vehículo
              Text('Vehículo: ${ticketState!.vehicleTipo ?? "-"}'),
              Text('ID Vehículo: ${ticketState.vehicleId ?? "-"}'),
            ] else ...[
              // 🚗 Caso: NO hay vehículo → alta rápida
              const Text(
                'No se encontró un vehículo con esta patente.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Patente: ${ticketState?.vehiclePlate ?? "-"}'),

              const SizedBox(height: 16),
              const Text('Seleccione tipo de vehículo:'),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  for (final tipo in ['auto', 'moto', 'camioneta'])
                    ChoiceChip(
                      label: Text(tipo),
                      selected: ticketState?.vehicleTipo == tipo,
                      onSelected: (v) async {
                        if (v) {
                          await ref
                              .read(newTicketNotifierProvider.notifier)
                              .registerNewVehicle(tipo);
                        }
                      },
                    ),
                ],
              ),

              // const SizedBox(height: 16),
              // const Text(
              //   'El vehículo se guardará sin usuario asociado.',
              //   style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              // ),
            ],
            if (ticketState?.vehicleId!=null && ticketState?.userId == null) ...[
               FilledButton(onPressed: (){  
                setState(() {
                assignUser = !assignUser;  
               });
               }
               ,
               child: Text('asignar usuario'))
            ],

            const SizedBox(height: 16),
            // asociar usuario

            if (assignUser && ticketState != null) ...[
              AssignDriverSection()
            ],

            // 4️⃣ Sección Usuario asociado al vehículo
            if (ticketState?.userId != null) ...[
              Text('Usuario: ${ticketState!.userNombre ?? "-"} ${ticketState.userApellido ?? "-"}'),
              Text('Email: ${ticketState.userEmail ?? "-"}'),
              ],
            const SizedBox(height: 16),

            // 5️⃣ Botón Confirmar (habilitado solo si state.informacionMinima)
            ElevatedButton(
              onPressed: ticketState?.informacionMinima() ?? false
                  ? () async {
                      await ref.read(newTicketNotifierProvider.notifier)
                               .assignSlot();
                      await ref.read(newTicketNotifierProvider.notifier)
                                .confirmIngreso();
                      
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
