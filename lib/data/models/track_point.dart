import 'package:flutter/foundation.dart';

/// Un punto GPS muestreado durante la sesión.
@immutable
class TrackPoint {
  const TrackPoint({
    this.id,
    required this.sessionId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    this.distanceSoFar = 0,
  });

  final int? id;
  final int sessionId;
  final double lat;
  final double lng;

  /// m/s instantáneos (ya suavizados por [DistanceFilter]).
  final double speed;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  /// Odómetro acumulado en el momento de este punto (metros).
  final double distanceSoFar;

  Map<String, Object?> toMap() => {
        'session_id': sessionId,
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'altitude': altitude,
        'accuracy': accuracy,
        'ts': timestamp.millisecondsSinceEpoch,
        'distance_so_far': distanceSoFar,
      };

  factory TrackPoint.fromMap(Map<String, Object?> map) => TrackPoint(
        id: map['id'] as int?,
        sessionId: map['session_id'] as int,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        speed: (map['speed'] as num).toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble() ?? 0,
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
        distanceSoFar: (map['distance_so_far'] as num?)?.toDouble() ?? 0,
      );
}
