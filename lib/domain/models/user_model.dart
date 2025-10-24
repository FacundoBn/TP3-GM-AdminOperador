import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;          // Siempre igual al uid de FirebaseAuth
  final String email;        // Desde FirebaseAuth.user.email
  final String nombre;       // Editable por el usuario
  final String apellido;     // Editable
  final String? cuit;        // Nullable, puede completarse luego
  final String userName;     // Alias o nombre visible
  final DateTime createdAt;  // Fecha de alta en Firestore

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.userName,
    this.cuit,
    required this.createdAt,
  });

  /// 🔹 Constructor desde Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      userName: data['userName'] ?? '',
      cuit: data['cuit'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// 🔹 Serialización a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'userName': userName,
      if (cuit != null) 'cuit': cuit,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 🔹 Factory inicial mínimo (post signup)
  factory UserModel.initialFromAuth({
    required String uid,
    required String email,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      nombre: '',
      apellido: '',
      userName: '',
      createdAt: DateTime.now(),
    );
  }

  UserModel copyWith({
  String? nombre,
  String? apellido,
  String? userName,
  String? cuit,
}) =>
    UserModel(
      uid: uid,
      email: email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      userName: userName ?? this.userName,
      cuit: cuit ?? this.cuit,
      createdAt: createdAt,
    );
}
