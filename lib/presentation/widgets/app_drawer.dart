import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tp3_v2/domain/logic/role_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _nav(BuildContext context, String path) {
    Navigator.of(context).pop(); // cierra drawer antes de navegar
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(currentUserRolesProvider);
    final theme = Theme.of(context);

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
              padding: EdgeInsets.zero,
              children: [
                // ===== Header renovado =====
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                        child: Icon(Icons.local_parking, size: 28, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Garage Manager',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: .2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Panel',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _Item(
                  icon: Icons.home,
                  text: 'Inicio',
                  onTap: () => _nav(context, '/home'),
                ),
                _Item(
                  icon: Icons.qr_code_scanner,
                  text: 'Escanear',
                  onTap: () => _nav(context, '/scan'),
                ),

                if (canSeeRrhh)
                  _Item(
                    icon: Icons.group,
                    text: 'RRHH',
                    onTap: () => _nav(context, '/rrhh'),
                  ),

                if (canSeeConfigEst)
                  _Item(
                    icon: Icons.settings,
                    text: 'Config Estacionamiento',
                    onTap: () => _nav(context, '/config'),
                  ),

                _Item(
                  icon: Icons.history,
                  text: 'Historial',
                  onTap: () => _nav(context, '/history'),
                ),

                const Divider(height: 24),

                _Item(
                  icon: Icons.logout,
                  text: 'Salir',
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

class _Item extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _Item({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary.withOpacity(.10),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
