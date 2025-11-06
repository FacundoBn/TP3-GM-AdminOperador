import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/domain/models/vehicle_model.dart';


class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Agregar un vehicle
  Future<String> addVehicle(Vehicle vehicle) async {
    final docRef = await _firestore.collection('vehicles').add(vehicle.toFirestore());
    return docRef.id;
  }

  /// 🔹 Obtener vehicles de un usuario (reactivo)
  Stream<List<Vehicle>> fetchVehiclesForUser(String userUid) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Vehicle.fromFirestore(doc)).toList());
  }

  /// 🔹 Asignar un usuario a un vehicle existente
  Future<void> assignUser(String vehicleUid, String userUid) async {
    // opcional: validar que userUid exista en users collection
    final userDoc = await _firestore.collection('users').doc(userUid).get();
    if (!userDoc.exists) throw Exception('Usuario no encontrado');

    await _firestore.collection('vehicles').doc(vehicleUid).update({'userId': userUid});
  }

  /// 🔹 Eliminar un vehicle
  Future<void> deleteVehicle(String vehicleUid) async {
    await _firestore.collection('vehicles').doc(vehicleUid).delete();
  }

  Future <Vehicle?>findByPlate (String plate) async {
    try{
      final query = await _firestore
                      .collection('vehicles')
                      .where('plate',isEqualTo: plate)
                      .limit(1)
                      .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return Vehicle.fromFirestore(doc);
    } catch (e, st){
      debugPrint('Error en VehicleService.findByPlate ${e.toString()}');
      return null;
    }                 
  }
}
