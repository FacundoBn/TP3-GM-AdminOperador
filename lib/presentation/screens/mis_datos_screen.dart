import 'package:flutter/material.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';

class MisDatosScreen extends StatelessWidget {
  const MisDatosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Mis datos',
      body: Center(child: Text('Aquí podrás ver/editar tus datos (próximamente)')),
    );
  }
}
