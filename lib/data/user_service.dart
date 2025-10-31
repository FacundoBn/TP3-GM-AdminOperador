
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/domain/models/user_model.dart';

class UserService{

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<UserModel?> currentUser (String uid) {
  return _firestore.collection('users').doc(uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  });
}

Future<void> addUser(UserModel user) async {
    // Guarda en Firestore
    final docRef = await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .set(user.toFirestore());

  }

Future<void> updateUser(UserModel user) async {
  if (user.uid.isEmpty) throw Exception('No se puede actualizar sin uid');
  await _firestore
      .collection('users')
      .doc(user.uid)
      .update(user.toFirestore()); // <-- solo manda campos editables
}

  Future<UserModel?> findByUserId(String userId) async {
  try {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  } catch (e) {
    debugPrint('Error findByUserId: $e');
    return null;
  }
}

}