import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../core/constants.dart';

/// Puente único con la pantalla de bloqueo.
///
/// | Plataforma | Mecanismo                                              |
/// |------------|--------------------------------------------------------|
/// | Android    | Notificación ongoing del `TrackingForegroundService`    |
/// |            | con acciones PendingIntent (Pausar / Reanudar / Parar)  |
/// | iOS        | Live Activity (ActivityKit) + Dynamic Island            |
///
/// Ambos lados emiten comandos ("pause", "resume", "stop") por el mismo
/// stream [commands], así el controlador de entrenamiento no sabe en qué
/// plataforma corre.
class LockScreenService {
  LockScreenService._();

  static const MethodChannel _channel = MethodChannel(AppConfig.androidChannel);
  static const MethodChannel _iosChannel = MethodChannel(AppConfig.iosChannel);

  static final StreamController<String> _commands =
      StreamController<String>.broadcast();

  /// Comandos emitidos por los botones de la pantalla de bloqueo.
  static Stream<String> get commands => _commands.stream;

  static bool _handlersReady = false;

  /// Debe llamarse una vez, antes de iniciar el primer entreno.
  static void init() {
    if (_handlersReady) return;
    _handlersReady = true;

    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'onAction') {
          final String action = (call.arguments as String?) ?? '';
          if (action.isNotEmpty) _commands.add(action);
        }
        return null;
      });
    }

    if (Platform.isIOS) {
      _iosChannel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'onCommand') {
          final String action = (call.arguments as String?) ?? '';
          if (action.isNotEmpty) _commands.add(action);
        }
        return null;
      });
    }
  }

  /// Arranca la superficie de bloqueo.
  /// [title] suele ser "Carrera 4 km" o "Bici 12 km".
  static Future<void> start({
    required String title,
    required double targetMeters,
  }) async {
    init();
    if (Platform.isAndroid) {
      await _safeInvoke(_channel, 'start', {
        'title': title,
        'targetMeters': targetMeters,
      });
    } else if (Platform.isIOS) {
      await _safeInvoke(_iosChannel, 'start', {
        'title': title,
        'targetMeters': targetMeters,
      });
    }
  }

  /// Refresco en tiempo real (~1 vez por segundo).
  ///
  /// Se envía texto ya formateado para que Kotlin/Swift no tengan que
  /// reimplementar el formato de ritmo ni los decimales en español.
  static Future<void> update({
    required String title,
    required String distanceText,
    required String paceText,
    required String remainingText,
    required double progress,
    required bool paused,
  }) async {
    final Map<String, Object?> args = {
      'title': title,
      'distance': distanceText,
      'pace': paceText,
      'remaining': remainingText,
      'progress': progress,
      'paused': paused,
    };
    if (Platform.isAndroid) {
      await _safeInvoke(_channel, 'update', args);
    } else if (Platform.isIOS) {
      await _safeInvoke(_iosChannel, 'update', args);
    }
  }

  /// Cierra notificación / Live Activity.
  static Future<void> stop({required String title, required String summary}) async {
    final Map<String, Object?> args = {'title': title, 'summary': summary};
    if (Platform.isAndroid) {
      await _safeInvoke(_channel, 'stop', args);
    } else if (Platform.isIOS) {
      await _safeInvoke(_iosChannel, 'end', args);
    }
  }

  /// Nunca dejamos que un fallo del canal nativo tumbe el entreno:
  /// si la notificación falla, el GPS debe seguir funcionando.
  static Future<void> _safeInvoke(
    MethodChannel channel,
    String method,
    Map<String, Object?> args,
  ) async {
    try {
      await channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Plataforma sin implementación (tests, escritorio): se ignora.
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('LockScreenService.$method falló: ${e.message}');
    }
  }
}
