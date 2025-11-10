// lib/presentation/screens/ticket_receipt_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';

class TicketReceiptScreen extends StatelessWidget {
  final String ticketId;
  const TicketReceiptScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('tickets').doc(ticketId);

    return AppScaffold(
      title: 'Comprobante',
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: docRef.get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error cargando comprobante: ${snap.error}'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('No se encontró el ticket.'));
          }

          final data = snap.data!.data()!;
          final plate      = (data['vehiclePlate'] ?? '') as String? ?? '';
          final ingresoTs  = data['ingreso'];
          final egresoTs   = data['egreso'];
          final ingreso    = ingresoTs is Timestamp ? ingresoTs.toDate() : null;
          final egreso     = egresoTs  is Timestamp ? egresoTs.toDate()  : null;
          final precio     = (data['precioFinal'] is num) ? (data['precioFinal'] as num).toDouble() : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Resumen de estadía', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Patente: ${plate.isEmpty ? '-' : plate}'),
                        Text('Inicio:  ${_fmtDateTime(ingreso)}'),
                        Text('Fin:     ${_fmtDateTime(egreso)}'),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                            Text(
                              precio != null ? '\$${precio.toStringAsFixed(2)}' : '-',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.home),
                            label: const Text('Volver al inicio'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final d = '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
    final t = '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';
    return '$d $t';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
