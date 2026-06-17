import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class StorageService {
  static Isar? _isar;

  // Inicialización perezosa de la bóveda de la base de datos
  static Future<Isar> get db async {
    if (_isar != null) return _isar!;
    
    // Buscamos la carpeta segura nativa del teléfono (iOS/Android)
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [StudyModelSchema], // El esquema generado automáticamente
      directory: dir.path,
    );
    
    return _isar!;
  }

  // Mantenemos el estado activo/volátil en SharedPreferences para máxima agilidad en el cronómetro
  Future<void> saveActiveTimeData(List<Map<String, dynamic>> rac, List<Map<String, dynamic>> cont) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('times_rac', jsonEncode(rac));
    await prefs.setString('times_cont', jsonEncode(cont));
  }

  // --- MÉTODOS DE BASE DE DATOS (ISAR) ---

  // Método privado para convertir Mapas volátiles a Objetos estrictos de memoria
  List<TimeRecord> _mapToTimeRecords(List<Map<String, dynamic>> rawTimes) {
    return rawTimes.map((e) {
      return TimeRecord()
        ..name = e['name'] as String?
        ..time = e['time'] as int?
        ..type = e['type'] as String?
        ..cumulativeTime = e['cumulative_time'] as int?;
    }).toList();
  }

  Future<int> saveStudyToHistory({
    required String name,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
  }) async {
    final isar = await db;
    
    final newStudy = StudyModel()
      ..name = name
      ..date = DateTime.now()
      ..mode = mode
      ..times = _mapToTimeRecords(times);
    
    // Transacción atómica de escritura
    await isar.writeTxn(() async {
      await isar.studyModels.put(newStudy); // Isar asigna el ID automáticamente
    });
    
    return newStudy.id; // Retorna el número de identificación (int)
  }

  Future<void> updateExistingStudy({
    required int id, // Ahora usamos int en lugar de String
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
  }) async {
    final isar = await db;
    
    final existingStudy = await isar.studyModels.get(id);
    
    if (existingStudy != null) {
      existingStudy.date = DateTime.now(); // Actualizamos la fecha
      existingStudy.mode = mode;
      existingStudy.times = _mapToTimeRecords(times);
      
      await isar.writeTxn(() async {
        await isar.studyModels.put(existingStudy);
      });
    }
  }

  Future<List<StudyModel>> getStudiesHistory() async {
    final isar = await db;
    // Consulta directa de ultra-alta velocidad (sin parsear JSON)
    return await isar.studyModels.where().findAll();
  }

  Future<void> deleteStudyFromHistory(int id) async { 
    final isar = await db;
    
    await isar.writeTxn(() async {
      await isar.studyModels.delete(id); // Destruye únicamente ese registro al instante
    });
  }

  Future<void> updateStudyName(int id, String newName) async { 
    final isar = await db;
    final existingStudy = await isar.studyModels.get(id);
    
    if (existingStudy != null) {
      existingStudy.name = newName;
      await isar.writeTxn(() async {
        await isar.studyModels.put(existingStudy);
      });
    }
  }
}