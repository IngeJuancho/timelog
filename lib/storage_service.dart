import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';

class StorageService {
  static Isar? _isar;

  static Future<Isar> get db async {
    if (_isar != null) return _isar!;
    
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [StudyModelSchema, OperationTemplateSchema], // Añadimos el esquema de plantillas
      directory: dir.path,
    );
    
    return _isar!;
  }

  Future<void> saveActiveTimeData(List<Map<String, dynamic>> rac, List<Map<String, dynamic>> cont) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('times_rac', jsonEncode(rac));
    await prefs.setString('times_cont', jsonEncode(cont));
  }

  List<TimeRecord> _mapToTimeRecords(List<Map<String, dynamic>> rawTimes) {
    return rawTimes.map((e) {
      return TimeRecord()
        ..name = e['name'] as String?
        ..time = e['time'] as int?
        ..type = e['type'] as String?
        ..cumulativeTime = e['cumulative_time'] as int?
        ..stepIndex = e['step_index'] as int?; // NUEVO: Atrapamos el índice
    }).toList();
  }

  Future<int> saveStudyToHistory({
    required String name,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
    OperationTemplate? template, // NUEVO: Recibimos la plantilla
  }) async {
    final isar = await db;
    final newStudy = StudyModel()
      ..name = name
      ..date = DateTime.now()
      ..mode = mode
      ..times = _mapToTimeRecords(times)
      ..isTemplate = template != null // Marcamos que es plantilla
      ..templateSteps = template?.steps ?? []; // Guardamos una copia de seguridad de los pasos
    
    await isar.writeTxn(() async {
      await isar.studyModels.put(newStudy); 
    });
    return newStudy.id; 
  }

  Future<void> updateExistingStudy({
    required int id,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
    OperationTemplate? template, // NUEVO: Recibimos la plantilla
  }) async {
    final isar = await db;
    final existingStudy = await isar.studyModels.get(id);
    
    if (existingStudy != null) {
      existingStudy.date = DateTime.now(); 
      existingStudy.mode = mode;
      existingStudy.times = _mapToTimeRecords(times);
      
      // Si hay plantilla, actualizamos la memoria del estudio
      if (template != null) {
        existingStudy.isTemplate = true;
        existingStudy.templateSteps = template.steps;
      }
      
      await isar.writeTxn(() async {
        await isar.studyModels.put(existingStudy);
      });
    }
  }

  Future<List<StudyModel>> getStudiesHistory() async {
    final isar = await db;
    return await isar.studyModels.where().findAll();
  }

  Future<void> deleteStudyFromHistory(int id) async { 
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.studyModels.delete(id); 
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

  // --- MÉTODOS PARA PLANTILLAS DE SECUENCIA ---

  Future<List<OperationTemplate>> getTemplates() async {
    final isar = await db;
    return await isar.operationTemplates.where().findAll();
  }

  Future<void> saveTemplate(String name, List<String> steps) async {
    final isar = await db;
    final template = OperationTemplate()
      ..name = name
      ..steps = steps;
    await isar.writeTxn(() async {
      await isar.operationTemplates.put(template);
    });
  }

  // NUEVO: Para actualizar el nombre de una plantilla existente
  Future<void> updateTemplateName(int id, String newName) async {
    final isar = await db;
    final template = await isar.operationTemplates.get(id);
    if (template != null) {
      template.name = newName;
      await isar.writeTxn(() async {
        await isar.operationTemplates.put(template);
      });
    }
  }

  // NUEVO: Para actualizar la lista de pasos completa de una plantilla
  Future<void> updateTemplateSteps(int id, List<String> newSteps) async {
    final isar = await db;
    final template = await isar.operationTemplates.get(id);
    if (template != null) {
      template.steps = newSteps;
      await isar.writeTxn(() async {
        await isar.operationTemplates.put(template);
      });
    }
  }

  Future<void> deleteTemplate(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.operationTemplates.delete(id);
    });
  }

  Future<String?> exportTemplate(OperationTemplate template) async {
    try {
      final Map<String, dynamic> data = {
        'name': template.name,
        'steps': template.steps,
      };
      final String jsonStr = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      
      final fileName = 'Plantilla_${template.name.replaceAll(' ', '_')}';
      final result = await FileSaver.instance.saveAs(name: fileName, bytes: bytes, ext: 'json', mimeType: MimeType.json);
      return result != null ? '$fileName.json' : null;
    } catch (e) {
      throw Exception("Error al exportar: $e");
    }
  }

  Future<bool> importTemplate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return false;
      
      Uint8List? fileBytes = result.files.first.bytes;
      if (fileBytes == null && result.files.first.path != null) {
        fileBytes = File(result.files.first.path!).readAsBytesSync();
      }
      if (fileBytes == null) return false;

      final String jsonString = utf8.decode(fileBytes);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey('name') && data.containsKey('steps')) {
        List<String> steps = List<String>.from(data['steps']);
        await saveTemplate(data['name'], steps);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception("Error al importar archivo: Formato incorrecto.");
    }
  }
}