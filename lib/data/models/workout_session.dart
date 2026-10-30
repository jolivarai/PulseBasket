import 'routine_day.dart';

/// Resultado persistente de una sesión de carrera, bicicleta o fuerza.
///
/// Se guarda una fila por sesión y se actualiza al pausar/finalizar, de modo
/// que si el sistema mata la app a mitad de entreno no se pierde el recorrido.
class WorkoutSession {
  const WorkoutSession({
    this.id,
    required this.title,
    required this.type,
    required this.startedAt,
    this.finishedAt,
    this.distanceMeters = 0,
    this.movingSeconds = 0,
    this.targetDistanceMeters = 0,
    this.avgSpeed = 0,
    this.maxSpeed = 0,
    this.isFinished = false,
    this.notes = '',
    this.weekdayPlanId = 1,
  });

  final int? id;
  final String title;
  final WorkoutType type;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double distanceMeters;

  /// Segundos en movimiento (sin contar pausas).
  final int movingSeconds;
  final double targetDistanceMeters;

  /// m/s medios y máximos.
  final double avgSpeed;
  final double maxSpeed;
  final bool isFinished;
  final String notes;
  final int weekdayPlanId;

  double get remainingMeters =>
      (targetDistanceMeters - distanceMeters).clamp(0, double.infinity).toDouble();

  double get progress =>
      targetDistanceMeters <= 0 ? 0 : (distanceMeters / targetDistanceMeters).clamp(0, 1).toDouble();

  Duration get movingTime => Duration(seconds: movingSeconds);

  WorkoutSession copyWith({
    int? id,
    String? title,
    DateTime? finishedAt,
    double? distanceMeters,
    int? movingSeconds,
    double? avgSpeed,
    double? maxSpeed,
    bool? isFinished,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      targetDistanceMeters: targetDistanceMeters,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      isFinished: isFinished ?? this.isFinished,
      notes: notes ?? this.notes,
      weekdayPlanId: weekdayPlanId,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'type': type.name,
        'started_at': startedAt.millisecondsSinceEpoch,
        'finished_at': finishedAt?.millisecondsSinceEpoch,
        'distance_m': distanceMeters,
        'moving_s': movingSeconds,
        'target_m': targetDistanceMeters,
        'avg_speed': avgSpeed,
        'max_speed': maxSpeed,
        'is_finished': isFinished ? 1 : 0,
        'notes': notes,
        'weekday_plan': weekdayPlanId,
      };

  factory WorkoutSession.fromMap(Map<String, Object?> m) => WorkoutSession(
        id: m['id'] as int?,
        title: m['title'] as String? ?? 'Sesión',
        type: WorkoutType.fromName(m['type'] as String? ?? 'run'),
        startedAt: DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
        finishedAt: m['finished_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['finished_at'] as int),
        distanceMeters: (m['distance_m'] as num?)?.toDouble() ?? 0,
        movingSeconds: (m['moving_s'] as num?)?.toInt() ?? 0,
        targetDistanceMeters: (m['target_m'] as num?)?.toDouble() ?? 0,
        avgSpeed: (m['avg_speed'] as num?)?.toDouble() ?? 0,
        maxSpeed: (m['max_speed'] as num?)?.toDouble() ?? 0,
        isFinished: (m['is_finished'] as int? ?? 0) == 1,
        notes: m['notes'] as String? ?? '',
        weekdayPlanId: (m['weekday_plan'] as num?)?.toInt() ?? 1,
      );
}
