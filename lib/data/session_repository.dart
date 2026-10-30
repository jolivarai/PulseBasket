import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'models/track_point.dart';
import 'models/workout_session.dart';

/// Acceso a sesiones y puntos GPS.
class SessionRepository {
  SessionRepository(this._db);

  final AppDatabase _db;

  /// Crea la sesión "en curso" y devuelve su id.
  Future<int> create(WorkoutSession session) async {
    final Database db = await _db.database;
    return db.insert('sessions', session.toMap());
  }

  /// Guardado incremental: se llama al pausar, al cambiar de estado y al
  /// finalizar. Si Android mata el proceso, la sesión sigue en la base.
  Future<void> update(WorkoutSession session) async {
    final int? id = session.id;
    if (id == null) return;
    final Database db = await _db.database;
    await db.update(
      'sessions',
      session.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Inserción por lotes: escribir 1 fila por segundo durante 40 min castiga
  /// la batería y el disco, así que se agrupa.
  Future<void> addPoints(List<TrackPoint> points) async {
    if (points.isEmpty) return;
    final Database db = await _db.database;
    final Batch batch = db.batch();
    for (final TrackPoint point in points) {
      batch.insert('track_points', point.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<WorkoutSession>> recent({int limit = 60}) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'sessions',
      where: 'is_finished = 1',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> between(DateTime from, DateTime to) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'sessions',
      where: 'started_at >= ? AND started_at < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'started_at ASC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<TrackPoint>> pointsOf(int sessionId) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'track_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'ts ASC',
    );
    return rows.map(TrackPoint.fromMap).toList();
  }

  /// La sesión que quedó abierta (app cerrada a la fuerza). Se usa para
  /// ofrecer "recuperar entreno" en la pantalla de inicio.
  Future<WorkoutSession?> unfinished() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'sessions',
      where: 'is_finished = 0 AND distance_m > 100',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  /// Borra todo el historial (Ajustes > Borrar historial).
  /// Los puntos GPS se eliminan en cascada por la FK `ON DELETE CASCADE`.
  Future<void> deleteAll() async {
    final Database db = await _db.database;
    await db.delete('sessions');
  }

  Future<void> delete(int sessionId) async {
    final Database db = await _db.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  /// Velocidad media (m/s) de cada uno de los últimos 7 días con actividad.
  /// Se usa para el gráfico semanal de evolución.
  Future<Map<DateTime, double>> weeklyAverageSpeed({DateTime? reference}) async {
    final DateTime now = reference ?? DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final List<WorkoutSession> sessions = await between(start, now.add(const Duration(days: 1)));

    final Map<DateTime, List<double>> grouped = {};
    for (final WorkoutSession s in sessions) {
      if (s.distanceMeters < 200 || s.movingSeconds < 60) continue;
      final DateTime day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      grouped.putIfAbsent(day, () => []).add(s.avgSpeed);
    }
    return grouped.map(
      (DateTime day, List<double> values) =>
          MapEntry(day, values.reduce((a, b) => a + b) / values.length),
    );
  }
}
