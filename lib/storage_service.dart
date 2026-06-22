import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'models.dart';

class StorageService {
  static late Isar _isar;
  static bool _isInitialized = false;

  Future<Isar> get db async {
    if (_isInitialized) return _isar;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [StudyModelSchema, OperationTemplateSchema, TemplateFolderSchema],
      directory: dir.path,
    );
    _isInitialized = true;
    return _isar;
  }

  // ===========================================================================
  // MANEJO DE HISTORIAL DE ESTUDIOS
  // ===========================================================================
  List<TimeRecord> _mapToTimeRecords(List<Map<String, dynamic>> rawTimes) {
    return rawTimes.map((e) {
      return TimeRecord()
        ..name = e['name'] as String?
        ..time = e['time'] as int?
        ..type = e['type'] as String?
        ..cumulativeTime = e['cumulative_time'] as int?
        ..stepIndex = e['step_index'] as int?;
    }).toList();
  }

  Future<int> saveStudyToHistory({
    required String name,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
    OperationTemplate? template,
  }) async {
    final isar = await db;
    final newStudy = StudyModel()
      ..name = name
      ..date = DateTime.now()
      ..mode = mode
      ..times = _mapToTimeRecords(times)
      ..isTemplate = template != null
      ..templateSteps = template?.steps ?? [];
    
    await isar.writeTxn(() async {
      await isar.studyModels.put(newStudy); 
    });
    return newStudy.id; 
  }

  Future<void> updateExistingStudy({
    required int id,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
    OperationTemplate? template,
  }) async {
    final isar = await db;
    final existingStudy = await isar.studyModels.get(id);
    
    if (existingStudy != null) {
      existingStudy.date = DateTime.now(); 
      existingStudy.mode = mode;
      existingStudy.times = _mapToTimeRecords(times);
      
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
    return await isar.studyModels.where().sortByDateDesc().findAll();
  }

  Future<void> deleteStudyFromHistory(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.studyModels.delete(id);
    });
  }

  Future<void> updateStudyName(int id, String newName) async {
    final isar = await db;
    final study = await isar.studyModels.get(id);
    if (study != null) {
      study.name = newName;
      await isar.writeTxn(() async {
        await isar.studyModels.put(study);
      });
    }
  }

  // ===========================================================================
  // MANEJO DE CARPETAS
  // ===========================================================================
  Future<List<TemplateFolder>> getFolders() async {
    final isar = await db;
    return await isar.templateFolders.where().sortByName().findAll();
  }

  Future<int> createFolder(String name) async {
    final isar = await db;
    final folder = TemplateFolder()..name = name;
    await isar.writeTxn(() async {
      await isar.templateFolders.put(folder);
    });
    return folder.id;
  }

  Future<void> updateFolderName(int id, String newName) async {
    final isar = await db;
    final folder = await isar.templateFolders.get(id);
    if (folder != null) {
      folder.name = newName;
      await isar.writeTxn(() async {
        await isar.templateFolders.put(folder);
      });
    }
  }

  Future<void> deleteFolder(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.operationTemplates.filter().folderIdEqualTo(id).deleteAll();
      await isar.templateFolders.delete(id);
    });
  }

  // ===========================================================================
  // MANEJO DE PLANTILLAS (RUTAS ESTÁNDAR)
  // ===========================================================================

  // NUEVO: Método para traer absolutamente TODAS las plantillas (para el cronómetro)
  Future<List<OperationTemplate>> getAllTemplates() async {
    final isar = await db;
    return await isar.operationTemplates.where().sortByName().findAll();
  }
  
  Future<List<OperationTemplate>> getTemplates({int? folderId}) async {
    final isar = await db;
    if (folderId == null) {
      return await isar.operationTemplates.filter().folderIdIsNull().sortByName().findAll();
    } else {
      return await isar.operationTemplates.filter().folderIdEqualTo(folderId).sortByName().findAll();
    }
  }

  Future<void> saveTemplate(String name, List<String> steps, {int? folderId}) async {
    final isar = await db;
    final template = OperationTemplate()
      ..name = name
      ..steps = steps
      ..folderId = folderId; 
      
    await isar.writeTxn(() async {
      await isar.operationTemplates.put(template);
    });
  }

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

  // --- IMPORTAR / EXPORTAR PLANTILLAS (FORMATO JSON) ---
  Future<String?> exportTemplate(OperationTemplate template) async {
    try {
      final Map<String, dynamic> data = {
        'name': template.name,
        'steps': template.steps,
      };
      String jsonString = jsonEncode(data);
      Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      final date = DateTime.now();
      final baseName = template.name.replaceAll(' ', '_');
      final fileName = 'Ruta_${baseName}_${date.year}${date.month}${date.day}';

      final result = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        ext: 'json',
        mimeType: MimeType.json
      );
      return result != null ? '$fileName.json' : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> importTemplate({int? currentFolderId}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) return false;

      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = File(result.files.first.path!).readAsBytesSync();
      }
      if (bytes == null) return false;

      String jsonString = utf8.decode(bytes);
      Map<String, dynamic> data = jsonDecode(jsonString);
      
      if (data.containsKey('name') && data.containsKey('steps')) {
        String name = data['name'];
        List<String> steps = List<String>.from(data['steps']);
        await saveTemplate(name, steps, folderId: currentFolderId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- NUEVO: IMPORTACIÓN MASIVA SELECCIONANDO MÚLTIPLES ARCHIVOS ---
  Future<bool> importMultipleTemplates({int? targetFolderId, String? newFolderName}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // LA MAGIA ESTÁ AQUÍ
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) return false;

      // Si estamos en raíz, creamos la carpeta con el nombre que nos dio el usuario
      int folderIdToUse = targetFolderId ?? await createFolder(newFolderName ?? "Rutas Importadas");
      bool importedAny = false;

      // Leemos todos los archivos seleccionados de forma segura
      for (var file in result.files) {
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = File(file.path!).readAsBytesSync();
        }
        
        if (bytes != null) {
          try {
            String jsonString = utf8.decode(bytes);
            Map<String, dynamic> data = jsonDecode(jsonString);
            
            if (data.containsKey('name') && data.containsKey('steps')) {
              String name = data['name'];
              List<String> steps = List<String>.from(data['steps']);
              
              await saveTemplate(name, steps, folderId: folderIdToUse);
              importedAny = true;
            }
          } catch (_) {
            // Si un archivo no es válido, lo saltamos silenciosamente
          }
        }
      }

      // Si falló todo y habíamos creado una carpeta nueva en la raíz, la borramos para no dejar basura
      if (!importedAny && targetFolderId == null) {
        await deleteFolder(folderIdToUse);
        return false;
      }

      return importedAny;
    } catch (e) {
      return false;
    }
  }
}