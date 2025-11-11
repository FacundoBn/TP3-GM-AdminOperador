import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/domain/logic/ticket_provider.dart';
import 'package:tp3_v2/domain/logic/user_service_provider.dart';
import 'package:tp3_v2/domain/logic/vehicle_provider.dart';
import 'package:tp3_v2/domain/models/user_model.dart';
import 'package:tp3_v2/domain/models/vehicle_model.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class AssignDriverScreen extends ConsumerStatefulWidget {
  final String vehiclePlate;
  final String ticketId;
  const AssignDriverScreen({super.key, required this.vehiclePlate, required this.ticketId});

  @override
  ConsumerState<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends ConsumerState<AssignDriverScreen> {
  UserModel? _selectedUser;

  @override
  Widget build(BuildContext context) {
    final vehicleService = ref.read(vehicleServiceProvider);
    final usersRolClientAsync = ref.watch(usersByRolProvider('cliente'));
    final ticketService = ref.read(ticketServiceProvider);
    

    return AppScaffold(
      title: "Assign Driver to Vehicle",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Vehicle?>(
          future: vehicleService.findByPlate(widget.vehiclePlate),
          builder: (context, snapshot) {
            // Loading o error del Future (Vehicle)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error al cargar vehículo: ${snapshot.error}'));
            }

            final vehicle = snapshot.data;
            if (vehicle == null) {
              return const Center(child: Text('Vehículo no encontrado.'));
            }

            // Ahora mostramos dropdown de usuarios
            return usersRolClientAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error al cargar usuarios: $e')),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                      child: Text('No hay usuarios disponibles.'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Vehículo: ${vehicle.plate}",
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),

                    // Dropdown para elegir usuario
                    DropdownButton<UserModel>(
              isExpanded: true,
              value: _selectedUser,
              hint: const Text('Elegir usuario'),
              items: users.map((user) {
                return DropdownMenuItem<UserModel>(
                  value: user,
                  child: Text('${user.nombre} ${user.apellido}'),
                );
              }).toList(),
              onChanged: (user) {
                setState(() => _selectedUser = user);
              },
            ),

                    const SizedBox(height: 24),

                    // Botón de asignar
                    ElevatedButton.icon(
                      onPressed: _selectedUser == null
                          ? null
                          : () async {
                              try {
                                await vehicleService.assignUser(
                                  vehicle.uid!,
                                  _selectedUser!.uid,
                                );

                                // aqui nueva función en TicketService
                                if (_selectedUser != null){
                                await ticketService.updateTicket(
                                  ticketId:widget.ticketId,
                                  userId:_selectedUser!.uid, 
                                  userNombre: _selectedUser!.nombre,
                                  userApellido: _selectedUser!.apellido,
                                  userEmail:_selectedUser!.email);
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Usuario asignado correctamente'),
                                    ),
                                  );
                                  context.go('/home');
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Error al asignar usuario: $e')),
                                );
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: const Text("Asignar usuario"),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
