/// Un ejercicio concreto de la rutina.
///
/// [steps] es la descripción paso a paso que se muestra en la pantalla de
/// detalle; es el campo que hace que la app sea usable sin vídeos ni internet.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.steps,
    required this.cue,
    required this.basketballTransfer,
    required this.source,
    this.easier = '',
    this.harder = '',
  });

  final String id;
  final String name;

  /// 'Espalda', 'Pecho', 'Bíceps', 'Tríceps', 'Core'...
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSeconds;

  /// Pasos numerados, en orden de ejecución.
  final List<String> steps;

  /// La corrección técnica que más impacto tiene (una sola frase).
  final String cue;

  /// Por qué este ejercicio mejora el rendimiento en baloncesto.
  final String basketballTransfer;

  /// Metodología de referencia (no implica afiliación ni programa oficial).
  final String source;

  final String easier;
  final String harder;

  Exercise copyWith({
    String? name,
    String? muscleGroup,
    int? sets,
    String? reps,
    int? restSeconds,
    List<String>? steps,
    String? cue,
    String? basketballTransfer,
    String? source,
    String? easier,
    String? harder,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      steps: steps ?? this.steps,
      cue: cue ?? this.cue,
      basketballTransfer: basketballTransfer ?? this.basketballTransfer,
      source: source ?? this.source,
      easier: easier ?? this.easier,
      harder: harder ?? this.harder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
        'steps': steps,
        'cue': cue,
        'basketballTransfer': basketballTransfer,
        'source': source,
        'easier': easier,
        'harder': harder,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        muscleGroup: json['muscleGroup'] as String? ?? '',
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        reps: json['reps'] as String? ?? '10',
        restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 45,
        steps: (json['steps'] as List<dynamic>? ?? const []).cast<String>(),
        cue: json['cue'] as String? ?? '',
        basketballTransfer: json['basketballTransfer'] as String? ?? '',
        source: json['source'] as String? ?? '',
        easier: json['easier'] as String? ?? '',
        harder: json['harder'] as String? ?? '',
      );
}
