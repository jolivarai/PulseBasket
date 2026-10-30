import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/geo.dart';
import '../data/models/routine_day.dart';
import '../data/models/track_point.dart';
import '../data/models/workout_session.dart';
import '../data/providers.dart';
import 'location_service.dart';
import 'lock_screen_service.dart';

/// Punto de la traza, ligero: solo lo que necesita el `CustomPainter`.
@immutable
class RoutePoint {
  const RoutePoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

enum TrackingStatus { idle, acquiring, running, paused, finished }

@immutable
class TrackingState {
  const TrackingState({
    this.status = TrackingStatus.idle,
    this.title = '',
    this.type = WorkoutType.run,
    this.distanceMeters = 0,
    this.elapsedSeconds = 0,
    this.currentSpeed = 0,
    this.avgSpeed = 0,
    this.maxSpeed = 0,
    this.targetMeters = 0,
    this.route = const [],
    this.accuracy = 0,
    this.startedAt,
    this.sessionId,
    this.message,
    this.targetReached = false,
  });

  final TrackingStatus status;
  final String title;
  final WorkoutType type;
  final double distanceMeters;
  final int elapsedSeconds;
  final double currentSpeed; // m/s suavizados
  final double avgSpeed; // m/s
  final double maxSpeed; // m/s
  final double targetMeters;
  final List<RoutePoint> route;
  final double accuracy;
  final DateTime? startedAt;
  final int? sessionId;

  /// Aviso puntual para el usuario (permiso denegado, GPS perdido...).
  final String? message;
  final bool targetReached;

  bool get isActive =>
      status == TrackingStatus.running ||
      status == TrackingStatus.paused ||
      status == TrackingStatus.acquiring;

  double get remainingMeters =>
      (targetMeters - distanceMeters).clamp(0, double.infinity).toDouble();

  double get progress =>
      targetMeters <= 0 ? 0 : (distanceMeters / targetMeters).clamp(0, 1).toDouble();

  Duration get elapsed => Duration(seconds: elapsedSeconds);

  /// Ritmo o velocidad según disciplina.
  String get paceLabel => type == WorkoutType.bike
      ? Fmt.speedKmh(currentSpeed)
      : Fmt.pace(currentSpeed);

  TrackingState copyWith({
    TrackingStatus? status,
    String? title,
    WorkoutType? type,
    double? distanceMeters,
    int? elapsedSeconds,
    double? currentSpeed,
    double? avgSpeed,
    double? maxSpeed,
    double? targetMeters,
    List<RoutePoint>? route,
    double? accuracy,
    DateTime? startedAt,
    int? sessionId,
    String? message,
    bool? targetReached,
    bool clearMessage = false,
  }) {
    return TrackingState(
      status: status ?? this.status,
      title: title ?? this.title,
      type: type ?? this.type,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      targetMeters: targetMeters ?? this.targetMeters,
      route: route ?? this.route,
      accuracy: accuracy ?? this.accuracy,
      startedAt: startedAt ?? this.startedAt,
      sessionId: sessionId ?? this.sessionId,
      message: clearMessage ? null : (message ?? this.message),
      targetReached: targetReached ?? this.targetReached,
    );
  }
}

/// Máquina de estados del entrenamiento.
///
/// Diseño defensivo: la sesión se crea en SQLite ANTES del primer punto GPS y
/// se persiste cada 15 s. Si el sistema mata la app (Android es agresivo con
/// los procesos en segundo plano), el recorrido ya está en disco.
class TrackingController extends Notifier<TrackingState> {
  final LocationService _location = LocationService();
  final DistanceFilter _filter = DistanceFilter(
    maxAccuracy: AppConfig.maxAccuracyMeters,
    minMovement: AppConfig.minMovementMeters,
  );
  final List<RoutePoint> _route = <RoutePoint>[];
  final List<TrackPoint> _buffer = <TrackPoint>[];

  StreamSubscription<Position>? _subscription;
  Timer? _ticker;
  int _secondsSincePersist = 0;

  @override
  TrackingState build() {
    // Los botones de la pantalla de bloqueo llegan por aquí.
    final StreamSubscription<String> sub =
        LockScreenService.commands.listen(_handleNativeCommand);
    ref.onDispose(() {
      sub.cancel();
      _subscription?.cancel();
      _ticker?.cancel();
    });
    return const TrackingState();
  }

  // ────────────────────────────────────────────────────────────── API ──

  Future<void> start({
    required WorkoutType type,
    double targetMeters = 0,
    String? title,
  }) async {
    if (state.isActive) return;

    try {
      await _location.ensureReady();
    } on LocationException catch (e) {
      state = state.copyWith(message: e.message);
      return;
    }

    final DateTime now = DateTime.now();
    final String resolvedTitle = title ?? _defaultTitle(type, targetMeters);

    // 1. Fila en SQLite antes de moverse un metro.
    final int id = await ref.read(sessionRepositoryProvider).create(
          WorkoutSession(
            title: resolvedTitle,
            type: type,
            startedAt: now,
            targetDistanceMeters: targetMeters,
            weekdayPlanId: now.weekday,
          ),
        );

    _route.clear();
    _buffer.clear();
    _filter.reset();
    _secondsSincePersist = 0;

    state = TrackingState(
      status: TrackingStatus.acquiring,
      title: resolvedTitle,
      type: type,
      targetMeters: targetMeters,
      startedAt: now,
      sessionId: id,
      route: _route,
    );

    // 2. Superficie de bloqueo (notificación Android / Live Activity iOS).
    await LockScreenService.start(title: resolvedTitle, targetMeters: targetMeters);

    // 3. GPS. El stream sigue vivo con la pantalla apagada gracias al
    //    servicio en primer plano (Android) / background location (iOS).
    _subscription = _location.positions().listen(
          _onPosition,
          onError: (Object error) {
            state = state.copyWith(message: 'Señal GPS interrumpida: $error');
          },
          cancelOnError: false,
        );

    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  Future<void> pause() async {
    if (state.status != TrackingStatus.running) return;
    state = state.copyWith(status: TrackingStatus.paused, message: 'Pausado');
    await _persist();
    await _refreshLockScreen();
  }

  Future<void> resume() async {
    if (state.status != TrackingStatus.paused) return;
    state = state.copyWith(status: TrackingStatus.running, clearMessage: true);
    // Si el sistema cerró el stream, se reabre sin perder lo acumulado.
    _subscription ??=
        _location.positions().listen(_onPosition, cancelOnError: false);
    await _refreshLockScreen();
  }

  Future<void> finish() async {
    if (state.status == TrackingStatus.idle || state.status == TrackingStatus.finished) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    _ticker?.cancel();
    _ticker = null;

    await _flushPoints();

    final int seconds = state.elapsedSeconds;
    final double avg = seconds > 0 ? state.distanceMeters / seconds : 0;

    final WorkoutSession finished = WorkoutSession(
      id: state.sessionId,
      title: state.title,
      type: state.type,
      startedAt: state.startedAt ?? DateTime.now(),
      finishedAt: DateTime.now(),
      distanceMeters: state.distanceMeters,
      movingSeconds: seconds,
      targetDistanceMeters: state.targetMeters,
      avgSpeed: avg,
      maxSpeed: state.maxSpeed,
      isFinished: true,
      weekdayPlanId: (state.startedAt ?? DateTime.now()).weekday,
    );
    await ref.read(sessionRepositoryProvider).update(finished);

    await LockScreenService.stop(
      title: state.title,
      summary: '${Fmt.distance(state.distanceMeters)} · ${Fmt.duration(Duration(seconds: seconds))}',
    );

    state = state.copyWith(status: TrackingStatus.finished, avgSpeed: avg);
    ref.invalidate(historyProvider);
    ref.invalidate(weeklySpeedProvider);
  }

  /// Descarta la sesión en curso (botón "Descartar" del menú).
  Future<void> discard() async {
    final int? id = state.sessionId;
    await _subscription?.cancel();
    _subscription = null;
    _ticker?.cancel();
    _ticker = null;
    if (id != null) {
      await ref.read(sessionRepositoryProvider).delete(id);
    }
    await LockScreenService.stop(title: state.title, summary: 'Entreno descartado');
    state = const TrackingState();
    ref.invalidate(historyProvider);
  }

  /// Vuelve a "inicio" después de ver el resumen final.
  void reset() => state = const TrackingState();

  void clearMessage() => state = state.copyWith(clearMessage: true);

  // ─────────────────────────────────────────────────────── INTERNO ──

  void _onPosition(Position position) {
    if (state.status == TrackingStatus.paused ||
        state.status == TrackingStatus.finished ||
        state.status == TrackingStatus.idle) {
      return;
    }

    final double gained = _filter.add(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      rawSpeed: position.speed.isNegative ? 0 : position.speed,
    );

    // primer fix válido => pasamos de "buscando GPS" a "grabando"
    if (state.status == TrackingStatus.acquiring) {
      state = state.copyWith(status: TrackingStatus.running, clearMessage: true);
    }
    if (gained <= 0) {
      state = state.copyWith(accuracy: position.accuracy);
      return;
    }

    final double total = state.distanceMeters + gained;
    _route.add(RoutePoint(position.latitude, position.longitude));

    _buffer.add(
      TrackPoint(
        sessionId: state.sessionId ?? 0,
        lat: position.latitude,
        lng: position.longitude,
        speed: _filter.smoothedSpeed,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        distanceSoFar: total,
      ),
    );

    final double speed = _filter.smoothedSpeed;
    final bool reached = state.targetMeters > 0 && total >= state.targetMeters;

    state = state.copyWith(
      status: TrackingStatus.running,
      distanceMeters: total,
      currentSpeed: speed,
      maxSpeed: speed > state.maxSpeed ? speed : state.maxSpeed,
      route: _route,
      accuracy: position.accuracy,
      targetReached: reached,
    );

    if (_buffer.length >= AppConfig.pointsBatchSize) {
      // No se espera: escribir en disco no debe bloquear el hilo del GPS.
      unawaited(_flushPoints());
    }
  }

  void _onTick(Timer timer) {
    if (state.status != TrackingStatus.running) return;

    final int elapsed = state.elapsedSeconds + 1;
    final double avg = elapsed > 0 ? state.distanceMeters / elapsed : 0;

    state = state.copyWith(elapsedSeconds: elapsed, avgSpeed: avg);

    // La pantalla de bloqueo se refresca cada segundo; el disco cada 15 s.
    unawaited(_refreshLockScreen());
    _secondsSincePersist++;
    if (_secondsSincePersist >= 15) {
      _secondsSincePersist = 0;
      unawaited(_persist());
    }
  }

  Future<void> _refreshLockScreen() async {
    await LockScreenService.update(
      title: state.title,
      distanceText: Fmt.distance(state.distanceMeters),
      paceText: state.paceLabel,
      remainingText: state.targetMeters > 0
          ? 'Faltan ${Fmt.distance(state.remainingMeters)}'
          : Fmt.duration(state.elapsed),
      progress: state.progress,
      paused: state.status == TrackingStatus.paused,
    );
  }

  Future<void> _persist() async {
    final int? id = state.sessionId;
    if (id == null) return;
    await ref.read(sessionRepositoryProvider).update(
          WorkoutSession(
            id: id,
            title: state.title,
            type: state.type,
            startedAt: state.startedAt ?? DateTime.now(),
            distanceMeters: state.distanceMeters,
            movingSeconds: state.elapsedSeconds,
            targetDistanceMeters: state.targetMeters,
            avgSpeed: state.avgSpeed,
            maxSpeed: state.maxSpeed,
            weekdayPlanId: (state.startedAt ?? DateTime.now()).weekday,
          ),
        );
    await _flushPoints();
  }

  Future<void> _flushPoints() async {
    if (_buffer.isEmpty) return;
    final List<TrackPoint> batch = List<TrackPoint>.from(_buffer);
    _buffer.clear();
    await ref.read(sessionRepositoryProvider).addPoints(batch);
  }

  void _handleNativeCommand(String command) {
    switch (command) {
      case 'pause':
        unawaited(pause());
      case 'resume':
        unawaited(resume());
      case 'stop':
        unawaited(finish());
    }
  }

  String _defaultTitle(WorkoutType type, double meters) {
    final String km = (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1);
    return switch (type) {
      WorkoutType.run => 'Carrera $km km',
      WorkoutType.bike => 'Bicicleta $km km',
      WorkoutType.strength => 'Fuerza',
      WorkoutType.rest => 'Recuperación',
    };
  }
}

final NotifierProvider<TrackingController, TrackingState> trackingProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);
