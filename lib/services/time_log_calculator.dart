import 'dart:math';
import '../models.dart';

class StepStatistics {
  final String stepName;
  final int stepIndex;
  final double averageTime;
  final double minTime;
  final double maxTime;
  final double stdDev;
  final int sampleCount;

  const StepStatistics({
    required this.stepName,
    required this.stepIndex,
    this.averageTime = 0.0,
    this.minTime = 0.0,
    this.maxTime = 0.0,
    this.stdDev = 0.0,
    this.sampleCount = 0,
  });
}

class StatisticsResult {
  final double averageTime;
  final double minTime;
  final double maxTime;
  final double stdDev;
  final int completedCycles;
  final int totalValidSamples;
  final bool hasTemplate;
  final List<StepStatistics> stepStatistics;

  const StatisticsResult({
    this.averageTime = 0.0,
    this.minTime = 0.0,
    this.maxTime = 0.0,
    this.stdDev = 0.0,
    this.completedCycles = 0,
    this.totalValidSamples = 0,
    this.hasTemplate = false,
    this.stepStatistics = const [],
  });
}

class TimeLogCalculator {
  static StatisticsResult calculate(
    List<Map<String, dynamic>> currentList, {
    OperationTemplate? activeTemplate,
    StopwatchMode mode = StopwatchMode.regresoACero,
  }) {
    if (currentList.isEmpty) {
      return const StatisticsResult();
    }

    final bool hasTemplate = activeTemplate != null && activeTemplate.steps.length > 1;

    final validRecords = currentList
        .where((e) =>
            (e['type'] ?? 'normal') != 'outlier' &&
            (e['type'] ?? 'normal') != 'merged' &&
            ((e['time'] as num?)?.toInt() ?? 0) > 0 &&
            e['status'] != 'pending')
        .toList();

    if (validRecords.isEmpty) {
      return const StatisticsResult();
    }

    if (!hasTemplate) {
      final validTimes = validRecords
          .map((e) => (e['time'] as num?)?.toInt() ?? 0)
          .toList();

      double avg = validTimes.reduce((a, b) => a + b) / validTimes.length;
      double mTime = validTimes.reduce(min).toDouble();
      double mxTime = validTimes.reduce(max).toDouble();
      double sDev = 0.0;

      if (validTimes.length > 1) {
        final variance = validTimes
                .map((t) => pow(t - avg, 2))
                .reduce((a, b) => a + b) /
            (validTimes.length - 1);
        sDev = sqrt(variance);
      }

      final singleStepStat = StepStatistics(
        stepName: currentList.isNotEmpty ? (currentList[0]['name']?.toString() ?? 'Operación') : 'Operación',
        stepIndex: 0,
        averageTime: avg,
        minTime: mTime,
        maxTime: mxTime,
        stdDev: sDev,
        sampleCount: validTimes.length,
      );

      return StatisticsResult(
        averageTime: avg,
        minTime: mTime,
        maxTime: mxTime,
        stdDev: sDev,
        completedCycles: validTimes.length,
        totalValidSamples: validTimes.length,
        hasTemplate: false,
        stepStatistics: [singleStepStat],
      );
    }

    // MULTI-STEP TEMPLATE
    final numSteps = activeTemplate.steps.length;
    final List<StepStatistics> stepStatsList = [];

    for (int s = 0; s < numSteps; s++) {
      final stepName = activeTemplate.steps[s];
      final stepRecords = validRecords.where((e) {
        if (e['step_index'] != null) {
          return e['step_index'] == s;
        }
        return e['name']?.toString() == stepName;
      }).map((e) => (e['time'] as num?)?.toInt() ?? 0).toList();

      if (stepRecords.isEmpty) {
        stepStatsList.add(StepStatistics(
          stepName: stepName,
          stepIndex: s,
          averageTime: 0.0,
          minTime: 0.0,
          maxTime: 0.0,
          stdDev: 0.0,
          sampleCount: 0,
        ));
      } else {
        double sAvg = stepRecords.reduce((a, b) => a + b) / stepRecords.length;
        double sMin = stepRecords.reduce(min).toDouble();
        double sMax = stepRecords.reduce(max).toDouble();
        double sStdDev = 0.0;
        if (stepRecords.length > 1) {
          final sVar = stepRecords
                  .map((t) => pow(t - sAvg, 2))
                  .reduce((a, b) => a + b) /
              (stepRecords.length - 1);
          sStdDev = sqrt(sVar);
        }

        stepStatsList.add(StepStatistics(
          stepName: stepName,
          stepIndex: s,
          averageTime: sAvg,
          minTime: sMin,
          maxTime: sMax,
          stdDev: sStdDev,
          sampleCount: stepRecords.length,
        ));
      }
    }

    // Grouping by cycle for complete cycle calculation
    final Map<int, List<int>> cyclesMap = {};
    for (int i = 0; i < currentList.length; i++) {
      final record = currentList[i];
      if (record['status'] == 'pending') continue;

      int cIndex = (record['cycle_index'] as num?)?.toInt() ?? (i ~/ numSteps);

      if ((record['type'] ?? 'normal') != 'outlier' &&
          ((record['time'] as num?)?.toInt() ?? 0) > 0) {
        cyclesMap.putIfAbsent(cIndex, () => []).add((record['time'] as num).toInt());
      }
    }

    final List<int> completeCycleTimes = [];
    cyclesMap.forEach((cIdx, times) {
      if (times.length == numSteps) {
        completeCycleTimes.add(times.reduce((a, b) => a + b));
      }
    });

    double cycleAvg = 0.0;
    double cycleMin = 0.0;
    double cycleMax = 0.0;
    double cycleStdDev = 0.0;

    if (completeCycleTimes.isNotEmpty) {
      cycleAvg = completeCycleTimes.reduce((a, b) => a + b) / completeCycleTimes.length;
      cycleMin = completeCycleTimes.reduce(min).toDouble();
      cycleMax = completeCycleTimes.reduce(max).toDouble();
      if (completeCycleTimes.length > 1) {
        final variance = completeCycleTimes
                .map((t) => pow(t - cycleAvg, 2))
                .reduce((a, b) => a + b) /
            (completeCycleTimes.length - 1);
        cycleStdDev = sqrt(variance);
      }
    } else {
      cycleAvg = stepStatsList.map((s) => s.averageTime).fold(0.0, (a, b) => a + b);
      cycleMin = stepStatsList.map((s) => s.minTime).fold(0.0, (a, b) => a + b);
      cycleMax = stepStatsList.map((s) => s.maxTime).fold(0.0, (a, b) => a + b);
      double sumVariances = stepStatsList.map((s) => pow(s.stdDev, 2)).fold(0.0, (a, b) => a + b);
      cycleStdDev = sqrt(sumVariances);
    }

    return StatisticsResult(
      averageTime: cycleAvg,
      minTime: cycleMin,
      maxTime: cycleMax,
      stdDev: cycleStdDev,
      completedCycles: completeCycleTimes.length,
      totalValidSamples: validRecords.length,
      hasTemplate: true,
      stepStatistics: stepStatsList,
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

    if (activeTemplate != null &&
        activeTemplate.steps.isNotEmpty &&
        doneItems.length % activeTemplate.steps.length == 0) {
      return 0;
    } else {
      return (doneItems.last['cumulative_time'] as num?)?.toInt() ?? 0;
    }
  }
}
