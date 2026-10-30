import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../data/models/routine_day.dart';
import '../../data/models/workout_session.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'session_detail_screen.dart';

/// Historial permanente + evolución de la velocidad de la semana.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<WorkoutSession>> history = ref.watch(historyProvider);
    final AsyncValue<Map<DateTime, double>> weekly = ref.watch(weeklySpeedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          SectionCard(
            title: 'Velocidad media · últimos 7 días',
            trailing: IconButton(
              tooltip: 'Actualizar',
              onPressed: () => ref.invalidate(weeklySpeedProvider),
              icon: const Icon(Icons.refresh, size: 20),
            ),
            child: SizedBox(
              height: 170,
              child: weekly.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, _) => Center(child: Text('No se pudo leer: $e')),
                data: (Map<DateTime, double> data) =>
                    _WeeklySpeedChart(data: data),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sirve para ver la evolución en menos de 30 días: si la línea sube con '
            'el mismo esfuerzo percibido, el plan está funcionando.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text('Sesiones', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          history.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Error al leer el historial',
              subtitle: '$e',
            ),
            data: (List<WorkoutSession> sessions) {
              if (sessions.isEmpty) {
                return const EmptyState(
                  icon: Icons.route,
                  title: 'Todavía no hay recorridos',
                  subtitle: 'Pulsa "Entrenar" y empieza tu primera sesión de 4 km.',
                );
              }
              return Column(
                children: [
                  _WeeklyTotals(sessions: sessions),
                  const SizedBox(height: 12),
                  for (final WorkoutSession s in sessions) ...[
                    _SessionTile(session: s),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyTotals extends StatelessWidget {
  const _WeeklyTotals({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final List<WorkoutSession> week = sessions
        .where((WorkoutSession s) => s.startedAt.isAfter(monday))
        .toList();
    final double km =
        week.fold<double>(0, (double a, WorkoutSession s) => a + s.distanceMeters) / 1000;

    return Row(
      children: [
        Expanded(
          child: SectionCard(
            padding: const EdgeInsets.all(14),
            child: StatTile(value: km.toStringAsFixed(1), label: 'km esta semana'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SectionCard(
            padding: const EdgeInsets.all(14),
            child: StatTile(value: '${week.length}', label: 'sesiones'),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(session.type.emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${Fmt.dateShort(session.startedAt)} · ${Fmt.duration(session.movingTime)} · '
          '${session.type == WorkoutType.bike ? Fmt.speedKmh(session.avgSpeed) : Fmt.pace(session.avgSpeed)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          Fmt.distance(session.distanceMeters),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionDetailScreen(session: session),
          ),
        ),
      ),
    );
  }
}

/// Gráfico de líneas con la media diaria (m/s -> km/h).
class _WeeklySpeedChart extends StatelessWidget {
  const _WeeklySpeedChart({required this.data});

  final Map<DateTime, double> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime today = DateTime.now();
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (int i) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i)),
    );

    final List<FlSpot> spots = [];
    for (int i = 0; i < days.length; i++) {
      final double? speed = data[days[i]];
      if (speed != null) spots.add(FlSpot(i.toDouble(), speed * 3.6));
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'Sin sesiones esta semana.\nCorre o pedalea para empezar la curva.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final double maxY = (spots.map((FlSpot s) => s.y).reduce((a, b) => a > b ? a : b) + 4)
        .clamp(8, 60)
        .toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: 6,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (double value) => FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
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
              reservedSize: 30,
              interval: maxY / 3,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int i = value.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('E', 'es').format(days[i]).substring(0, 1).toUpperCase(),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touched) => touched
                .map((LineBarSpot spot) => LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} km/h',
                      theme.textTheme.labelSmall!,
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            barWidth: 3,
            color: theme.colorScheme.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}
