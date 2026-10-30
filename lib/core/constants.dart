/// Constantes globales de la app.
///
/// Todo lo que puede cambiar entre compilaciones (canal de método nativo,
/// App Group de iOS, etc.) vive aquí para no repetirlo por el código.
class AppConfig {
  AppConfig._();

  /// Nombre visible en la pantalla de bloqueo / notificación.
  static const String appName = 'Pulso Basket';

  /// Canal Kotlin <-> Dart para el servicio en primer plano de Android.
  static const String androidChannel = 'pulso/tracking_service';

  /// Canal Swift <-> Dart para la Live Activity de iOS.
  static const String iosChannel = 'pulso/live_activity';

  /// App Group compartido entre la app y la extensión del widget de iOS.
  /// Debe coincidir EXACTAMENTE con el de Xcode y el de `Runner.entitlements`.
  static const String iosAppGroup = 'group.com.pulso.basket';

  /// Esquema usado por los enlaces de la Live Activity (fallback iOS 16).
  static const String deepLinkScheme = 'pulso';

  /// Identificador de la notificación Android.
  static const int androidNotificationId = 4210;

  /// Umbral de precisión GPS (metros). Por encima de esto el punto se descarta:
  /// es la principal defensa contra el "GPS drift" que infla la distancia.
  static const double maxAccuracyMeters = 25.0;

  /// Distancia mínima entre puntos para acumular metros (metros).
  static const double minMovementMeters = 2.5;

  /// Cada cuántos puntos se escribe un lote en SQLite.
  static const int pointsBatchSize = 15;
}
