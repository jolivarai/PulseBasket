import 'dart:io';

import 'package:geolocator/geolocator.dart';

/// Excepción con mensaje legible para mostrar en la UI.
class LocationException implements Exception {
  LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Envoltorio de `geolocator` con la configuración correcta para entrenar
/// con la pantalla apagada y sin datos móviles.
///
/// Puntos importantes:
///  - `bestForNavigation` usa GPS + GLONASS/Galileo; no consume datos.
///  - `distanceFilter: 2` filtra en el sistema operativo antes de despertar a
///    Dart, lo que ahorra batería.
///  - En Android NO se usa la notificación del plugin: la nuestra es la única
///    (la del servicio en primer plano propio, con botones).
class LocationService {
  /// Comprueba GPS y permisos. Lanza [LocationException] con texto accionable.
  Future<void> ensureReady() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'El GPS está desactivado. Actívalo en Ajustes > Ubicación.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Sin permiso de ubicación no se puede medir el recorrido.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permiso de ubicación bloqueado. Actívalo en Ajustes del sistema.',
      );
    }
    // En iOS, "mientras uso la app" no basta para la pantalla bloqueada.
    if (Platform.isIOS && permission == LocationPermission.whileInUse) {
      throw LocationException(
        'En iOS necesitas permiso "Siempre" para seguir grabando con la '
        'pantalla bloqueada (Ajustes > Pulso Basket > Ubicación > Siempre).',
      );
    }
  }

  /// Stream de posiciones configurado para fondo.
  Stream<Position> positions() {
    if (Platform.isAndroid) {
      return Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
          intervalDuration: const Duration(seconds: 1),
          // El servicio en primer plano lo gestiona TrackingForegroundService,
          // por eso aquí se deja en null y solo hay una notificación.
          foregroundNotificationConfig: null,
        ),
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 2,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      ),
    );
  }

  Future<Position> currentPosition() => Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
}
