import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class RrhhScreen extends StatefulWidget {
  const RrhhScreen({super.key});

  @override
  State<RrhhScreen> createState() => _RrhhScreenState();
}

class _RrhhScreenState extends State<RrhhScreen> {
  bool _refreshing = true;
  String? _claimDump;

  @override
  void initState() {
    super.initState();
    _ensureFreshClaims();
  }

  Future<void> _ensureFreshClaims() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      final res = await u.getIdTokenResult(true); // 🔄 refresca el token/claims
      _claimDump = (res.claims ?? {}).toString();
    }
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_refreshing) {
      return const AppScaffold(
        title: 'RRHH',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'RRHH',
      actions: [
        IconButton(
          tooltip: 'Refrescar permisos',
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await _ensureFreshClaims();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Claims: $_claimDump')),
            );
          },
        ),
      ],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('email').snapshots(),
        builder: (context, s) {
          if (s.hasError) {
            // Mostramos el error real (suele ser permission-denied)
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error al listar usuarios:\n${s.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = s.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          docs.sort((a, b) {
            final ea = (a.data()['email'] ?? '') as String;
            final eb = (b.data()['email'] ?? '') as String;
            return ea.compareTo(eb);
          });

          final myUid = FirebaseAuth.instance.currentUser?.uid;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final uid = docs[i].id;
              final name = (d['displayName'] ?? d['nombre'] ?? d['userName'] ?? '') as String;
              final email = (d['email'] ?? '') as String;
              final roles = (d['roleIds'] as List<dynamic>? ?? const []).map((e) => e.toString()).toSet();

              return ListTile(
                leading: CircleAvatar(child: Text((name.isNotEmpty ? name[0] : (email.isNotEmpty ? email[0] : '?')).toUpperCase())),
                title: Text(name.isNotEmpty ? name : email),
                subtitle: Text(email),
                trailing: Text(roles.isEmpty ? '—' : roles.join(', ')),
                onTap: () async {
                  final result = await showDialog<Set<String>>(
                    context: context,
                    builder: (_) => _RolePickerDialog(initial: roles),
                  );
                  if (result == null) return;

                  // Evitar quitarte admin a vos mismo
                  if (uid == myUid && !result.contains('admin')) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No podés quitarte el rol admin a vos mismo.')),
                      );
                    }
                    return;
                  }

                  await FirebaseFirestore.instance.collection('users').doc(uid).set({
                    'roleIds': result.toList(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Roles actualizados. El usuario debe reloguear para aplicar permisos.')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RolePickerDialog extends StatefulWidget {
  const _RolePickerDialog({required this.initial});
  final Set<String> initial;

  @override
  State<_RolePickerDialog> createState() => _RolePickerDialogState();
}

class _RolePickerDialogState extends State<_RolePickerDialog> {
  late Set<String> selected;
  @override
  void initState() { super.initState(); selected = {...widget.initial}; }

  @override
  Widget build(BuildContext context) {
    const roles = ['admin', 'operador', 'cliente'];
    return AlertDialog(
      title: const Text('Asignar roles'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((r) => CheckboxListTile(
            title: Text(r[0].toUpperCase() + r.substring(1)),
            subtitle: Text(r),
            value: selected.contains(r),
            onChanged: (v) => setState(() => v! ? selected.add(r) : selected.remove(r)),
          )).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Guardar')),
      ],
    );
  }
}
