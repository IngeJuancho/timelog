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
}

@embedded
class TimeRecord {
  String? name;
  int? time;             
  String? type;          
  int? cumulativeTime;   
}

// --- NUEVA ESTRUCTURA PARA PLANTILLAS DE OPERACIÓN ---
@collection
class OperationTemplate {
  Id id = Isar.autoIncrement;
  
  late String name;
  List<String> steps = [];
}