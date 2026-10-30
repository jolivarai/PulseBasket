import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'models/routine_day.dart';
import 'models/workout_session.dart';
import 'routine_repository.dart';
import 'session_repository.dart';

final Provider<AppDatabase> databaseProvider =
    Provider<AppDatabase>((Ref ref) => AppDatabase.instance);

final Provider<SessionRepository> sessionRepositoryProvider =
    Provider<SessionRepository>((Ref ref) => SessionRepository(ref.watch(databaseProvider)));

final Provider<RoutineRepository> routineRepositoryProvider =
    Provider<RoutineRepository>((Ref ref) => RoutineRepository(ref.watch(databaseProvider)));

/// Historial reciente. Se refresca con `ref.invalidate(historyProvider)`.
final FutureProvider<List<WorkoutSession>> historyProvider =
    FutureProvider<List<WorkoutSession>>((Ref ref) =>
        ref.watch(sessionRepositoryProvider).recent());

/// Plan semanal completo.
final FutureProvider<List<RoutineDay>> weekPlanProvider =
    FutureProvider<List<RoutineDay>>((Ref ref) =>
        ref.watch(routineRepositoryProvider).loadWeek());

/// Plan del día de hoy (1 = lunes ... 7 = domingo).
final FutureProvider<RoutineDay?> todayPlanProvider =
    FutureProvider<RoutineDay?>((Ref ref) {
  final int weekday = DateTime.now().weekday;
  return ref.watch(routineRepositoryProvider).dayOf(weekday);
});

/// Velocidad media de los últimos 7 días, para el gráfico de evolución.
final FutureProvider<Map<DateTime, double>> weeklySpeedProvider =
    FutureProvider<Map<DateTime, double>>((Ref ref) =>
        ref.watch(sessionRepositoryProvider).weeklyAverageSpeed());
