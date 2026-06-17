import 'package:isar/isar.dart';

// Esta línea marcará error hasta que ejecutemos el comando en la Fase 2. 
// Es el archivo que Isar construirá automáticamente por nosotros.
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

// --- NUEVOS PLANOS ESTRICTOS PARA LA BASE DE DATOS ---

@collection
class StudyModel {
  // Isar exige que el ID principal sea un número entero (Id). 
  // 'autoIncrement' hace que Isar asigne el 1, 2, 3... automáticamente.
  Id id = Isar.autoIncrement; 

  late String name;
  late DateTime date;
  
  // Guardamos el Enum directamente, Isar se encarga de traducirlo a la BD
  @enumerated
  late StopwatchMode mode;

  // Lista estricta de objetos, adiós a los Mapas frágiles y JSON
  List<TimeRecord> times = [];
}

// @embedded significa que estos registros no tienen una tabla propia, 
// sino que viven "incrustados" dentro del StudyModel que los contiene.
@embedded
class TimeRecord {
  String? name;
  int? time;             // Tiempo Observado (TO)
  String? type;          // normal o outlier
  int? cumulativeTime;   // Tiempo Acumulado (TC)
}