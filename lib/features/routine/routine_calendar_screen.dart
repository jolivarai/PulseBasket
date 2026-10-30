import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/models/routine_day.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'day_detail_screen.dart';
import 'edit_day_screen.dart';

/// Calendario semanal editable.
class RoutineCalendarScreen extends ConsumerWidget {
  const RoutineCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<RoutineDay>> week = ref.watch(weekPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutina semanal'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => ref.invalidate(weekPlanProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: week.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'No se pudo cargar el plan',
          subtitle: '$e',
        ),
        data: (List<RoutineDay> days) {
          final int today = DateTime.now().weekday;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Text(
                'Plan de 30 días · nivel intermedio · solo colchoneta',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _WeekStrip(days: days, today: today),
              const SizedBox(height: 18),
              for (final RoutineDay day in days) ...[
                _DayCard(day: day, isToday: day.weekday == today),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Toca el lápiz de cualquier día para cambiar ejercicios, '
                        'series, repeticiones o distancia.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Cómo personalizar el plan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.today});

  final List<RoutineDay> days;
  final int today;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final RoutineDay day in days)
          Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.weekday == today
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                alignment: Alignment.center,
                child: Text(
                  day.weekdayName.substring(0, 1),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: day.weekday == today
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                day.isRestDay ? '—' : day.type.emoji,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.isToday});

  final RoutineDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int strengthMinutes = day.estimatedStrengthMinutes;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isToday
          ? theme.colorScheme.primaryContainer.withOpacity(0.45)
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isToday ? theme.colorScheme.primary : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DayDetailScreen(weekday: day.weekday),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Text(day.type.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          day.weekdayName.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.1,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Text(
                            'HOY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (day.hasDistance) Fmt.distance(day.targetDistanceMeters),
                        if (day.exercises.isNotEmpty) '${day.exercises.length} ejercicios',
                        if (strengthMinutes > 0) '~$strengthMinutes min',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar día',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditDayScreen(weekday: day.weekday),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
