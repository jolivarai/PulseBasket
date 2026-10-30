import 'dart:math' as math;

/// Utilidades geográficas sin dependencias externas.
class Geo {
  Geo._();

  static const double earthRadius = 6371000.0; // metros

  /// Distancia Haversine en metros entre dos coordenadas.
  ///
  /// Se usa Haversine y no la distancia planar porque a velocidades de carrera
  /// el error planar en latitudes medias es apreciable, y porque necesitamos
  /// exactitud también en rutas largas de bicicleta.
  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = _rad(lat2 - lat1);
    final double dLon = _rad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Rumbo inicial (0-360°) entre dos puntos. Se usa para dibujar la traza.
  static double bearing(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = _rad(lon2 - lon1);
    final double y = math.sin(dLon) * math.cos(_rad(lat2));
    final double x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
        math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}

/// Filtro de distancia con histéresis.
///
/// Un GPS de teléfono tiene ruido de 3-15 m incluso parado. Si sumáramos todos
/// los saltos, un entreno de 40 minutos "ganaría" cientos de metros falsos.
/// Este filtro:
///  1. descarta fixes con precisión peor que [maxAccuracy],
///  2. ignora desplazamientos menores que [minMovement],
///  3. aplica una media móvil exponencial a la velocidad instantánea.
class DistanceFilter {
  DistanceFilter({
    this.maxAccuracy = 25,
    this.minMovement = 2.5,
    this.smoothing = 0.35,
  });

  final double maxAccuracy;
  final double minMovement;
  final double smoothing;

  double _lat = 0;
  double _lng = 0;
  bool _hasFix = false;
  double _speed = 0;

  double get smoothedSpeed => _speed;

  /// Devuelve los metros acumulados con este fix (0 si se descarta).
  double add({
    required double lat,
    required double lng,
    required double accuracy,
    required double rawSpeed,
  }) {
    if (accuracy > maxAccuracy || accuracy < 0) return 0;

    if (!_hasFix) {
      _lat = lat;
      _lng = lng;
      _hasFix = true;
      _speed = rawSpeed.clamp(0, 20);
      return 0;
    }

    final double d = Geo.haversine(_lat, _lng, lat, lng);
    // Descartar saltos imposibles (> 12 m/s ≈ 43 km/h corriendo): casi siempre
    // son un salto de celda, no un sprint.
    if (d > 60) return 0;

    _speed = _speed + smoothing * (rawSpeed.clamp(0, 20) - _speed);

    if (d < minMovement) return 0;

    _lat = lat;
    _lng = lng;
    return d;
  }

  void reset() {
    _hasFix = false;
    _speed = 0;
    _lat = 0;
    _lng = 0;
  }
}
