import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/domain/models/ticket_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<String> create(Ticket ticket) async {
    debugPrint('tiket_service: create: ${ticket.toString()}');
    final ref = _firestore.collection('tickets').doc();
    await ref.set(ticket.toFirestore(), SetOptions(merge: false));
    return ref.id;
  }

  Stream <List<Ticket>> watchActiveTicketsByUser(String userid){
    return _firestore
        .collection('tickets')
        .where('userid', isEqualTo: userid)
        .where('egreso', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList());
  }

  Future<void> closeTicket (String ticketUid, DateTime egreso, double precioFinal ) async {
    await _firestore.collection('Tickets')
    .doc(ticketUid)
    .update({'egreso': egreso, "precioFinal":precioFinal});
  }

  Stream<List<Ticket>> watchActiveTicketsByVehicle(String vehId) {
    return _firestore
      .collection('tickets')
      .where('vehicleId', isEqualTo: vehId)
      .where('egreso', isNull: true)
      .snapshots()
      .map((snapshot){
        return snapshot.docs
        .map((doc){
          return Ticket.fromFirestore(doc);
        })
        .toList();
      });    
    }
}  