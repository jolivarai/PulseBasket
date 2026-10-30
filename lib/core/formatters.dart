import 'package:intl/intl.dart';

/// Formatos de presentación compartidos por toda la app.
class Fmt {
  Fmt._();

  static final DateFormat _dayMonth = DateFormat('d MMM', 'es');
  static final DateFormat _full = DateFormat("EEEE d 'de' MMMM · HH:mm", 'es');
  static final DateFormat _time = DateFormat('HH:mm', 'es');

  /// "3,4 km" / "850 m" según magnitud.
  static String distance(double meters) {
    if (meters < 950) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Ritmo en min/km a partir de metros/segundo.
  /// Devuelve "--'--\"" cuando la velocidad es 0 o irreal.
  static String pace(double metersPerSecond) {
    if (metersPerSecond <= 0.3) return "--'--\"";
    final double secPerKm = 1000 / metersPerSecond;
    if (secPerKm > 3600) return "--'--\"";
    final int minutes = secPerKm ~/ 60;
    final int seconds = (secPerKm % 60).round();
    // Corrige el redondeo de 59,6 s -> 60 s
    if (seconds == 60) return "${minutes + 1}'00\"";
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// Velocidad en km/h (bici).
  static String speedKmh(double metersPerSecond) {
    final double kmh = metersPerSecond * 3.6;
    return '${kmh.toStringAsFixed(1).replaceAll('.', ',')} km/h';
  }

  /// Cronómetro mm:ss o h:mm:ss.
  static String duration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String dateShort(DateTime d) => _dayMonth.format(d);
  static String dateFull(DateTime d) => _full.format(d);
  static String time(DateTime d) => _time.format(d);
}
