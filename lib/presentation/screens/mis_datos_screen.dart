import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/domain/logic/current_user_provider.dart';
import 'package:tp3_v2/domain/models/user_model.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

/// Pantalla "Mis datos" – escucha currentUserProvider y permite edición.
class MisDatosScreen extends ConsumerStatefulWidget {
  const MisDatosScreen({super.key});

  @override
  ConsumerState<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends ConsumerState<MisDatosScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _cuitCtrl;
  late final TextEditingController _userNameCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _apellidoCtrl = TextEditingController();
    _cuitCtrl = TextEditingController();
    _userNameCtrl = TextEditingController();  
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cuitCtrl.dispose();
    _userNameCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final nuevo = user.copyWith(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      cuit: _cuitCtrl.text.trim().isEmpty ? null : _cuitCtrl.text.trim(),
      userName: _userNameCtrl.text.trim(),
    );

    // Diálogo de confirmación
    final bool? confirma = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(user: nuevo),
    );

    if (confirma == true) {
      try {
        await ref.read(userServiceProvider).updateUser(nuevo);
         ref.invalidate(currentUserProvider);
        if (mounted) context.go('/home'); // cierra pantalla
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(currentUserProvider);
        return asyncUser.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (user){ 
          if (user == null) {
            return const Scaffold(body: Center(child: Text('No hay usuario')));
          }
      _nombreCtrl.text= user.nombre;
      _apellidoCtrl.text= user.apellido;
      _cuitCtrl.text= user.cuit?? '';
      _userNameCtrl.text= user.userName;

        return AppScaffold(
          title: 'Mis datos',
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Email solo lectura
                TextField(
                  controller: TextEditingController(text: user.email),
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                // Nombre
                TextField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    hintText: user.nombre.isEmpty ? 'SIN DATOS' : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Apellido
                TextField(
                  controller: _apellidoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    hintText: user.apellido.isEmpty ? 'SIN DATOS' : null,
                  ),
                ),
                const SizedBox(height: 12),
                // CUIT
                TextField(
                  controller: _cuitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CUIT',
                    hintText: user.cuit?.isEmpty ?? true ? 'SIN DATOS' : null,
                  ),
                ),
                const SizedBox(height: 12),
                // UserName
                TextField(
                  controller: _userNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    hintText: user.userName.isEmpty ? 'SIN DATOS' : null,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

/// Diálogo de confirmación con todos los camios visibles
class _ConfirmDialog extends StatelessWidget {
  final UserModel user;
  const _ConfirmDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar cambios'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row('Nombre', user.nombre),
            _Row('Apellido', user.apellido),
            _Row('CUIT', user.cuit ?? 'Sin dato'),
            _Row('Usuario', user.userName),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
      ],
    );
  }

  Widget _Row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$label: ${value.isEmpty ? 'Sin datos' : value}'),
      );
}