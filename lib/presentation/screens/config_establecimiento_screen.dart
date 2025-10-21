import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class ConfigEstablecimientoScreen extends StatefulWidget {
  const ConfigEstablecimientoScreen({super.key});

  @override
  State<ConfigEstablecimientoScreen> createState() => _ConfigEstablecimientoScreenState();
}

class _ConfigEstablecimientoScreenState extends State<ConfigEstablecimientoScreen> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return (data['role'] ?? '') == 'admin';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('config').doc('settings');

    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const AppScaffold(
            title: 'Configuración',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data != true) {
          return const AppScaffold(
            title: 'Configuración',
            body: Center(child: Text('Acceso restringido a administradores')),
          );
        }

        return AppScaffold(
          title: 'Configuración del establecimiento',
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: doc.snapshots(),
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = s.data?.data() ?? {};
              final tarifa = (data['tarifaPorHora'] ?? 100).toDouble();

              if (_ctrl.text.isEmpty && !_saving) {
                _ctrl.text = tarifa.toStringAsFixed(2);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tarifa por hora'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                        hintText: 'Ej: 100.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              final val = double.tryParse(_ctrl.text.replaceAll(',', '.'));
                              if (val == null || val <= 0) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ingrese un valor válido')),
                                  );
                                }
                                return;
                              }
                              setState(() => _saving = true);
                              try {
                                await doc.set({'tarifaPorHora': val}, SetOptions(merge: true));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tarifa actualizada')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      icon: const Icon(Icons.save),
                      label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta tarifa se usa para calcular el precio final al cerrar un ticket. '
                      'Si querés, conectamos Active a este valor ahora mismo.',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
