import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String? uid;       // ID Firestore
  final String? vehicleId;
  final String? userId;
  final String? guestId;
  final String? slotId;
  final DateTime? ingreso;
  final DateTime? egreso;
  final double? precioFinal;

  // 🔹 Datos redundantes para facilitar la UI
  final String? vehiclePlate;
  final String? vehicleTipo;       // moto, auto, camioneta
  final String? userNombre;
  final String? userApellido;
  final String? userEmail;
  final String? slotGarageId;

  Ticket({
    this.uid,
    this.vehicleId,
    this.userId,
    this.guestId,
    this.slotId,
    this.ingreso,
    this.egreso,
    this.precioFinal,
    this.vehiclePlate,
    this.vehicleTipo,
    this.userNombre,
    this.userApellido,
    this.userEmail,
    this.slotGarageId,
  });

  /// 🔹 Factory para reconstruir desde Firestore
  factory Ticket.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Ticket(
      uid: doc.id,
      vehicleId: data['vehicleId'] as String,
      userId: data['userId'] as String?,
      guestId: data['guestId'] as String?,
      slotId: data['slotId'] as String,
      ingreso: (data['ingreso'] as Timestamp).toDate(),
      egreso: data['egreso'] != null ? (data['egreso'] as Timestamp).toDate() : null,
      precioFinal: data['precioFinal'] != null ? (data['precioFinal'] as num).toDouble() : null,
      vehiclePlate: data['vehiclePlate'] as String? ?? '',
      vehicleTipo: data['vehicleTipo'] as String? ?? 'auto',
      userNombre: data['userNombre'] as String? ?? '',
      userApellido: data['userApellido'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      slotGarageId: data['slotGarageId'] as String? ?? '',
    );
  }

  /// 🔹 Serialización a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'vehicleId': vehicleId,
      'userId': userId,
      if (guestId != null) 'guestId': guestId,
      'slotId': slotId,
      'ingreso': Timestamp.fromDate(ingreso!),
      if (egreso != null) 'egreso': Timestamp.fromDate(egreso!),
      if (precioFinal != null) 'precioFinal': precioFinal,
      // 🔹 Datos redundantes
      'vehiclePlate': vehiclePlate,
      'vehicleTipo': vehicleTipo,
      'userNombre': userNombre,
      'userApellido': userApellido,
      'userEmail': userEmail,
      'slotGarageId': slotGarageId,
    };
  }

  Ticket copyWith({
    String? uid,
    String? vehicleId,
    String? userId,
    String? guestId,
    String? slotId,
    DateTime? ingreso,
    DateTime? egreso,
    double? precioFinal,
    String? vehiclePlate,
    String? vehicleTipo,
    String? userNombre,
    String? userApellido,
    String? userEmail,
    String? slotGarageId,
  }) =>
      Ticket(
        uid: uid ?? this.uid,
        vehicleId: vehicleId ?? this.vehicleId,
        userId: userId ?? this.userId,
        guestId: guestId ?? this.guestId,
        slotId: slotId ?? this.slotId,
        ingreso: ingreso ?? this.ingreso,
        egreso: egreso ?? this.egreso,
        precioFinal: precioFinal ?? this.precioFinal,
        vehiclePlate: vehiclePlate ?? this.vehiclePlate,
        vehicleTipo: vehicleTipo ?? this.vehicleTipo,
        userNombre: userNombre ?? this.userNombre,
        userApellido: userApellido ?? this.userApellido,
        userEmail: userEmail ?? this.userEmail,
        slotGarageId: slotGarageId ?? this.slotGarageId,
      );

  /// 🔹 Información mínima completa
  bool informacionMinima() {
    return slotId != null &&
           vehicleId != null &&
           vehiclePlate != null && vehiclePlate!.isNotEmpty &&
           slotGarageId != null && slotGarageId!.isNotEmpty &&
           ingreso != null;
  }

  @override
  String toString() {
    return 'Ticket(uid: $uid, vehicleId: $vehicleId, userId: $userId, guestId: $guestId, slotId: $slotId, ingreso: $ingreso, egreso: $egreso, precioFinal: $precioFinal, vehiclePlate: $vehiclePlate, vehicleTipo: $vehicleTipo, userNombre: $userNombre, userApellido: $userApellido, userEmail: $userEmail, slotGarageId: $slotGarageId)';
  }

}
