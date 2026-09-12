import 'dart:math';
import '../models.dart';

class StatisticsResult {
  final double averageTime;
  final double minTime;
  final double maxTime;
  final double stdDev;

  const StatisticsResult({
    this.averageTime = 0.0,
    this.minTime = 0.0,
    this.maxTime = 0.0,
    this.stdDev = 0.0,
  });
}

class TimeLogCalculator {
  static StatisticsResult calculate(List<Map<String, dynamic>> currentList) {
    if (currentList.isEmpty) {
      return const StatisticsResult();
    }

    final validTimes = currentList
        .where((e) => (e['type'] ?? 'normal') != 'outlier' && (e['time'] as int) > 0 && e['status'] != 'pending')
        .map((e) => e['time'] as int)
        .toList();

    if (validTimes.isEmpty) {
      return const StatisticsResult();
    }

    double avg = validTimes.reduce((a, b) => a + b) / validTimes.length;
    double mTime = validTimes.reduce(min).toDouble();
    double mxTime = validTimes.reduce(max).toDouble();
    double sDev = 0.0;

    if (validTimes.length > 1) {
      final variance = validTimes.map((t) => pow(t - avg, 2)).reduce((a, b) => a + b) / (validTimes.length - 1);
      sDev = sqrt(variance);
    }

    return StatisticsResult(
      averageTime: avg,
      minTime: mTime,
      maxTime: mxTime,
      stdDev: sDev,
    );
  }

  static int recalculateLastRecordedTime({
    required StopwatchMode mode,
    required List<Map<String, dynamic>> recordedTimesContinuo,
    required OperationTemplate? activeTemplate,
  }) {
    if (mode != StopwatchMode.continuo) {
      return 0;
    }

    final doneItems = recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
    if (doneItems.isEmpty) {
      return 0;
    }

    if (activeTemplate != null && doneItems.length % activeTemplate.steps.length == 0) {
      return 0;
    } else {
      return doneItems.last['cumulative_time'] as int;
    }
  }
}
