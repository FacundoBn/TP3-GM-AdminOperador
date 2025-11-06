import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/domain/logic/new_ticket_notifier.dart';
import 'package:tp3_v2/domain/logic/user_service_provider.dart';

class AssignDriverSection extends ConsumerStatefulWidget {
  const AssignDriverSection({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __AssignUserWidgetStateState();
}

class __AssignUserWidgetStateState extends ConsumerState<AssignDriverSection> {

  String? _selectedUserId;
  
  @override
  Widget build(BuildContext context) {
  final ticketState = ref.watch(newTicketNotifierProvider);
  final usersRolClientAsync = ref.watch(usersByRolProvider('cliente'));  
    
    
    return usersRolClientAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Text('No hay usuarios disponibles para este rol.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione un usuario:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButton<String>(
              isExpanded: true,
              value: _selectedUserId,
              hint: const Text('Elegir usuario'),
              items: users.map((user) {
                return DropdownMenuItem<String>(
                  value: user.uid,
                  child: Text('${user.nombre} ${user.apellido}'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedUserId = val);
              },
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: _selectedUserId == null
                  ? null
                  : () async {
                      // 🧩 Buscar el usuario seleccionado
                      final selectedUser = users.firstWhere(
                        (u) => u.uid == _selectedUserId,
                      );
                      await ref
                          .read(newTicketNotifierProvider.notifier)
                          .assignUser(selectedUser.uid);
                          ref
                          .read(newTicketNotifierProvider.notifier)
                          .updatePartial(userNombre:selectedUser.nombre,
                                        userApellido:selectedUser.apellido,
                                        userEmail: selectedUser.email,
                                        userId: selectedUser.uid,);
                    },
              child: const Text('Asignar usuario'),
            ),
          ],
        );
      },
     loading: ()=> const Center(child: CircularProgressIndicator()),
     error: (e,st) => Text('Error ${e} - stack ${st}'), 
    );
  }
}