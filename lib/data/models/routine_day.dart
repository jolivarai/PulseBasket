import 'exercise.dart';

/// Tipo de sesión del calendario. Se guarda como texto en SQLite.
enum WorkoutType {
  run,
  bike,
  strength,
  rest;

  String get label => switch (this) {
        WorkoutType.run => 'Carrera',
        WorkoutType.bike => 'Bicicleta',
        WorkoutType.strength => 'Fuerza',
        WorkoutType.rest => 'Descanso',
      };

  /// Icono usado en calendario y tarjetas.
  String get emoji => switch (this) {
        WorkoutType.run => '🏃',
        WorkoutType.bike => '🚴',
        WorkoutType.strength => '💪',
        WorkoutType.rest => '🛌',
      };

  static WorkoutType fromName(String name) =>
      WorkoutType.values.firstWhere((t) => t.name == name, orElse: () => WorkoutType.rest);
}

/// Un día de la semana dentro del plan editable.
///
/// [weekday] sigue la convención de DateTime: 1 = lunes ... 7 = domingo.
class RoutineDay {
  const RoutineDay({
    required this.weekday,
    required this.title,
    required this.type,
    required this.targetDistanceMeters,
    this.exercises = const [],
    this.isRestDay = false,
    this.note = '',
  });

  final int weekday;
  final String title;
  final WorkoutType type;

  /// 0 para días sin distancia (fuerza, descanso).
  final double targetDistanceMeters;
  final List<Exercise> exercises;
  final bool isRestDay;
  final String note;

  String get weekdayName => const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ][weekday - 1];

  bool get hasDistance => targetDistanceMeters > 0;

  /// Estimación de duración de la parte de fuerza (series x ejecución + descansos).
  int get estimatedStrengthMinutes {
    if (exercises.isEmpty) return 0;
    int seconds = 0;
    for (final Exercise e in exercises) {
      seconds += e.sets * (40 + e.restSeconds);
    }
    return (seconds / 60).round();
  }

  RoutineDay copyWith({
    String? title,
    WorkoutType? type,
    double? targetDistanceMeters,
    List<Exercise>? exercises,
    bool? isRestDay,
    String? note,
  }) {
    return RoutineDay(
      weekday: weekday,
      title: title ?? this.title,
      type: type ?? this.type,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      exercises: exercises ?? this.exercises,
      isRestDay: isRestDay ?? this.isRestDay,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'title': title,
        'type': type.name,
        'targetDistanceMeters': targetDistanceMeters,
        'isRestDay': isRestDay,
        'note': note,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory RoutineDay.fromJson(Map<String, dynamic> json) => RoutineDay(
        weekday: (json['weekday'] as num).toInt(),
        title: json['title'] as String? ?? '',
        type: WorkoutType.fromName(json['type'] as String? ?? 'rest'),
        targetDistanceMeters: (json['targetDistanceMeters'] as num?)?.toDouble() ?? 0,
        isRestDay: json['isRestDay'] as bool? ?? false,
        note: json['note'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>? ?? const [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
