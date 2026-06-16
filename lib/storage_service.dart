import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _historyKey = 'studies_history';

  Future<void> saveActiveTimeData(List<Map<String, dynamic>> rac, List<Map<String, dynamic>> cont) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('times_rac', jsonEncode(rac));
    await prefs.setString('times_cont', jsonEncode(cont));
  }

  Future<String> saveStudyToHistory({
    required String name,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StudyModel> history = await getStudiesHistory();
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newStudy = StudyModel(
      id: newId,
      name: name,
      date: DateTime.now(),
      mode: mode,
      times: List<Map<String, dynamic>>.from(times), 
    );
    
    history.add(newStudy);
    final historyJson = history.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
    
    return newId;
  }

  // Nueva función para sobrescribir los datos de un estudio ya existente
  Future<void> updateExistingStudy({
    required String id,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StudyModel> history = await getStudiesHistory();
    
    final index = history.indexWhere((study) => study.id == id);
    if (index != -1) {
      final oldStudy = history[index];
      history[index] = StudyModel(
        id: oldStudy.id,
        name: oldStudy.name, // Mantenemos el nombre original
        date: DateTime.now(), // Actualizamos la fecha de última modificación
        mode: mode,
        times: List<Map<String, dynamic>>.from(times),
      );
      final historyJson = history.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    }
  }

  Future<List<StudyModel>> getStudiesHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);
    
    if (historyString == null) return [];
    
    final List<dynamic> decoded = jsonDecode(historyString);
    return decoded.map((e) => StudyModel.fromJson(e)).toList();
  }

  Future<void> deleteStudyFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StudyModel> history = await getStudiesHistory();
    
    history.removeWhere((study) => study.id == id);
    
    final historyJson = history.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  Future<void> updateStudyName(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StudyModel> history = await getStudiesHistory();
    
    final index = history.indexWhere((study) => study.id == id);
    if (index != -1) {
      final oldStudy = history[index];
      history[index] = StudyModel(
        id: oldStudy.id,
        name: newName,
        date: oldStudy.date,
        mode: oldStudy.mode,
        times: oldStudy.times,
      );
      final historyJson = history.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    }
  }
}