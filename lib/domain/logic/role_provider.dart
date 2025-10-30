import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final currentUserRolesProvider = StreamProvider<List<String>>((ref) {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(u.uid)
      .snapshots()
      .map((s) {
        if (!s.exists) return <String>[];
        final data = s.data() as Map<String, dynamic>;
        final raw = (data['roleIds'] as List?) ?? const [];
        return raw.map((e) => e.toString()).toList();
      });
});

final isAdminProvider = Provider<bool>((ref) {
  final roles = ref.watch(currentUserRolesProvider).maybeWhen(
    data: (r) => r,
    orElse: () => <String>[],
  );
  return roles.contains('admin');
});
