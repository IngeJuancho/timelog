import 'dart:convert';
import 'package:isar/isar.dart';

part 'models.g.dart';

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

@collection
class StudyModel {
  Id id = Isar.autoIncrement; 

  late String name;
  late DateTime date;
  
  @enumerated
  late StopwatchMode mode;

  List<TimeRecord> times = [];

  bool isTemplate = false;
  List<String> templateSteps = [];

  String? cycleRatingsJson;

  @ignore
  Map<int, int> get cycleRatingsMap {
    if (cycleRatingsJson == null || cycleRatingsJson!.isEmpty) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(cycleRatingsJson!);
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  set cycleRatingsMap(Map<int, int> ratings) {
    if (ratings.isEmpty) {
      cycleRatingsJson = null;
    } else {
      cycleRatingsJson = jsonEncode(ratings.map((k, v) => MapEntry(k.toString(), v)));
    }
  }
}

@embedded
class TimeRecord {
  String? name;
  int? time;             
  String? type;          
  int? cumulativeTime;
  int? stepIndex; 
}

// --- NUEVA ESTRUCTURA DE CARPETAS ---
@collection
class TemplateFolder {
  Id id = Isar.autoIncrement;
  late String name;
}

@collection
class OperationTemplate {
  Id id = Isar.autoIncrement;
  
  late String name;
  List<String> steps = [];
  
  // NUEVO: Identificador de la carpeta a la que pertenece (null = carpeta principal)
  int? folderId; 
}