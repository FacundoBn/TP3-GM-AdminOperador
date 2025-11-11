// lib/core/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tp3_v2/presentation/screens/assign_driver_screen.dart';

// Pantallas (ajustá los imports si tu paquete no es tp3_v2)
import 'package:tp3_v2/presentation/screens/login_screen.dart';
import 'package:tp3_v2/presentation/screens/new_ticket_screen.dart';
import 'package:tp3_v2/presentation/screens/register_screen.dart';
import 'package:tp3_v2/presentation/screens/home_screen.dart';
import 'package:tp3_v2/presentation/screens/history_screen.dart';
import 'package:tp3_v2/presentation/screens/scan_screen.dart';
import 'package:tp3_v2/presentation/screens/active_session_screen.dart';
import 'package:tp3_v2/presentation/screens/mis_datos_screen.dart';
import 'package:tp3_v2/presentation/screens/rrhh_screen.dart';
import 'package:tp3_v2/presentation/screens/config_establecimiento_screen.dart';

/// Notifier para refrescar GoRouter cuando cambia el stream (ej: authStateChanges)
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

/// Exponé el router como provider para poder usarlo con Riverpod
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();

  return GoRouter(
    navigatorKey: _navKey,
    initialLocation: '/home',

    // 🔁 Re-evalúa redirect cuando cambia el estado de auth
    refreshListenable: GoRouterRefreshStream(authStream),

    // 🚪 Redirecciones básicas (sin validar roles)
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      final isAuth = user != null;

      // Si no está logueado y no va a login/register -> forzá login
      if (!isAuth && !loggingIn && !registering) return '/login';

      // Si está logueado y va a login/register -> mandalo a home
      if (isAuth && (loggingIn || registering)) return '/home';

      // 🔒 VALIDACIÓN DE ROLES — DESACTIVADA POR AHORA
      /*
      if (isAuth) {
        // Final: cuando quieras reactivar, descomentá y agregá:
        // import 'package:cloud_firestore/cloud_firestore.dart';
        final restricted = ['/rrhh', '/config'];
        // final snap = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        // final role = (snap.data()?['role'] ?? 'operador') as String;
        // if (restricted.contains(state.matchedLocation) && role != 'admin') {
        //   return '/home';
        // }
      }
      */

      return null;
    },

    routes: [
      // Públicas
      GoRoute(path: '/login',    builder: (_, __) => LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),

      // Privadas comunes
      GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/history',  builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/scan',     builder: (_, __) => const ScanScreen()),

      // Detalle / Activa (en Admin/Operador permitimos cerrar -> readOnly:false)
      GoRoute(
        path: '/active',
        builder: (_, state) {
          final ticketId = state.extra is String ? state.extra as String : null;
          return ActiveSessionScreen(ticketId: ticketId, readOnly: false);
        },
      ),

      GoRoute(
        path: '/assign',
        builder: (_, state) {
          final data = state.extra as Map<String , dynamic>;
          final vehiclePlate = data['plate'] as String;
          final ticketId = data ['id'] as String;
          debugPrint('en app_router_ vehiclePlate: $vehiclePlate - ticketId: $ticketId');
          return AssignDriverScreen(vehiclePlate: vehiclePlate, ticketId: ticketId);
        },
      ),

      GoRoute(
        path: '/newTicket',
        redirect: (context, state) {
          final plate = state.extra is String ? state.extra as String : null;
          return plate == null ? '/scan' : null;
        },
        builder: (_, state) {
          final plate = state.extra as String;
          return NewTicketScreen(plate: plate);
        },
      ),

      // Pantallas que serán “solo admin” cuando actives la validación
      GoRoute(path: '/rrhh',   builder: (_, __) => const RrhhScreen()),
      GoRoute(path: '/config', builder: (_, __) => const ConfigEstablecimientoScreen()),

      // Perfil (admin y operador)
      GoRoute(path: '/perfil', builder: (_, __) => const MisDatosScreen()),
    ],
  );
});
