import 'package:flutter/material.dart';

import '../../data/models/exercise.dart';
import '../../widgets/common.dart';

/// Ficha de ejecución: pasos, corrección técnica y transferencia al básquet.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.muscleGroup)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            exercise.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(value: '${exercise.sets}', label: 'series'),
              const SizedBox(width: 22),
              _Metric(value: exercise.reps, label: 'repeticiones'),
              const SizedBox(width: 22),
              _Metric(value: '${exercise.restSeconds}s', label: 'descanso'),
            ],
          ),
          const SizedBox(height: 22),
          SectionCard(
            title: 'Ejecución paso a paso',
            child: Column(
              children: [
                for (int i = 0; i < exercise.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            exercise.steps[i],
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (exercise.cue.isNotEmpty)
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corrección clave',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(exercise.cue, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (exercise.basketballTransfer.isNotEmpty)
            SectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Para qué sirve en básquet',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(exercise.basketballTransfer, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (exercise.easier.isNotEmpty || exercise.harder.isNotEmpty)
            SectionCard(
              title: 'Ajusta la dificultad',
              child: Column(
                children: [
                  if (exercise.easier.isNotEmpty)
                    _LevelRow(
                      label: 'Más fácil',
                      value: exercise.easier,
                      color: Colors.green.shade700,
                    ),
                  if (exercise.easier.isNotEmpty && exercise.harder.isNotEmpty)
                    const Divider(height: 22),
                  if (exercise.harder.isNotEmpty)
                    _LevelRow(
                      label: 'Más difícil',
                      value: exercise.harder,
                      color: theme.colorScheme.error,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          if (exercise.source.isNotEmpty)
            Text(
              'Referencia metodológica: ${exercise.source}. '
              'Atribución de escuela de entrenamiento; no implica afiliación ni '
              'programa oficial.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}
