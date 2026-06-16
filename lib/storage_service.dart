import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _historyKey = 'studies_history';

  // Guarda la sesión activa actual
  Future<void> saveActiveTimeData(List<Map<String, dynamic>> rac, List<Map<String, dynamic>> cont) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('times_rac', jsonEncode(rac));
    await prefs.setString('times_cont', jsonEncode(cont));
  }

  // Guarda un estudio completo en el historial simulando una base de datos
  Future<void> saveStudyToHistory({
    required String name,
    required StopwatchMode mode,
    required List<Map<String, dynamic>> times,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StudyModel> history = await getStudiesHistory();
    
    final newStudy = StudyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      date: DateTime.now(),
      mode: mode,
      times: List<Map<String, dynamic>>.from(times), // Copia profunda
    );
    
    history.add(newStudy);
    final historyJson = history.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  // Recupera el historial completo
  Future<List<StudyModel>> getStudiesHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);
    
    if (historyString == null) return [];
    
    final List<dynamic> decoded = jsonDecode(historyString);
    return decoded.map((e) => StudyModel.fromJson(e)).toList();
  }

  // Elimina un estudio del historial
  Future<void> deleteStudyFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<StudyModel> history = await getStudiesHistory();
    
    history.removeWhere((study) => study.id == id);
    
    final historyJson = history.map((e) => e.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }
}