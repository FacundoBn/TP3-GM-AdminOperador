import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class ActiveSessionScreen extends StatelessWidget {
  final String? ticketId;
  final bool readOnly;
  const ActiveSessionScreen({super.key, this.ticketId, this.readOnly = true});

  @override
  Widget build(BuildContext context) {
    if (ticketId == null) {
      return const AppScaffold(
        title: 'Estadía activa',
        body: Center(child: Text('No hay estadía activa seleccionada.')),
      );
    }

    final doc = FirebaseFirestore.instance.collection('tickets').doc(ticketId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AppScaffold(
            title: 'Estadía activa',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const AppScaffold(
            title: 'Estadía activa',
            body: Center(child: Text('Ticket no encontrado.')),
          );
        }

        final d = snap.data!.data()!;
        final plate = (d['plate'] ?? '') as String;
        final status = (d['status'] ?? '') as String; // 'active' | 'closed'
        final ingreso = (d['ingreso'] as Timestamp).toDate();
        final egreso = d['egreso'] != null ? (d['egreso'] as Timestamp).toDate() : null;
        final precio = d['precioFinal'];
        final isActive = status == 'active';

        final duration = DateTime.now().toUtc().difference(ingreso.toUtc());
        final hh = duration.inHours.toString().padLeft(2, '0');
        final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return AppScaffold(
          title: 'Estadía activa',
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.local_parking)),
                    title: Text('Patente: $plate'),
                    subtitle: Text('Inicio: ${ingreso.toLocal()}'),
                    trailing: Chip(
                      label: Text(isActive ? 'ACTIVO' : 'CERRADO'),
                      backgroundColor: isActive ? Colors.green.shade100 : Colors.blueGrey.shade100,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: isActive
                        ? Column(
                            children: [
                              const Text('Tiempo transcurrido'),
                              const SizedBox(height: 6),
                              Text('$hh:$mm:$ss', style: Theme.of(context).textTheme.displaySmall),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Inicio:  ${ingreso.toLocal()}'),
                              if (egreso != null) Text('Fin:     ${egreso.toLocal()}'),
                              const SizedBox(height: 8),
                              Text('Total:   \$${(precio ?? 0).toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                  ),
                ),
                const Spacer(),
                if (isActive && !readOnly)
                  FilledButton.icon(
                    onPressed: () async {
                      final now = DateTime.now().toUtc();
                      final minutes = now.difference(ingreso.toUtc()).inMinutes.clamp(1, 1000000);

                      // (Opcional) leer tarifa desde config/settings
                      final cfg = await FirebaseFirestore.instance.collection('config').doc('settings').get();
                      final tarifa = ((cfg.data()?['tarifaPorHora'] ?? 100).toDouble()).clamp(0.01, 1000000.0);
                      final amount = (tarifa / 60.0) * minutes;

                      await doc.update({
                        'egreso': Timestamp.fromDate(now),
                        'precioFinal': amount,
                        'status': 'closed',
                      });

                      if (context.mounted) context.go('/history');
                    },
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Finalizar'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
