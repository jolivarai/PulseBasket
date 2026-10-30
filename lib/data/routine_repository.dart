import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'models/routine_day.dart';
import 'routine_seed.dart';

/// Lectura/escritura del calendario editable.
class RoutineRepository {
  RoutineRepository(this._db);

  final AppDatabase _db;

  Future<List<RoutineDay>> loadWeek() async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows =
        await db.query('routine_days', orderBy: 'weekday ASC');
    return rows
        .map((row) => RoutineDay.fromJson(
              jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<RoutineDay?> dayOf(int weekday) async {
    final Database db = await _db.database;
    final List<Map<String, Object?>> rows = await db.query(
      'routine_days',
      where: 'weekday = ?',
      whereArgs: [weekday],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RoutineDay.fromJson(
      jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> saveDay(RoutineDay day) async {
    final Database db = await _db.database;
    await db.insert(
      'routine_days',
      {'weekday': day.weekday, 'payload': jsonEncode(day.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Vuelve al plan original (botón "Restaurar plan" de Ajustes).
  Future<void> resetToSeed() async {
    final Database db = await _db.database;
    final Batch batch = db.batch();
    for (final RoutineDay day in kSeedWeek) {
      batch.insert(
        'routine_days',
        {'weekday': day.weekday, 'payload': jsonEncode(day.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
