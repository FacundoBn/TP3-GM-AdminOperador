import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

/// RRHH: solo para ADMIN. Permite asignar rol 'admin' u 'operador' a usuarios existentes.
/// Los usuarios se leen de la colección `users/{uid}` con campos: email, displayName, role.
class RrhhScreen extends StatelessWidget {
  const RrhhScreen({super.key});

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return (data['role'] ?? '') == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const AppScaffold(
            title: 'RRHH',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data != true) {
          return const AppScaffold(
            title: 'RRHH',
            body: Center(child: Text('Acceso restringido a administradores')),
          );
        }

        final usersQuery = FirebaseFirestore.instance.collection('users');

        return AppScaffold(
          title: 'RRHH',
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: usersQuery.snapshots(),
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = s.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No hay usuarios registrados'));
              }

              docs.sort((a, b) {
                final ra = (a.data()['role'] ?? '') as String;
                final rb = (b.data()['role'] ?? '') as String;
                if (ra == rb) {
                  final ea = (a.data()['email'] ?? '') as String;
                  final eb = (b.data()['email'] ?? '') as String;
                  return ea.compareTo(eb);
                }
                return ra.compareTo(rb);
              });

              final myUid = FirebaseAuth.instance.currentUser?.uid;

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final uid = docs[i].id;
                  final name = (d['displayName'] ?? '') as String;
                  final email = (d['email'] ?? '') as String;
                  final role = (d['role'] ?? 'operador') as String;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (name.isNotEmpty ? name[0] : (email.isNotEmpty ? email[0] : '?')).toUpperCase(),
                      ),
                    ),
                    title: Text(name.isNotEmpty ? name : email),
                    subtitle: Text('Rol: $role'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'make_admin') {
                          await _setRole(uid, 'admin');
                        } else if (value == 'make_operador') {
                          await _setRole(uid, 'operador');
                        }
                      },
                      itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                        const PopupMenuItem(
                          value: 'make_operador',
                          child: Text('Asignar Operador'),
                        ),
                        if (uid != myUid) // no quitarte tu propio admin
                          const PopupMenuItem(
                            value: 'make_admin',
                            child: Text('Asignar Admin'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _setRole(String uid, String role) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    await doc.set({'role': role}, SetOptions(merge: true));
  }
}
