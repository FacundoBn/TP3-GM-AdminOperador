// lib/data/ticket_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/domain/models/ticket_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> create(Ticket ticket) async {
    debugPrint('ticket_service.create: ${ticket.toString()}');
    final ref = _firestore.collection('tickets').doc();
    await ref.set(ticket.toFirestore(), SetOptions(merge: false));
    return ref.id;
  }

  Stream<List<Ticket>> watchActiveTicketsByUser(String userid) {
    return _firestore
        .collection('tickets')
        .where('userid', isEqualTo: userid) // esquema actual
        .where('egreso', isNull: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Ticket.fromFirestore(d)).toList());
  }

  Future<void> closeTicket(
    String ticketUid,
    DateTime egreso,
    double precioFinal,
  ) async {
    // OJO: la colección correcta es 'tickets' (en minúscula)
    await _firestore
        .collection('tickets')
        .doc(ticketUid)
        .update({'egreso': egreso, 'precioFinal': precioFinal});
  }

  Stream<List<Ticket>> watchActiveTicketsByVehicle(String vehicleId) {
    return _firestore
        .collection('tickets')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('egreso', isNull: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Ticket.fromFirestore(d)).toList());
  }

  /// Asigna/actualiza los datos del usuario en el ticket.
  /// Mantiene compatibilidad escribiendo **userId** y **userid**.
  Future<void> updateTicket({
    required String ticketId,
    required String userId,
    required String userNombre,
    required String userApellido,
    required String userEmail,
  }) async {
    try {
      final ticketRef = _firestore.collection('tickets').doc(ticketId);
      final doc = await ticketRef.get();
      if (!doc.exists) {
        throw Exception('Ticket no encontrado: $ticketId');
      }

      await ticketRef.update({
        // claves nuevas
        'userId': userId,
        'userNombre': userNombre,
        'userApellido': userApellido,
        'userEmail': userEmail,
        // compat con esquema previo
        'userid': userId,
        'user_name': userNombre,   // si tu modelo viejo lo usa, queda cubierto
        'user_lastname': userApellido,
        'user_mail': userEmail,
      });

      debugPrint('✅ Ticket $ticketId actualizado con usuario $userId');
    } catch (e, st) {
      debugPrint('❌ Error en TicketService.updateTicket: $e\n$st');
      rethrow;
    }
  }
}
