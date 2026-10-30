import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/tracking_controller.dart';

/// Dibuja la traza GPS como un mapa esquemático.
///
/// ¿Por qué no un mapa real? Porque los tiles de mapas necesitan red (o un
/// paquete MBTiles de cientos de MB). La app es 100 % offline, así que
/// mostramos el recorrido normalizado: sirve para ver la forma de la ruta,
/// los giros y si el GPS se dispersó, sin descargar ni un byte.
class RoutePainter extends CustomPainter {
  RoutePainter({
    required this.points,
    required this.color,
    required this.gridColor,
  });

  final List<RoutePoint> points;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    if (points.length < 2) return;

    double minLat = points.first.lat, maxLat = points.first.lat;
    double minLng = points.first.lng, maxLng = points.first.lng;
    for (final RoutePoint p in points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }

    // Evita división por cero en rutas ida y vuelta perfectamente lineales.
    final double spanLat = math.max(maxLat - minLat, 1e-6);
    final double spanLng = math.max(maxLng - minLng, 1e-6);
    const double pad = 18;
    final double w = size.width - pad * 2;
    final double h = size.height - pad * 2;
    final double scale = math.min(w / spanLng, h / spanLat);

    Offset project(RoutePoint p) {
      final double x = pad + (p.lng - minLng) * scale + (w - spanLng * scale) / 2;
      // La latitud crece hacia el norte; en pantalla el norte es arriba.
      final double y = pad + (maxLat - p.lat) * scale + (h - spanLat * scale) / 2;
      return Offset(x, y);
    }

    final Path path = Path();
    final Offset first = project(points.first);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset o = project(points[i]);
      path.lineTo(o.dx, o.dy);
    }

    // Halo para que la línea se lea sobre cualquier fondo.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Salida (verde) y posición actual (relleno).
    canvas.drawCircle(first, 5, Paint()..color = const Color(0xFF2F9E44));
    canvas.drawCircle(project(points.last), 6, Paint()..color = color);
    canvas.drawCircle(
      project(points.last),
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.6;
    const double step = 28;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) =>
      oldDelegate.points.length != points.length || oldDelegate.color != color;
}
