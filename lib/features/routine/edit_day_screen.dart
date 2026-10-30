import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../data/models/routine_day.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

/// Editor completo de un día: distancia, tipo de sesión, nota y ejercicios.
///
/// Los cambios se guardan en SQLite (tabla `routine_days`) y el calendario se
/// refresca al volver: no hay que reiniciar la app.
class EditDayScreen extends ConsumerStatefulWidget {
  const EditDayScreen({super.key, required this.weekday});

  final int weekday;

  @override
  ConsumerState<EditDayScreen> createState() => _EditDayScreenState();
}

class _EditDayScreenState extends ConsumerState<EditDayScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _distanceKm = TextEditingController();
  final TextEditingController _note = TextEditingController();

  List<Exercise> _exercises = [];
  WorkoutType _type = WorkoutType.run;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final RoutineDay? day =
        await ref.read(routineRepositoryProvider).dayOf(widget.weekday);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (day != null) {
        _title.text = day.title;
        _type = day.type;
        _distanceKm.text = day.hasDistance
            ? (day.targetDistanceMeters / 1000).toStringAsFixed(
                day.targetDistanceMeters % 1000 == 0 ? 0 : 1)
            : '';
        _note.text = day.note;
        _exercises = List<Exercise>.from(day.exercises);
      } else {
        _title.text = 'Nuevo día';
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _distanceKm.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String weekdayName = const [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ][widget.weekday - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar $weekdayName'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                SectionCard(
                  title: 'Sesión',
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Título del día',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<WorkoutType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: WorkoutType.values
                            .map(
                              (WorkoutType t) => DropdownMenuItem<WorkoutType>(
                                value: t,
                                child: Text('${t.emoji}  ${t.label}'),
                              ),
                            )
                            .toList(),
                        onChanged: (WorkoutType? value) {
                          if (value != null) setState(() => _type = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _distanceKm,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Distancia objetivo (km)',
                          helperText: '0 = sesión sin GPS (solo fuerza o descanso)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _note,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nota / calentamiento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ejercicios (${_exercises.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _editExercise(null),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Añadir'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_exercises.isEmpty)
                  const EmptyState(
                    icon: Icons.self_improvement,
                    title: 'Sin ejercicios',
                    subtitle: 'Añade los que quieras: la rutina es tuya.',
                  ),
                for (int i = 0; i < _exercises.length; i++)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        _exercises[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_exercises[i].sets} × ${_exercises[i].reps} · '
                        '${_exercises[i].muscleGroup}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Subir',
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: i == 0 ? null : () => _move(i, -1),
                          ),
                          IconButton(
                            tooltip: 'Bajar',
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed:
                                i == _exercises.length - 1 ? null : () => _move(i, 1),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editExercise(_exercises[i]),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => setState(() => _exercises.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ],
            ),
    );
  }

  void _move(int index, int delta) {
    final int target = index + delta;
    if (target < 0 || target >= _exercises.length) return;
    setState(() {
      final Exercise item = _exercises.removeAt(index);
      _exercises.insert(target, item);
    });
  }

  Future<void> _editExercise(Exercise? current) async {
    final Exercise? result = await showDialog<Exercise>(
      context: context,
      builder: (_) => _ExerciseEditorDialog(initial: current),
    );
    if (result == null) return;
    setState(() {
      if (current == null) {
        _exercises.add(result);
      } else {
        final int index = _exercises.indexWhere((Exercise e) => e.id == current.id);
        if (index >= 0) _exercises[index] = result;
      }
    });
  }

  Future<void> _save() async {
    final double km = double.tryParse(_distanceKm.text.replaceAll(',', '.')) ?? 0;
    final bool rest = _type == WorkoutType.rest || (km == 0 && _exercises.isEmpty);

    final RoutineDay day = RoutineDay(
      weekday: widget.weekday,
      title: _title.text.trim().isEmpty ? 'Sesión' : _title.text.trim(),
      type: rest ? WorkoutType.rest : _type,
      targetDistanceMeters: km * 1000,
      exercises: _exercises,
      isRestDay: rest,
      note: _note.text.trim(),
    );

    await ref.read(routineRepositoryProvider).saveDay(day);
    ref.invalidate(weekPlanProvider);
    ref.invalidate(todayPlanProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Día actualizado')),
    );
  }
}

/// Diálogo de alta/edición de un ejercicio. Devuelve el [Exercise] resultante.
class _ExerciseEditorDialog extends StatefulWidget {
  const _ExerciseEditorDialog({this.initial});

  final Exercise? initial;

  @override
  State<_ExerciseEditorDialog> createState() => _ExerciseEditorDialogState();
}

class _ExerciseEditorDialogState extends State<_ExerciseEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _group;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _rest;
  late final TextEditingController _steps;
  late final TextEditingController _cue;
  late final TextEditingController _transfer;

  @override
  void initState() {
    super.initState();
    final Exercise? e = widget.initial;
    _name = TextEditingController(text: e?.name ?? '');
    _group = TextEditingController(text: e?.muscleGroup ?? 'Core');
    _sets = TextEditingController(text: '${e?.sets ?? 3}');
    _reps = TextEditingController(text: e?.reps ?? '10');
    _rest = TextEditingController(text: '${e?.restSeconds ?? 45}');
    _steps = TextEditingController(text: e?.steps.join('\n') ?? '');
    _cue = TextEditingController(text: e?.cue ?? '');
    _transfer = TextEditingController(text: e?.basketballTransfer ?? '');
  }

  @override
  void dispose() {
    for (final TextEditingController c in [
      _name,
      _group,
      _sets,
      _reps,
      _rest,
      _steps,
      _cue,
      _transfer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nuevo ejercicio' : 'Editar ejercicio'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _group,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sets,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Series'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _reps,
                      decoration: const InputDecoration(labelText: 'Reps / tiempo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _rest,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Descanso (s)'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _steps,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pasos (uno por línea)',
                  alignLabelWithHint: true,
                ),
              ),
              TextField(
                controller: _cue,
                decoration: const InputDecoration(labelText: 'Corrección clave'),
              ),
              TextField(
                controller: _transfer,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Transferencia al básquet',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.of(context).pop(
              Exercise(
                id: widget.initial?.id ??
                    'custom-${DateTime.now().millisecondsSinceEpoch}',
                name: _name.text.trim(),
                muscleGroup: _group.text.trim(),
                sets: int.tryParse(_sets.text) ?? 3,
                reps: _reps.text.trim(),
                restSeconds: int.tryParse(_rest.text) ?? 45,
                steps: _steps.text
                    .split('\n')
                    .map((String s) => s.trim())
                    .where((String s) => s.isNotEmpty)
                    .toList(),
                cue: _cue.text.trim(),
                basketballTransfer: _transfer.text.trim(),
                source: widget.initial?.source ?? 'Personalizado',
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
