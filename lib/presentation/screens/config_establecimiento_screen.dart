import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

import 'package:tp3_v2/data/slot_service.dart';

class ConfigEstablecimientoScreen extends StatefulWidget {
  const ConfigEstablecimientoScreen({super.key});

  @override
  State<ConfigEstablecimientoScreen> createState() => _ConfigEstablecimientoScreenState();
}

class _ConfigEstablecimientoScreenState extends State<ConfigEstablecimientoScreen> {
  final _tarifaCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  bool _saving = false;
  int _currentCount = 0;

  final _slotService = SlotService();

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    // Tu base mezcla "role" y "roleIds"; mantenemos compatibilidad básica:
    final role = (data['role'] ?? '') as String;
    final roles = ((data['roleIds'] ?? []) as List).map((e) => e.toString()).toList();
    return role == 'admin' || roles.contains('admin');
  }

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final c = await _slotService.countSlots();
      if (mounted) setState(() => _currentCount = c);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tarifaCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  double _parseMoney(String v) {
    final normalized = v.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('config').doc('settings');

    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AppScaffold(
            title: 'Configuración',
            body: Center(child: CircularProgressIndicator()),
          );
        }
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
              final targetSlots = (data['targetSlots'] ?? _currentCount) as int;

              if (_tarifaCtrl.text.isEmpty && !_saving) {
                _tarifaCtrl.text = tarifa.toStringAsFixed(2);
              }
              if (_targetCtrl.text.isEmpty && !_saving) {
                _targetCtrl.text = targetSlots.toString();
              }

              final desired = int.tryParse(_targetCtrl.text) ?? _currentCount;
              final delta = desired - _currentCount;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    // ================== TARIFA ==================
                    const Text('Tarifa por hora'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tarifaCtrl,
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
                              final val = _parseMoney(_tarifaCtrl.text);
                              if (val <= 0) {
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
                      label: Text(_saving ? 'Guardando...' : 'Guardar tarifa'),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ================== SLOTS ==================
                    Row(
                      children: [
                        const Icon(Icons.local_parking),
                        const SizedBox(width: 8),
                        Text('Lugares actuales: $_currentCount',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Cantidad total de lugares deseada'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 50',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      delta >= 0
                          ? 'Se crearán $delta lugares nuevos (no se borran existentes).'
                          : 'El nuevo total es menor que el actual. No se borran lugares automáticamente.',
                      style: TextStyle(
                        color: delta >= 0 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Aplicar cantidad (crear faltantes)'),
                      onPressed: () async {
                        final desiredTotal = int.tryParse(_targetCtrl.text);
                        if (desiredTotal == null || desiredTotal < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Número inválido')),
                          );
                          return;
                        }

                        setState(() => _saving = true);
                        try {
                          // Guarda el target en el mismo doc de config
                          await doc.set({'targetSlots': desiredTotal}, SetOptions(merge: true));
                          // Genera los faltantes
                          final created = await _slotService.createMissingSlotsToReach(desiredTotal);
                          await _loadCount(); // refresca la cuenta actual
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lugares nuevos creados: $created')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error creando lugares: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Notas:\n'
                      '• Solo se crean los lugares faltantes hasta el total deseado.\n'
                      '• No se borra ni modifica nada existente.\n'
                      '• Los nuevos lugares nacen con vehicleId = null (disponibles).',
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
