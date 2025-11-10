import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@demo.com');
  final _passCtrl = TextEditingController(text: '');
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Error desconocido';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al ingresar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold( // ← login sin drawer
      body: Stack(
        children: [
          // Fondo con degradé suave + “ondas”
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(.10),
                    theme.colorScheme.primary.withOpacity(.03),
                  ],
                ),
              ),
            ),
          ),
          // Marca principal
          Positioned(
            top: 48,
            left: 24,
            right: 24,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                  child: Icon(Icons.local_parking, size: 28, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Garage Manager',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    Text(
                      'Accedé para gestionar tu estacionamiento',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido centrado
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícono contextual grande
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(.10),
                        child: Icon(Icons.local_parking_rounded,
                            size: 30, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text('Login',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'usuario@dominio.com',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Clave',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresá tu clave';
                                if (v.length < 5) return 'Mínimo 5 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                child: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Ingresar'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _loading ? null : () => context.go('/register'),
                              child: const Text('Crear cuenta nueva'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pie con mini ilustración (opcional simple)
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_parking, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Estacionamiento seguro y simple',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
