import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  // 🔧 NUEVO: soporta TabBar en el AppBar
  final PreferredSizeWidget? bottom;

  // Extras opcionales (por si alguna screen los usa)
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? endDrawer;
  final Widget? drawer;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.endDrawer,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: bottom, // ← ahora sí acepta TabBar/PreferredSizeWidget
      ),
      // si no te pasan un drawer, usamos el condicional por roles
      drawer: drawer ?? const AppDrawer(),
      endDrawer: endDrawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
