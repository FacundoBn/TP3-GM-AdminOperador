// lib/presentation/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;
  final PreferredSizeWidget? bottom; // 👈 NUEVO: para TabBar u otro widget

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = false,
    this.bottom, // 👈 NUEVO
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: bottom, // 👈 conecta el parámetro al AppBar
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
              )
            : null,
        actions: actions,
      ),
      // Con Drawer, el botón de hamburguesa aparece automáticamente
      drawer: const _MainDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _MainDrawer extends StatelessWidget {
  const _MainDrawer();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'Usuario'),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),

            // Menú principal
            _tile(context, Icons.home, 'Home', '/home'),
            _tile(context, Icons.qr_code_scanner, 'Escanear', '/scan'),
            _tile(context, Icons.history, 'Historial', '/history'),
            const Divider(),

            // Admin (ahora se muestran SIEMPRE; la validación por rol está desactivada)
            _tile(context, Icons.people_alt, 'RRHH', '/rrhh'),
            _tile(context, Icons.settings_suggest, 'Config. Establecimiento', '/config'),
            const Divider(),

            // Comunes
            _tile(context, Icons.person, 'Mis datos', '/perfil'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Salir'),
              onTap: () async {
                Navigator.of(context).pop(); // cerrar drawer
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _tile(BuildContext context, IconData icon, String text, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        Navigator.of(context).pop(); // cerrar drawer
        context.go(route);
      },
    );
  }
}
