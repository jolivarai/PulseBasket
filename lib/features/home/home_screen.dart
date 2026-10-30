import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../data/models/routine_day.dart';
import '../../data/models/workout_session.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../routine/day_detail_screen.dart';
import '../tracking/tracking_screen.dart';

/// Pantalla de inicio: qué toca hoy, cómo va la semana y acceso rápido.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<RoutineDay?> today = ref.watch(todayPlanProvider);
    final AsyncValue<List<WorkoutSession>> history = ref.watch(historyProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Text(
              'Pulso Basket',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now()),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),

            // ── Plan de hoy ────────────────────────────────────────────
            today.when(
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, _) => SectionCard(
                child: Text('No se pudo cargar el plan: $e'),
              ),
              data: (RoutineDay? day) {
                if (day == null) {
                  return const SectionCard(child: Text('Sin plan para hoy'));
                }
                return _TodayCard(day: day);
              },
            ),

            const SizedBox(height: 16),

            // ── Semana ─────────────────────────────────────────────────
            history.when(
              loading: () => const SizedBox.shrink(),
              error: (Object e, _) => const SizedBox.shrink(),
              data: (List<WorkoutSession> sessions) =>
                  _WeekOverview(sessions: sessions),
            ),

            const SizedBox(height: 16),

            // ── Funciona sin datos ─────────────────────────────────────
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi_off, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Funciona sin datos móviles',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El GPS del teléfono no necesita internet. Puedes bloquear '
                          'la pantalla: la distancia, el ritmo y los botones de pausa '
                          'siguen visibles en la pantalla de bloqueo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.day});

  final RoutineDay day;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.78),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOY · ${day.weekdayName.toUpperCase()}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.85),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            [
              if (day.hasDistance) Fmt.distance(day.targetDistanceMeters),
              if (day.exercises.isNotEmpty) '${day.exercises.length} ejercicios',
              if (day.estimatedStrengthMinutes > 0)
                '~${day.estimatedStrengthMinutes} min de fuerza',
              if (day.isRestDay) 'recuperación',
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.92),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TrackingScreen()),
                  ),
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Entrenar'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Ver rutina',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DayDetailScreen(weekday: day.weekday),
                  ),
                ),
                icon: const Icon(Icons.list_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekOverview extends StatelessWidget {
  const _WeekOverview({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final List<WorkoutSession> week = sessions
        .where((WorkoutSession s) => s.startedAt.isAfter(monday))
        .toList();
    final double km =
        week.fold<double>(0, (double a, WorkoutSession s) => a + s.distanceMeters) / 1000;

    final Set<int> trainedDays = week
        .map((WorkoutSession s) => s.startedAt.weekday)
        .toSet();

    return SectionCard(
      title: 'Tu semana',
      trailing: Text(
        '${trainedDays.length}/6 días',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatTile(value: km.toStringAsFixed(1), label: 'km totales'),
              StatTile(value: '${week.length}', label: 'sesiones'),
              StatTile(
                value: week.isEmpty
                    ? '—'
                    : Fmt.pace(
                        week.fold<double>(0, (double a, WorkoutSession s) => a + s.avgSpeed) /
                            week.length,
                      ),
                label: 'ritmo medio',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int d = 1; d <= 7; d++)
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trainedDays.contains(d)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        trainedDays.contains(d) ? Icons.check : Icons.remove,
                        size: 15,
                        color: trainedDays.contains(d)
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      const ['L', 'M', 'X', 'J', 'V', 'S', 'D'][d - 1],
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
