import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine_day.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../tracking/tracking_screen.dart';
import 'edit_day_screen.dart';
import 'exercise_detail_screen.dart';

/// Detalle de un día con la lista de ejercicios y acceso al editor.
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.weekday});

  final int weekday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<RoutineDay>> week = ref.watch(weekPlanProvider);

    return week.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object e, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, title: 'Error', subtitle: '$e'),
      ),
      data: (List<RoutineDay> days) {
        final Iterable<RoutineDay> matches =
            days.where((RoutineDay d) => d.weekday == weekday);
        final RoutineDay? day = matches.isEmpty ? null : matches.first;
        if (day == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(icon: Icons.event_busy, title: 'Día no encontrado'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(day.weekdayName),
            actions: [
              IconButton(
                tooltip: 'Editar este día',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditDayScreen(weekday: weekday),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(day.type.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            day.title,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (day.hasDistance)
                          _Tag(
                            icon: Icons.straighten,
                            label: Fmt.distance(day.targetDistanceMeters),
                          ),
                        if (day.exercises.isNotEmpty)
                          _Tag(
                            icon: Icons.fitness_center,
                            label: '${day.exercises.length} ejercicios',
                          ),
                        if (day.estimatedStrengthMinutes > 0)
                          _Tag(
                            icon: Icons.timer_outlined,
                            label: '~${day.estimatedStrengthMinutes} min',
                          ),
                        const _Tag(icon: Icons.self_improvement, label: 'Colchoneta'),
                      ],
                    ),
                    if (day.note.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        day.note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (day.hasDistance) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TrackingScreen()),
                  ),
                  icon: const Icon(Icons.gps_fixed),
                  label: Text(
                    'Grabar ${day.type == WorkoutType.bike ? 'bicicleta' : 'carrera'} '
                    '(${Fmt.distance(day.targetDistanceMeters)})',
                  ),
                ),
              ],
              if (day.exercises.isEmpty)
                const EmptyState(
                  icon: Icons.self_improvement,
                  title: 'Día de descanso',
                  subtitle: 'Recuperación activa: camina, movilidad y duerme bien.',
                )
              else ...[
                const SizedBox(height: 20),
                Text(
                  'Rutina de fuerza',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca un ejercicio para ver la ejecución paso a paso.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < day.exercises.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExerciseTile(index: i + 1, exercise: day.exercises[i]),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.index, required this.exercise});

  final int index;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
        ),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${exercise.sets} × ${exercise.reps} · ${exercise.restSeconds}s descanso',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
