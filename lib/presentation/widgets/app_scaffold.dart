import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  /// Widget inferior del AppBar (por ej., TabBar)
  final PreferredSizeWidget? bottom;

  /// Mostrar/ocultar Drawer (hamburguesa). Por defecto: true.
  final bool withDrawer;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.withDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ❗️Drawer habilita automáticamente el ícono “hamburguesa” en el AppBar
      drawer: withDrawer ? const AppDrawer() : null,

      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: actions,
        elevation: 0,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: ScrollConfiguration(
        behavior: const _NoGlowScroll(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960), // ancho cómodo en web
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // sin glow
  }
}
