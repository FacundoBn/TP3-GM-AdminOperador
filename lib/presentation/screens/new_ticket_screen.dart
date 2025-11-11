// lib/presentation/screens/new_ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tp3_v2/domain/logic/new_ticket_notifier.dart';
import 'package:tp3_v2/presentation/widgets/app_scaffold.dart';
import 'package:tp3_v2/presentation/widgets/assign_driver.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  final String plate;
  const NewTicketScreen({super.key, required this.plate});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  bool assignUser = false;
  bool _searching = false;
  bool _confirming = false;

  // === agregado desde la feature: auto iniciar la búsqueda al entrar ===
  Future<void> _initTicket() async {
    try {
      await ref
          .read(newTicketNotifierProvider.notifier)
          .startNewTicket(plate: widget.plate, context: context);
    } catch (e, st) {
      debugPrint('Error al iniciar ticket: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar ticket: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Ejecuta la búsqueda una vez montada la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTicket());
  }
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(newTicketNotifierProvider);
    final theme = Theme.of(context);
    final canConfirm = ticketState?.informacionMinima() ?? false;

    return AppScaffold(
      title: 'Nuevo Ticket',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _SectionCard(
                icon: Icons.directions_car,
                title: 'Patente',
                trailing: FilledButton.icon(
                  onPressed: _searching
                      ? null
                      : () async {
                          setState(() => _searching = true);
                          try {
                            await ref
                                .read(newTicketNotifierProvider.notifier)
                                .startNewTicket(plate: widget.plate, context: context);
                          } catch (e, st) {
                            debugPrint('Error al iniciar ticket: $e\n$st');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al iniciar ticket: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _searching = false);
                          }
                        },
                  icon: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_searching ? 'Buscando...' : 'BUSCAR'),
                ),
                child: SelectableText(
                  widget.plate,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (ticketState?.vehicleId != null)
                _SectionCard(
                  icon: Icons.local_taxi,
                  title: 'Vehículo detectado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KV('Tipo', ticketState!.vehicleTipo ?? '-'),
                      const SizedBox(height: 6),
                      _KV('ID Vehículo', ticketState.vehicleId ?? '-'),
                      const SizedBox(height: 12),
                      if (ticketState.userId == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => assignUser = !assignUser),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: Text(assignUser
                                ? 'Ocultar asignación'
                                : 'Asignar usuario'),
                          ),
                        ),
                    ],
                  ),
                )
              else
                _SectionCard(
                  icon: Icons.help_outline,
                  title: 'Vehículo no registrado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No se encontró un vehículo con esta patente.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _KV('Patente', ticketState?.vehiclePlate ?? widget.plate),
                      const SizedBox(height: 12),
                      Text(
                        'Seleccioná el tipo de vehículo:',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tipo in ['auto', 'moto', 'camioneta'])
                            ChoiceChip(
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(tipo),
                              ),
                              avatar: Icon(
                                tipo == 'auto'
                                    ? Icons.directions_car
                                    : tipo == 'moto'
                                        ? Icons.two_wheeler
                                        : Icons.local_shipping,
                                size: 18,
                              ),
                              selected: ticketState?.vehicleTipo == tipo,
                              onSelected: (v) async {
                                if (!v) return;
                                try {
                                  await ref
                                      .read(newTicketNotifierProvider.notifier)
                                      .registerNewVehicle(tipo);
                                } catch (e, st) {
                                  debugPrint(
                                      'Error al registrar vehículo: $e\n$st');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error al registrar vehículo: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              if (assignUser && ticketState != null)
                _SectionCard(
                  icon: Icons.person_search,
                  title: 'Asignar usuario al vehículo',
                  child: const AssignDriverSection(),
                ),

              const SizedBox(height: 12),

              if (ticketState?.userId != null)
                _SectionCard(
                  icon: Icons.person,
                  title: 'Usuario asociado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KV(
                        'Nombre',
                        '${ticketState!.userNombre ?? "-"} '
                        '${ticketState.userApellido ?? "-"}',
                      ),
                      const SizedBox(height: 6),
                      _KV('Email', ticketState.userEmail ?? '-'),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: !canConfirm || _confirming
                          ? null
                          : () async {
                              setState(() => _confirming = true);
                              try {
                                await ref
                                    .read(newTicketNotifierProvider.notifier)
                                    .assignSlot();

                                await ref
                                    .read(newTicketNotifierProvider.notifier)
                                    .confirmIngreso();

                                if (!mounted) return;
                                ref
                                    .read(newTicketNotifierProvider.notifier)
                                    .clear();
                                context.go('/home');
                              } catch (e, st) {
                                debugPrint(
                                    'Error al confirmar ticket: $e\n$st');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error al confirmar ticket: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _confirming = false);
                                }
                              }
                            },
                      icon: _confirming
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                          _confirming ? 'Confirmando...' : 'Confirmar Ingreso'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!canConfirm)
                Text(
                  'Completá los datos mínimos para habilitar el ingreso.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                  child:
                      Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            k,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(v, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
