import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/formatters.dart';
import '../../data/models/routine_day.dart';
import '../../data/providers.dart';
import '../../services/tracking_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/route_painter.dart';

/// Pantalla de grabación. Es la única que escribe en la base de datos
/// mientras hay un entreno activo.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  WorkoutType _type = WorkoutType.run;
  double _target = 4000;
  bool _typeInitialized = false;

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TrackingState state = ref.watch(trackingProvider);
    final TrackingController controller = ref.read(trackingProvider.notifier);
    final ThemeData theme = Theme.of(context);

    // El primer día que exista plan, se proponen disciplina y distancia.
    final RoutineDay? plan = ref.watch(todayPlanProvider).valueOrNull;
    if (!_typeInitialized && plan != null && plan.hasDistance) {
      _typeInitialized = true;
      _type = plan.type;
      _target = plan.targetDistanceMeters;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenar'),
        actions: [
          if (state.isActive)
            IconButton(
              tooltip: 'Descartar sesión',
              onPressed: () => _confirmDiscard(context, controller),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MessageBanner(
                message: state.message!,
                onClose: controller.clearMessage,
              ),
            ),
          if (state.status == TrackingStatus.idle)
            _buildSetup(theme, controller)
          else
            _buildLive(theme, state, controller),
        ],
      ),
    );
  }

  // ─────────────────────────────────────── Configuración previa ──

  Widget _buildSetup(ThemeData theme, TrackingController controller) {
    return Column(
      children: [
        SectionCard(
          title: 'Nuevo entreno',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El GPS funciona sin datos móviles. Puedes bloquear la pantalla: '
                'el recorrido y los botones de pausa siguen en la pantalla de bloqueo.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SegmentedButton<WorkoutType>(
                segments: const [
                  ButtonSegment(
                    value: WorkoutType.run,
                    label: Text('Correr'),
                    icon: Icon(Icons.directions_run),
                  ),
                  ButtonSegment(
                    value: WorkoutType.bike,
                    label: Text('Bici'),
                    icon: Icon(Icons.directions_bike),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<WorkoutType> value) {
                  setState(() => _type = value.first);
                },
              ),
              const SizedBox(height: 16),
              Text('Distancia objetivo', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final double km in const [0, 4, 12, 20])
                    ChoiceChip(
                      label: Text(km == 0 ? 'Libre' : '${km.toInt()} km'),
                      selected: _target == km * 1000,
                      onSelected: (_) => setState(() => _target = km * 1000),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            await WakelockPlus.enable();
            await controller.start(type: _type, targetMeters: _target);
          },
          icon: const Icon(Icons.gps_fixed),
          label: const Text('Iniciar entrenamiento'),
        ),
        const SizedBox(height: 12),
        Text(
          'La app pedirá ubicación "Siempre". En Android verás una notificación '
          'fija; en iPhone, una Live Activity en la pantalla de bloqueo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────── Sesión en vivo ──

  Widget _buildLive(ThemeData theme, TrackingState state, TrackingController controller) {
    final bool paused = state.status == TrackingStatus.paused;
    final bool finished = state.status == TrackingStatus.finished;
    final bool acquiring = state.status == TrackingStatus.acquiring;

    return Column(
      children: [
        SectionCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (finished)
                    StatusPill(
                      label: 'Finalizado',
                      color: theme.colorScheme.primary,
                      icon: Icons.flag,
                    )
                  else if (acquiring)
                    const StatusPill(
                      label: 'Buscando GPS',
                      color: Colors.orange,
                      icon: Icons.gps_not_fixed,
                    )
                  else if (paused)
                    const StatusPill(
                      label: 'Pausado',
                      color: Colors.orange,
                      icon: Icons.pause,
                    )
                  else
                    const StatusPill(
                      label: 'Grabando',
                      color: Color(0xFF2F9E44),
                      icon: Icons.circle,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                Fmt.distance(state.distanceMeters),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'recorridos',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.progress == 0 ? null : state.progress,
                  minHeight: 7,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatTile(
                    value: state.paceLabel,
                    label: state.type == WorkoutType.bike ? 'Velocidad' : 'Ritmo',
                    icon: Icons.speed,
                  ),
                  StatTile(
                    value: Fmt.duration(state.elapsed),
                    label: 'Tiempo',
                    icon: Icons.timer_outlined,
                  ),
                  StatTile(
                    value: state.targetMeters > 0
                        ? Fmt.distance(state.remainingMeters)
                        : '—',
                    label: 'Restante',
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Traza GPS offline
        SectionCard(
          title: 'Recorrido (GPS)',
          trailing: Text(
            '±${state.accuracy.toStringAsFixed(0)} m',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          child: SizedBox(
            height: 210,
            width: double.infinity,
            child: state.route.length < 2
                ? Center(
                    child: Text(
                      acquiring
                          ? 'Esperando señal del GPS…'
                          : 'Aún no hay puntos suficientes',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : CustomPaint(
                    painter: RoutePainter(
                      points: state.route,
                      color: theme.colorScheme.primary,
                      gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        if (!finished) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: paused ? null : controller.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: paused ? controller.resume : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reanudar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _confirmFinish(context, controller),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Finalizar y guardar'),
          ),
        ] else
          SectionCard(
            title: 'Resumen',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatTile(value: Fmt.distance(state.distanceMeters), label: 'Distancia'),
                    StatTile(value: Fmt.duration(state.elapsed), label: 'Tiempo'),
                    StatTile(value: Fmt.pace(state.avgSpeed), label: 'Ritmo medio'),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    controller.reset();
                    ref.invalidate(historyProvider);
                    ref.invalidate(weeklySpeedProvider);
                  },
                  child: const Text('Listo'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmFinish(BuildContext context, TrackingController c) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('¿Finalizar entreno?'),
        content: const Text('Se guardará en el historial y se cerrará la pantalla de bloqueo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (ok ?? false) {
      await WakelockPlus.disable();
      await c.finish();
    }
  }

  Future<void> _confirmDiscard(BuildContext context, TrackingController c) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Descartar sesión'),
        content: const Text('Se borrarán los datos de este entreno. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await WakelockPlus.disable();
      await c.discard();
    }
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18)),
        ],
      ),
    );
  }
}
