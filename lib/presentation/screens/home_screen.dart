// lib/presentation/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeQuery = FirebaseFirestore.instance
        .collection('tickets')
        .where('egreso', isNull: true);

    return AppScaffold(
      title: 'Home',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadías activas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: activeQuery.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay estadías activas'));
                  }

                  // Ordena por ingreso desc en cliente
                  docs.sort((a, b) {
                    final ta = (a.data()['ingreso'] as Timestamp).toDate();
                    final tb = (b.data()['ingreso'] as Timestamp).toDate();
                    return tb.compareTo(ta);
                  });

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final data = docs[i].data();
                      final id = docs[i].id;
                      final plate = (data['vehiclePlate'] ?? '') as String;
                      final ingreso = (data['ingreso'] as Timestamp).toDate();

                      final dur = DateTime.now()
                          .toUtc()
                          .difference(ingreso.toUtc());
                      final hh =
                          dur.inHours.toString().padLeft(2, '0');
                      final mm =
                          (dur.inMinutes % 60).toString().padLeft(2, '0');

                      // Si NO tiene user asignado mostramos el botón
                      final userId = (data['userId'] ?? data['userid']) as String?;
                      final bool hasAssignedUser =
                          userId != null && userId.trim().isNotEmpty;

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFA5D6A7),
                          child: Icon(Icons.play_arrow, color: Colors.black),
                        ),
                        title: Text(plate),
                        subtitle:
                            Text('Desde: ${ingreso.toLocal()} • $hh:$mm'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!hasAssignedUser)
                              TextButton(
                                onPressed: () {
                                  if (plate.trim().isEmpty || id.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Falta información del ticket o patente',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  context.go(
                                    '/assign',
                                    extra: {
                                      'plate': plate,
                                      'id': id,
                                    },
                                  );
                                },
                                child: const Text('Assign User'),
                              ),
                            const Chip(label: Text('ACTIVO')),
                          ],
                        ),
                        onTap: () => context.go('/active', extra: id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
