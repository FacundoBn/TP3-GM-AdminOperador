// lib/core/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/history_screen.dart';
import '../presentation/screens/scan_screen.dart';
import '../presentation/screens/active_session_screen.dart';
import '../presentation/screens/mis_datos_screen.dart';
import '../presentation/screens/rrhh_screen.dart';
import '../presentation/screens/config_establecimiento_screen.dart';
import '../presentation/screens/ticket_receipt_screen.dart';
import '../presentation/screens/new_ticket_screen.dart'; // Asegurate que existe

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _navKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = FirebaseAuth.instance;

  return GoRouter(
    navigatorKey: _navKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      final user = auth.currentUser;
      final loggingIn =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (user == null && !loggingIn) return '/login';
      if (user != null && loggingIn) return '/home';
      return null;
    },
    routes: [
      // Públicas
      GoRoute(path: '/login',    builder: (_, __) => LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),

      // Privadas
      GoRoute(path: '/home',    builder: (_, __) => HomeScreen()),
      GoRoute(path: '/history', builder: (_, __) => HistoryScreen()),
      GoRoute(path: '/scan',    builder: (_, __) => ScanScreen()),

      // Sesión activa (editable)
      GoRoute(
        path: '/active',
        builder: (_, state) {
          final ticketId = state.extra is String ? state.extra as String : null;
          return ActiveSessionScreen(ticketId: ticketId, readOnly: false);
        },
      ),

      // Comprobante
      GoRoute(
        path: '/ticket/:id',
        builder: (_, state) =>
            TicketReceiptScreen(ticketId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/ticket',
        builder: (_, state) =>
            TicketReceiptScreen(ticketId: (state.extra as String?) ?? ''),
      ),

      // ===== NewTicket: TODAS las variantes soportadas =====
      GoRoute(
        path: '/newTicket/:plate',
        builder: (_, state) =>
            NewTicketScreen(plate: state.pathParameters['plate'] ?? ''),
      ),
      GoRoute(
        path: '/newTicket',
        builder: (_, state) =>
            NewTicketScreen(plate: (state.extra as String?) ?? ''),
      ),
      // Compat con código viejo
      GoRoute(
        path: '/new/:plate',
        builder: (_, state) =>
            NewTicketScreen(plate: state.pathParameters['plate'] ?? ''),
      ),
      GoRoute(
        path: '/new',
        builder: (_, state) =>
            NewTicketScreen(plate: (state.extra as String?) ?? ''),
      ),

      // Admin + Perfil
      GoRoute(path: '/rrhh',   builder: (_, __) => RrhhScreen()),
      GoRoute(path: '/config', builder: (_, __) => ConfigEstablecimientoScreen()),
      GoRoute(path: '/perfil', builder: (_, __) => MisDatosScreen()),
    ],
  );
});
