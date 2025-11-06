import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('tickets')
        .where('status', isEqualTo: 'closed');

    return AppScaffold(
      title: 'Historial',
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data?.docs ?? [];
          if (all.isEmpty) {
            return const Center(child: Text('Aún no hay tickets finalizados'));
          }

          final docs = [...all]..sort((a, b) {
            final ta = (a.data()['ingreso'] as Timestamp).toDate();
            final tb = (b.data()['ingreso'] as Timestamp).toDate();
            return tb.compareTo(ta);
          });

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final plate = (d['vehiclePlate'] ?? '') as String;
              final ingreso = (d['ingreso'] as Timestamp).toDate();
              final egreso = d['egreso'] != null ? (d['egreso'] as Timestamp).toDate() : null;
              final price = d['precioFinal'];

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.receipt_long, color: Colors.white),
                ),
                title: Text(plate),
                subtitle: Text('De ${ingreso.toLocal()} a ${egreso?.toLocal() ?? '-'} • \$${(price ?? 0).toStringAsFixed(2)}'),
                onTap: () {
                  // futuro: comprobante / detalle
                },
              );
            },
          );
        },
      ),
    );
  }
}
