import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models/routine_day.dart';
import 'routine_seed.dart';

/// Base de datos local única de la app.
///
/// Todo el historial vive en el teléfono: no hay cuentas, ni nube, ni
/// sincronización. Eso es deliberado: la app funciona sin datos móviles y el
/// usuario es dueño de sus recorridos.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const int _version = 1;
  Database? _db;

  Future<Database> get database async {
    final Database? existing = _db;
    if (existing != null) return existing;
    final String dir = await getDatabasesPath();
    final Database db = await openDatabase(
      p.join(dir, 'pulso_basket.db'),
      version: _version,
      onConfigure: (Database db) async {
        // Integridad referencial: si se borra una sesión, sus puntos se van.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
    await _seedRoutineIfNeeded(db);
    _db = db;
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        title         TEXT    NOT NULL,
        type          TEXT    NOT NULL,
        started_at    INTEGER NOT NULL,
        finished_at   INTEGER,
        distance_m    REAL    NOT NULL DEFAULT 0,
        moving_s      INTEGER NOT NULL DEFAULT 0,
        target_m      REAL    NOT NULL DEFAULT 0,
        avg_speed     REAL    NOT NULL DEFAULT 0,
        max_speed     REAL    NOT NULL DEFAULT 0,
        is_finished   INTEGER NOT NULL DEFAULT 0,
        notes         TEXT    NOT NULL DEFAULT '',
        weekday_plan  INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE track_points (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id      INTEGER NOT NULL,
        lat             REAL    NOT NULL,
        lng             REAL    NOT NULL,
        speed           REAL    NOT NULL DEFAULT 0,
        altitude        REAL    NOT NULL DEFAULT 0,
        accuracy        REAL    NOT NULL DEFAULT 0,
        ts              INTEGER NOT NULL,
        distance_so_far REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Índice clave: los gráficos leen por sesión ordenados por tiempo.
    await db.execute(
      'CREATE INDEX idx_points_session_ts ON track_points (session_id, ts)',
    );
    await db.execute('CREATE INDEX idx_sessions_started ON sessions (started_at)');

    // La rutina se guarda como JSON por día para poder editarla sin migraciones
    // de esquema cuando el usuario cambia series, repeticiones o ejercicios.
    await db.execute('''
      CREATE TABLE routine_days (
        weekday INTEGER PRIMARY KEY,
        payload TEXT NOT NULL
      )
    ''');
  }

  /// Inserta el plan por defecto solo la primera vez que se abre la app.
  Future<void> _seedRoutineIfNeeded(Database db) async {
    final int count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM routine_days'),
        ) ??
        0;
    if (count > 0) return;
    final Batch batch = db.batch();
    for (final RoutineDay day in kSeedWeek) {
      batch.insert('routine_days', {
        'weekday': day.weekday,
        'payload': jsonEncode(day.toJson()),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
