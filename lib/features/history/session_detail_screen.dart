import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/models/routine_day.dart';
import '../../data/models/track_point.dart';
import '../../data/models/workout_session.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/route_painter.dart';
import '../../services/tracking_controller.dart' show RoutePoint;

/// Detalle de una sesión guardada: estadísticas, perfil de velocidad y traza.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int id = session.id ?? -1;

    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: FutureBuilder<List<TrackPoint>>(
        future: ref.read(sessionRepositoryProvider).pointsOf(id),
        builder: (BuildContext context, AsyncSnapshot<List<TrackPoint>> snap) {
          final List<TrackPoint> points = snap.data ?? const [];
          final List<RoutePoint> route =
              points.map((TrackPoint p) => RoutePoint(p.lat, p.lng)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              SectionCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatTile(
                          value: Fmt.distance(session.distanceMeters),
                          label: 'Distancia',
                          icon: Icons.straighten,
                        ),
                        StatTile(
                          value: Fmt.duration(session.movingTime),
                          label: 'Tiempo',
                          icon: Icons.timer_outlined,
                        ),
                        StatTile(
                          value: session.type == WorkoutType.bike
                              ? Fmt.speedKmh(session.avgSpeed)
                              : Fmt.pace(session.avgSpeed),
                          label: session.type == WorkoutType.bike ? 'Vel. media' : 'Ritmo medio',
                          icon: Icons.speed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.dateFull(session.startedAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (route.length > 1) ...[
                SectionCard(
                  title: 'Traza GPS',
                  child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: RoutePainter(
                        points: route,
                        color: theme.colorScheme.primary,
                        gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SectionCard(
                title: 'Velocidad durante la sesión',
                child: SizedBox(
                  height: 200,
                  child: snap.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : points.length < 3
                          ? Center(
                              child: Text(
                                'Sin datos suficientes para el gráfico',
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          : _SpeedProfile(points: points, isBike: session.type == WorkoutType.bike),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Datos',
                child: Column(
                  children: [
                    _row(theme, 'Velocidad máxima', Fmt.speedKmh(session.maxSpeed)),
                    _row(theme, 'Puntos GPS', '${points.length}'),
                    _row(theme, 'Objetivo', Fmt.distance(session.targetDistanceMeters)),
                    _row(
                      theme,
                      'Cumplimiento',
                      session.targetDistanceMeters > 0
                          ? '${(session.progress * 100).round()} %'
                          : 'Sesión libre',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Perfil temporal de velocidad: cada punto es un sample GPS.
class _SpeedProfile extends StatelessWidget {
  const _SpeedProfile({required this.points, required this.isBike});

  final List<TrackPoint> points;
  final bool isBike;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime start = points.first.timestamp;
    final List<FlSpot> spots = [];
    for (final TrackPoint p in points) {
      final double minutes = p.timestamp.difference(start).inSeconds / 60.0;
      spots.add(FlSpot(minutes, (p.speed * 3.6).clamp(0, 60)));
    }
    final double maxX = spots.last.x == 0 ? 1 : spots.last.x;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 40,
        minX: 0,
        maxX: maxX,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (double v) => FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 10,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxX / 4 == 0 ? 1 : maxX / 4,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                '${value.toStringAsFixed(0)}′',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            barWidth: 2.5,
            color: isBike ? const Color(0xFF1971C2) : theme.colorScheme.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (isBike ? const Color(0xFF1971C2) : theme.colorScheme.primary)
                  .withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}
