
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tp3_v2/domain/models/user_model.dart';

class UserService{

Stream<UserModel?> currentUser (String uid) {
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  });
}

Future<void> addUser(UserModel user) async {
    // Guarda en Firestore
    final docRef = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .set(user.toFirestore());
        
  }

Future<void> updateUser(UserModel user) async {
  if (user.uid.isEmpty) throw Exception('No se puede actualizar sin uid');
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update(user.toFirestore()); // <-- solo manda campos editables
}

}