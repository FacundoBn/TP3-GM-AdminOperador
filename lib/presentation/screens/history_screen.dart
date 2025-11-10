// lib/presentation/screens/history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Evitamos índice compuesto: ordenamos por egreso y filtramos en memoria.
    final query = FirebaseFirestore.instance
        .collection('tickets')
        .orderBy('egreso', descending: true);

    return AppScaffold(
      title: 'Historial',
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final all = snap.data?.docs ?? [];
          final docs = all.where((d) => (d.data()['status'] ?? '') == 'closed').toList();
          if (docs.isEmpty) {
            return const Center(child: Text('No hay tickets finalizados.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final id = doc.id;
              final d = doc.data();

              final plate = (d['vehiclePlate'] ?? '') as String? ?? '';
              final ingresoTs = d['ingreso'];
              final egresoTs  = d['egreso'];
              final ingreso = ingresoTs is Timestamp ? ingresoTs.toDate() : null;
              final egreso  = egresoTs  is Timestamp ? egresoTs.toDate()  : null;
              final total = (d['precioFinal'] is num) ? (d['precioFinal'] as num).toDouble() : null;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                title: Text(plate.isEmpty ? 'Sin patente' : plate),
                subtitle: Text([
                  if (ingreso != null) 'Ing: ${_fmtDateTime(ingreso)}',
                  if (egreso  != null) 'Egr: ${_fmtDateTime(egreso)}',
                  if (total   != null) 'Total: \$${total.toStringAsFixed(2)}',
                ].join(' • ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Igual que en Cliente: usamos /ticket/:id
                  context.push('/ticket/$id');
                  // (También funcionaría context.push('/ticket', extra: id); por la ruta alternativa)
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _fmtDateTime(DateTime dt) {
    final d = '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
    final t = '${_two(dt.hour)}:${_two(dt.minute)}';
    return '$d $t';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
