import 'package:flutter_test/flutter_test.dart';
import 'package:timelog/models.dart';
import 'package:timelog/services/time_log_calculator.dart';

void main() {
  group('TimeLogCalculator Tests', () {
    test('Free mode calculates single operation statistics accurately', () {
      final freeData = [
        {'time': 10000, 'status': 'done', 'type': 'normal'},
        {'time': 12000, 'status': 'done', 'type': 'normal'},
        {'time': 11000, 'status': 'done', 'type': 'normal'},
      ];

      final stats = TimeLogCalculator.calculate(freeData);
      expect(stats.hasTemplate, false);
      expect(stats.averageTime, 11000.0);
      expect(stats.minTime, 10000.0);
      expect(stats.maxTime, 12000.0);
      expect(stats.completedCycles, 3);
      expect(stats.totalValidSamples, 3);
      expect(stats.stdDev, 1000.0);
    });

    test('Multi-step template calculates true cycle time and per-element breakdown', () {
      final template = OperationTemplate()
        ..name = 'Ensamble'
        ..steps = ['Tomar', 'Soldar', 'Inspeccionar'];

      // Cycle 0: 2s, 50s, 4s = 56s
      // Cycle 1: 3s, 52s, 5s = 60s
      final studyData = [
        {'step_index': 0, 'cycle_index': 0, 'name': 'Tomar', 'time': 2000, 'status': 'done', 'type': 'normal'},
        {'step_index': 1, 'cycle_index': 0, 'name': 'Soldar', 'time': 50000, 'status': 'done', 'type': 'normal'},
        {'step_index': 2, 'cycle_index': 0, 'name': 'Inspeccionar', 'time': 4000, 'status': 'done', 'type': 'normal'},

        {'step_index': 0, 'cycle_index': 1, 'name': 'Tomar', 'time': 3000, 'status': 'done', 'type': 'normal'},
        {'step_index': 1, 'cycle_index': 1, 'name': 'Soldar', 'time': 52000, 'status': 'done', 'type': 'normal'},
        {'step_index': 2, 'cycle_index': 1, 'name': 'Inspeccionar', 'time': 5000, 'status': 'done', 'type': 'normal'},
      ];

      final stats = TimeLogCalculator.calculate(studyData, activeTemplate: template);

      // Cycle-level statistics:
      expect(stats.hasTemplate, true);
      expect(stats.completedCycles, 2);
      expect(stats.averageTime, 58000.0); // (56000 + 60000) / 2
      expect(stats.minTime, 56000.0);
      expect(stats.maxTime, 60000.0);

      // Granular step statistics:
      expect(stats.stepStatistics.length, 3);

      final step0 = stats.stepStatistics[0];
      expect(step0.stepName, 'Tomar');
      expect(step0.averageTime, 2500.0);
      expect(step0.minTime, 2000.0);
      expect(step0.maxTime, 3000.0);
      expect(step0.sampleCount, 2);

      final step1 = stats.stepStatistics[1];
      expect(step1.stepName, 'Soldar');
      expect(step1.averageTime, 51000.0);
      expect(step1.minTime, 50000.0);
      expect(step1.maxTime, 52000.0);

      final step2 = stats.stepStatistics[2];
      expect(step2.stepName, 'Inspeccionar');
      expect(step2.averageTime, 4500.0);
      expect(step2.minTime, 4000.0);
      expect(step2.maxTime, 5000.0);
    });

    test('Outliers are excluded from both element and cycle statistics', () {
      final template = OperationTemplate()
        ..name = 'Ensamble'
        ..steps = ['Paso 1', 'Paso 2'];

      final studyData = [
        {'step_index': 0, 'cycle_index': 0, 'name': 'Paso 1', 'time': 10000, 'status': 'done', 'type': 'normal'},
        {'step_index': 1, 'cycle_index': 0, 'name': 'Paso 2', 'time': 20000, 'status': 'done', 'type': 'normal'},

        {'step_index': 0, 'cycle_index': 1, 'name': 'Paso 1', 'time': 10000, 'status': 'done', 'type': 'normal'},
        {'step_index': 1, 'cycle_index': 1, 'name': 'Paso 2', 'time': 99999, 'status': 'done', 'type': 'outlier'}, // Excluded
      ];

      final stats = TimeLogCalculator.calculate(studyData, activeTemplate: template);

      // Paso 1 has 2 samples, Paso 2 has 1 valid sample
      expect(stats.stepStatistics[0].sampleCount, 2);
      expect(stats.stepStatistics[1].sampleCount, 1);
      expect(stats.stepStatistics[1].averageTime, 20000.0);
    });
  });
}
