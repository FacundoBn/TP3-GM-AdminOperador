import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Stream del rol del usuario actual: 'admin' | 'operador' | null
final roleProvider = StreamProvider<String?>((ref) {
  final current = FirebaseAuth.instance.currentUser;
  if (current == null) {
    return const Stream.empty();
  }
  final doc = FirebaseFirestore.instance.collection('users').doc(current.uid);
  return doc.snapshots().map((s) {
    if (!s.exists) return null;
    final data = s.data() as Map<String, dynamic>;
    final role = data['role'] as String?;
    return role;
  });
});
