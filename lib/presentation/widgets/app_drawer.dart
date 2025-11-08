import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tp3_v2/domain/logic/role_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _nav(BuildContext context, String path) {
    // cierra el drawer antes de navegar
    Navigator.of(context).pop();
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(currentUserRolesProvider);

    return Drawer(
      child: SafeArea(
        child: rolesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (roles) {
            final isAdmin = roles.contains('admin');
            final canSeeRrhh = isAdmin;
            final canSeeConfigEst = isAdmin;

            return ListView(
              children: [
                const DrawerHeader(
                  child: Text('Garage Manager', style: TextStyle(fontSize: 20)),
                ),

                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Inicio'),
                  onTap: () => _nav(context, '/home'),
                ),

                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Escanear'),
                  onTap: () => _nav(context, '/scan'),
                ),

                if (canSeeRrhh) ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('RRHH'),
                  onTap: () => _nav(context, '/rrhh'),
                ),

                if (canSeeConfigEst) ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Config Estacionamiento'),
                  onTap: () => _nav(context, '/config'), // ruta que definiste
                ),

                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial'),
                  onTap: () => _nav(context, '/historial'),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Salir'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
