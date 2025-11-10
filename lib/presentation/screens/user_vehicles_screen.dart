import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/domain/logic/current_user_provider.dart';
import 'package:tp3_v2/domain/logic/vehicle_provider.dart';

class UserVehiclesScreen extends ConsumerWidget {
  final String? userUid;

  const UserVehiclesScreen({super.key, this.userUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final effectiveUserUid = userUid ?? ref.watch(currentUserProvider).value?.uid;

    if (effectiveUserUid == null) {
      return const Center(child: Text('No hay sesión activa'));
    }

    final vehiclesAsync = ref.watch(userVehiclesProvider(effectiveUserUid));

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_filled,
                      size: 48, color: theme.colorScheme.primary.withOpacity(.35)),
                  const SizedBox(height: 8),
                  Text(
                    'No hay vehículos registrados',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Podés asociar un vehículo desde el flujo de ingreso.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final v = vehicles[i];
                final icon = v.tipo.name == 'moto'
                    ? Icons.two_wheeler
                    : v.tipo.name == 'camioneta'
                        ? Icons.local_shipping
                        : Icons.directions_car;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                      child: Icon(icon, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      v.plate,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(v.tipo.name),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
