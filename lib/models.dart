import 'package:flutter/material.dart';

enum StopwatchMode { regresoACero, continuo }

enum PhysicalButtonAction {
  none,
  startStop,
  lapSnapback,
  stopAndRecord,
  reset
}

enum HapticLevel { light, medium, heavy }

enum TimeFormat { standard, seconds, minutes }

// Estructura para el historial de estudios
class StudyModel {
  final String id;
  final String name;
  final DateTime date;
  final StopwatchMode mode;
  final List<Map<String, dynamic>> times;

  StudyModel({
    required this.id,
    required this.name,
    required this.date,
    required this.mode,
    required this.times,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'mode': mode.index,
        'times': times,
      };

  factory StudyModel.fromJson(Map<String, dynamic> json) => StudyModel(
        id: json['id'],
        name: json['name'],
        date: DateTime.parse(json['date']),
        mode: StopwatchMode.values[json['mode']],
        times: List<Map<String, dynamic>>.from(json['times']),
      );
}