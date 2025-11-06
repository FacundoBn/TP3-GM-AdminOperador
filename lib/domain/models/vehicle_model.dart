import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleType { moto, auto, camioneta }

class Vehicle {
  final String? uid;        // ID generado por Firestore
  final String plate;      // Patente
  final String? userId;   // ID del usuario dueño (nullable)
  final VehicleType tipo;  // Tipo de vehículo

  Vehicle({
    this.uid,
    required this.plate,
    this.userId,
    required this.tipo,
  });

  /// 🔹 Factory para instanciar desde Firestore
  factory Vehicle.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Vehicle(
      uid: doc.id,
      plate: data['plate'] ?? '',
      userId: data['userId'],
      tipo: stringToVehicleType(data['tipo'] ?? 'auto'), // default auto
    );
  }

  /// 🔹 Serialización a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'plate': plate,
      if (userId != null) 'userId': userId,
      'tipo': vehicleTypeToString(tipo),
    };
  }

  /// Helpers para convertir enum <-> string
  static VehicleType stringToVehicleType(String str) {
    switch (str) {
      case 'moto':
        return VehicleType.moto;
      case 'camioneta':
        return VehicleType.camioneta;
      case 'auto':
        return VehicleType.auto;
      default:
        return VehicleType.auto;
    }
  }

  static String vehicleTypeToString(VehicleType tipo) {
    switch (tipo) {
      case VehicleType.moto:
        return 'moto';
      case VehicleType.camioneta:
        return 'camioneta';
      case VehicleType.auto:
        return 'auto';
      default:
        return 'auto';
    }
  }
}
