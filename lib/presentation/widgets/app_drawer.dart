import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tp3_v2/domain/logic/role_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

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
            // Podés agregar otras reglas según 'operador' o 'cliente'
            final canSeeRrhh = isAdmin;                  // ocultar si NO es admin
            final canSeeConfigEst = isAdmin;             // ocultar si NO es admin

            return ListView(
              children: [
                const DrawerHeader(
                  child: Text('Garage Manager', style: TextStyle(fontSize: 20)),
                ),

                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Inicio'),
                  onTap: () => context.go('/home'),
                ),

                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Escanear'),
                  onTap: () => context.go('/scan'),
                ),

                if (canSeeRrhh) ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('RRHH'),
                  onTap: () => context.go('/rrhh'),
                ),

                if (canSeeConfigEst) ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Config Estacionamiento'),
                  onTap: () => context.go('/config-est'),
                ),

                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial'),
                  onTap: () => context.go('/historial'),
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
