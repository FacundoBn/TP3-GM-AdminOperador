import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 👈 agregado
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final docRef =
    FirebaseFirestore.instance.collection('tickets').doc(ticketId);

    return AppScaffold(
      title: 'Comprobante',
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: docRef.get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Ticket no encontrado'));
          }

          final data = snap.data!.data()!;
          final plate = (data['vehiclePlate'] ?? data['plate'] ?? '---') as String;
          final ingreso = (data['ingreso'] as Timestamp).toDate();
          final egreso = data['egreso'] != null
              ? (data['egreso'] as Timestamp).toDate()
              : null;
          final total = (data['precioFinal'] ?? 0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de estadía',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Patente: $plate'),
                    const SizedBox(height: 8),
                    Text('Inicio:  $ingreso'),
                    Text('Fin:    ${egreso ?? '-'}'),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: const Text(
                          'Volver al inicio',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
