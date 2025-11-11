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
        //.where('status', isEqualTo: 'active');
        .where('egreso', isNull: true);

    

    return AppScaffold(
      title: 'Home',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadías activas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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

                  // Ordenar por ingreso desc en cliente
                  docs.sort((a, b) {
                    final ta = (a.data()['ingreso'] as Timestamp).toDate();
                    final tb = (b.data()['ingreso'] as Timestamp).toDate();
                    return tb.compareTo(ta);
                  });

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final d = docs[i].data();
                      final id = docs[i].id;
                      final plate = (d['vehiclePlate'] ?? '') as String;
                      final ingreso = (d['ingreso'] as Timestamp).toDate();

                      final dur = DateTime.now().toUtc().difference(ingreso.toUtc());
                      final hh = dur.inHours.toString().padLeft(2, '0');
                      final mm = (dur.inMinutes % 60).toString().padLeft(2, '0');

                      final userId = d['userId'] as String?;
                      final bool assignedUser = userId != null && userId.isNotEmpty;

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFA5D6A7),
                          child: Icon(Icons.play_arrow, color: Colors.black),
                        ),
                        title: Text(plate),
                        subtitle: Text('Desde: ${ingreso.toLocal()} • $hh:$mm'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                           if (!assignedUser)
                            TextButton(
                              onPressed: () {
                                
                                if (plate != null && plate.isNotEmpty
                                && id != null && id.isNotEmpty) {
                                  context.go(
                                    '/assign',
                                    extra: {
                                      'plate': plate,
                                      'id': id,
                                    },
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No se encontró un vehicleId válido')),
                                  );
                                }
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
