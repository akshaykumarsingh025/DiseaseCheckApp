import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/health_data_provider.dart';
import '../services/storage_service.dart';
import '../models/health_data.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {

  void _showDeleteDialog(String testName, List<HealthData> dataPoints) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $testName data?'),
        content: Text('This will remove all ${dataPoints.length} data point(s) for $testName. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (var dp in dataPoints) {
                final key = dp.key;
                if (key != null) await StorageService.deleteHealthData(key);
              }
              ref.invalidate(healthDataProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthData = ref.watch(healthDataProvider);

    // Group data by testName for charting
    final Map<String, List<HealthData>> groupedData = {};
    for (var entry in healthData) {
      groupedData.putIfAbsent(entry.testName, () => []).add(entry);
    }

    // Sort each group by date
    for (var key in groupedData.keys) {
      groupedData[key]!.sort((a, b) => a.date.compareTo(b.date));
    }

    // Pick key metrics to chart (ones with multiple readings)
    final chartableTests =
        groupedData.entries.where((e) => e.value.length >= 2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Trends'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: healthData.isEmpty
          ? _buildEmptyState()
          : chartableTests.isEmpty
              ? _buildNotEnoughData()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chartableTests.length,
                  itemBuilder: (context, index) {
                    final entry = chartableTests[index];
                    return _buildChartCard(
                      entry.key,
                      entry.value,
                      entry.value.first.category,
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No Health Data Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Enter your lab data to see trends over time.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotEnoughData() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text('Need More Data Points',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Enter your lab data at least twice to see trends. '
              'Charts will appear once we have 2+ readings for a test.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
      String testName, List<HealthData> dataPoints, String category) {
    final unit = dataPoints.first.unit;
    final dateFormat = DateFormat('dd/MM');
    final minVal =
        dataPoints.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final maxVal =
        dataPoints.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final effectiveRange = range > 0 ? range : (maxVal.abs() * 0.1 + 5.0);
    final yMin = (minVal - effectiveRange * 0.2)
        .clamp(0.0, double.infinity)
        .toDouble();
    final yMax = (maxVal + effectiveRange * 0.2).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(testName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(category,
                      style:
                          TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(testName, dataPoints);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete this data', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range > 0 ? range / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (value, meta) => Text(
                            _formatAxisValue(value),
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < dataPoints.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                  dateFormat.format(dataPoints[idx].date),
                                  style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (dataPoints.length - 1).toDouble(),
                  minY: yMin,
                  maxY: yMax,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        dataPoints.length,
                        (i) => FlSpot(i.toDouble(), dataPoints[i].value),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue,
                                strokeWidth: 2,
                                strokeColor: Colors.white),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${_formatAxisValue(spot.y)} $unit',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatAxisValue(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      final k = abs / 1000;
      return '$sign${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
    } else if (abs >= 100) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(1);
    }
  }
}
