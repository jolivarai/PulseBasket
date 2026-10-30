import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          SectionCard(
            title: 'Permisos necesarios',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _permission(
                  theme,
                  'Ubicación "Siempre"',
                  'Sin este permiso el sistema corta el GPS al bloquear la pantalla.',
                ),
                const SizedBox(height: 10),
                _permission(
                  theme,
                  'Actividad física (iOS)',
                  'Mejora la precisión al correr y evita que el sistema pause la grabación.',
                ),
                const SizedBox(height: 10),
                _permission(
                  theme,
                  'Notificaciones (Android)',
                  'Son la pantalla de bloqueo: muestran distancia, ritmo y los botones Pausar/Reanudar.',
                ),
                const SizedBox(height: 10),
                _permission(
                  theme,
                  'Batería sin restricciones',
                  'En Xiaomi, Samsung u Oppo: Ajustes > Batería > Sin restricciones para Pulso Basket.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Plan',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Restaurar plan original'),
                  subtitle: const Text('Vuelve a la rutina semanal de fábrica'),
                  onTap: () => _confirmReset(context, ref),
                ),
                const Divider(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
                  title: Text(
                    'Borrar historial',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Elimina todos los recorridos guardados'),
                  onTap: () => _confirmWipe(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Sobre la app',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pulso Basket · versión 1.0.0', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  '100 % offline. El historial se guarda en SQLite dentro del '
                  'teléfono y nunca se envía a ningún servidor.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Referencias metodológicas: Dr. Stuart McGill (estabilidad '
                  'espinal), Mike Boyle (fuerza funcional), EXOS / Mark Verstegen '
                  '(movement prep), Peak Performance Project (Dr. Marcus Elliott) '
                  'y Tim Grover (Attack Athletics). Son atribuciones de escuela, '
                  'no afiliaciones ni programas oficiales.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta app no sustituye el criterio de un entrenador ni de un '
                  'médico. Si tienes dolor, lesión o patología, consulta antes '
                  'de empezar el plan.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permission(ThemeData theme, String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                detail,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('¿Restaurar el plan?'),
        content: const Text('Se perderán los cambios que hayas hecho en el calendario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await ref.read(routineRepositoryProvider).resetToSeed();
    ref.invalidate(weekPlanProvider);
    ref.invalidate(todayPlanProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan original restaurado')),
    );
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('¿Borrar todo el historial?'),
        content: const Text(
          'Se eliminarán todas las sesiones y sus puntos GPS. Esta acción no se '
          'puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await ref.read(sessionRepositoryProvider).deleteAll();
    ref.invalidate(historyProvider);
    ref.invalidate(weeklySpeedProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial eliminado')),
    );
  }
}
