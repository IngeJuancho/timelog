// lib/time_log_controller.dart
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'models.dart';
import 'main.dart'; 

final timeLogProvider = ChangeNotifierProvider<TimeLogController>((ref) => TimeLogController());

class TimeLogController extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  
  // Novedad: Tiempo base para anclar el cronómetro tras cierres o borrados
  int _baseTimeMs = 0;
  
  VoidCallback? onAnimateStart;
  VoidCallback? onAnimateSecondary;
  VoidCallback? onAnimateReset;
  VoidCallback? onAnimateExport;
  VoidCallback? onRequestResetDialog; 

  final TextEditingController taskNameController = TextEditingController();

  List<Map<String, dynamic>> recordedTimesRegresoACero = [];
  List<Map<String, dynamic>> recordedTimesContinuo = [];

  List<Map<String, dynamic>> get activeRecordedTimes =>
      currentMode == StopwatchMode.regresoACero ? recordedTimesRegresoACero : recordedTimesContinuo;

  double averageTime = 0.0;
  double minTime = 0.0;
  double maxTime = 0.0;
  double stdDev = 0.0;

  StopwatchMode currentMode = StopwatchMode.regresoACero;
  int _lastRecordedTimeMs = 0;
  bool hasExported = true;

  bool usePhysicalButtons = false;
  bool useHapticFeedback = false;
  HapticLevel hapticLevel = HapticLevel.medium;
  bool recordOnPause = false;
  TimeFormat timeFormat = TimeFormat.standard; 

  PhysicalButtonAction volUpActionRAC = PhysicalButtonAction.lapSnapback;
  PhysicalButtonAction volDownActionRAC = PhysicalButtonAction.stopAndRecord;
  PhysicalButtonAction volUpActionCont = PhysicalButtonAction.lapSnapback;
  PhysicalButtonAction volDownActionCont = PhysicalButtonAction.stopAndRecord;

  static const platform = MethodChannel('com.timelog/volume_buttons');

  bool get isRunning => _stopwatch.isRunning;
  
  // Novedad: El tiempo mostrado es la suma del cronómetro actual + el tiempo base anclado
  int get elapsedMilliseconds => _baseTimeMs + _stopwatch.elapsedMilliseconds;

  TimeLogController() {
    _initNativeButtonListener();
    loadAllData();
  }

  Future<void> loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    usePhysicalButtons = prefs.getBool('usePhysicalButtons') ?? false;
    useHapticFeedback = prefs.getBool('useHapticFeedback') ?? false;
    recordOnPause = prefs.getBool('recordOnPause') ?? false;
    
    int hapticIndex = prefs.getInt('hapticLevel') ?? HapticLevel.medium.index;
    hapticLevel = HapticLevel.values[hapticIndex];

    int formatIndex = prefs.getInt('timeFormat') ?? TimeFormat.standard.index;
    timeFormat = TimeFormat.values[formatIndex];

    volUpActionRAC = PhysicalButtonAction.values[prefs.getInt('volUpActionRAC') ?? PhysicalButtonAction.lapSnapback.index];
    volDownActionRAC = PhysicalButtonAction.values[prefs.getInt('volDownActionRAC') ?? PhysicalButtonAction.stopAndRecord.index];
    volUpActionCont = PhysicalButtonAction.values[prefs.getInt('volUpActionCont') ?? PhysicalButtonAction.lapSnapback.index];
    volDownActionCont = PhysicalButtonAction.values[prefs.getInt('volDownActionCont') ?? PhysicalButtonAction.stopAndRecord.index];

    String? racJson = prefs.getString('times_rac');
    if (racJson != null) recordedTimesRegresoACero = List<Map<String, dynamic>>.from(jsonDecode(racJson));

    String? contJson = prefs.getString('times_cont');
    if (contJson != null) recordedTimesContinuo = List<Map<String, dynamic>>.from(jsonDecode(contJson));

    // Novedad: Si hay datos al abrir la app en modo continuo, recuperar el tiempo exacto
    if (currentMode == StopwatchMode.continuo && recordedTimesContinuo.isNotEmpty) {
      _lastRecordedTimeMs = recordedTimesContinuo.last['cumulative_time'] as int;
      _baseTimeMs = _lastRecordedTimeMs;
    } else {
      _lastRecordedTimeMs = 0;
      _baseTimeMs = 0;
    }

    calculateStatistics();
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usePhysicalButtons', usePhysicalButtons);
    await prefs.setBool('useHapticFeedback', useHapticFeedback);
    await prefs.setBool('recordOnPause', recordOnPause);
    await prefs.setInt('hapticLevel', hapticLevel.index);
    await prefs.setInt('timeFormat', timeFormat.index);
    await prefs.setInt('volUpActionRAC', volUpActionRAC.index);
    await prefs.setInt('volDownActionRAC', volDownActionRAC.index);
    await prefs.setInt('volUpActionCont', volUpActionCont.index);
    await prefs.setInt('volDownActionCont', volDownActionCont.index);
    notifyListeners();
  }

  Future<void> saveTimeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('times_rac', jsonEncode(recordedTimesRegresoACero));
    await prefs.setString('times_cont', jsonEncode(recordedTimesContinuo));
  }

  void _initNativeButtonListener() {
    platform.setMethodCallHandler((call) async {
      if (!usePhysicalButtons) return;
      if (call.method == 'volumeUp') _handleNativeButtonPress(isVolumeUp: true);
      else if (call.method == 'volumeDown') _handleNativeButtonPress(isVolumeUp: false);
    });
  }

  void triggerHaptic() {
    if (useHapticFeedback) {
      switch (hapticLevel) {
        case HapticLevel.light: HapticFeedback.lightImpact(); break;
        case HapticLevel.medium: HapticFeedback.mediumImpact(); break;
        case HapticLevel.heavy: HapticFeedback.heavyImpact(); break;
      }
    }
  }

  void setMode(StopwatchMode mode) {
    if (currentMode != mode) {
      currentMode = mode;
      bool wasRunning = _stopwatch.isRunning;
      _stopwatch.reset(); 
      
      // Ajustar el tiempo base según los datos del nuevo modo seleccionado
      if (currentMode == StopwatchMode.continuo && recordedTimesContinuo.isNotEmpty) {
         _lastRecordedTimeMs = recordedTimesContinuo.last['cumulative_time'] as int;
         _baseTimeMs = _lastRecordedTimeMs;
      } else {
         _lastRecordedTimeMs = 0;
         _baseTimeMs = 0;
      }
      
      if (wasRunning) _stopwatch.start();

      calculateStatistics();
      _showSnackBar('Modo: ${mode == StopwatchMode.regresoACero ? "Regreso a Cero" : "Continuo"}', Icons.settings, Colors.tealAccent);
      notifyListeners();
    }
  }

  void deleteItem(int index) {
    bool wasLast = index == activeRecordedTimes.length - 1;
    activeRecordedTimes.removeAt(index);
    
    // Novedad: Si borramos el último dato en modo continuo, el cronómetro retrocede visualmente
    if (currentMode == StopwatchMode.continuo && wasLast) {
      _lastRecordedTimeMs = activeRecordedTimes.isNotEmpty ? activeRecordedTimes.last['cumulative_time'] as int : 0;
      _baseTimeMs = _lastRecordedTimeMs; // Retrocedemos el contador
      
      bool wasRunning = _stopwatch.isRunning;
      _stopwatch.reset();
      if (wasRunning) _stopwatch.start();
    }
    
    saveTimeData();
    calculateStatistics();
    notifyListeners();
  }

  void _handleNativeButtonPress({required bool isVolumeUp}) {
    PhysicalButtonAction action = currentMode == StopwatchMode.regresoACero 
        ? (isVolumeUp ? volUpActionRAC : volDownActionRAC)
        : (isVolumeUp ? volUpActionCont : volDownActionCont);
    if (action != PhysicalButtonAction.none) executePhysicalAction(action);
  }

  void executePhysicalAction(PhysicalButtonAction action) {
    switch (action) {
      case PhysicalButtonAction.startStop:
        if (_stopwatch.isRunning) {
          stopTimerLogic();
          if (recordOnPause) recordTime(resetStopwatch: currentMode == StopwatchMode.regresoACero, keepRunning: false);
        } else {
          startTimerLogic();
        }
        onAnimateStart?.call();
        break;
      case PhysicalButtonAction.lapSnapback:
        if (_stopwatch.isRunning) {
          if (currentMode == StopwatchMode.regresoACero) {
            recordTime(resetStopwatch: true, keepRunning: true);
            onAnimateSecondary?.call();
          } else {
            recordTime(resetStopwatch: false, keepRunning: true);
            onAnimateStart?.call();
          }
        }
        break;
      case PhysicalButtonAction.stopAndRecord:
        if (_stopwatch.isRunning) {
          stopTimerLogic();
          recordTime(resetStopwatch: true, keepRunning: false);
          onAnimateStart?.call();
        }
        break;
      case PhysicalButtonAction.reset:
        onAnimateReset?.call();
        onRequestResetDialog?.call(); 
        break;
      case PhysicalButtonAction.none:
        break;
    }
  }

  void startTimerLogic() {
    if (!_stopwatch.isRunning) {
      triggerHaptic();
      if (currentMode == StopwatchMode.continuo && _baseTimeMs == 0 && _stopwatch.elapsedMilliseconds == 0) {
        _lastRecordedTimeMs = 0;
      }
      _stopwatch.start();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => notifyListeners());
      notifyListeners();
    }
  }

  void stopTimerLogic() {
    if (_stopwatch.isRunning) {
      triggerHaptic();
      _stopwatch.stop();
      _timer?.cancel();
      notifyListeners();
    }
  }

  void recordTime({required bool resetStopwatch, required bool keepRunning}) {
    final currentTimeMs = elapsedMilliseconds;
    int individualTimeMs = 0;
    final currentList = activeRecordedTimes;

    if (currentTimeMs == 0) return;
    if (currentMode == StopwatchMode.continuo && currentTimeMs <= _lastRecordedTimeMs && currentList.isNotEmpty) return;

    Map<String, dynamic> timeEntry = {};
    if (currentMode == StopwatchMode.continuo) {
      individualTimeMs = currentTimeMs - _lastRecordedTimeMs;
      timeEntry['cumulative_time'] = currentTimeMs;
      _lastRecordedTimeMs = currentTimeMs;
    } else {
      individualTimeMs = currentTimeMs;
    }

    if (individualTimeMs >= 0) {
      triggerHaptic();
      final name = taskNameController.text.isNotEmpty ? taskNameController.text : 'Ciclo ${currentList.length + 1}';
      timeEntry['name'] = name;
      timeEntry['time'] = individualTimeMs;

      currentList.add(timeEntry);
      hasExported = false;
      saveTimeData();
      calculateStatistics();
      _showSnackBarWithUndo('Registrado: ${formatTime(individualTimeMs.toDouble())}', Icons.check_circle, Colors.tealAccent);
    }

    if (resetStopwatch) {
      if (currentMode == StopwatchMode.regresoACero) {
        _stopwatch.reset();
        _baseTimeMs = 0; // Regresamos el contador a cero en este modo
      }
      // En modo continuo, omitimos resetear el tiempo base para no perder la secuencia acumulada
    }
    
    if (keepRunning) {
      if (!_stopwatch.isRunning) _stopwatch.start();
    } else {
      stopTimerLogic();
    }
    
    notifyListeners();
  }

  void undoLastRecord() {
    final currentList = activeRecordedTimes;
    if (currentList.isEmpty) return;

    currentList.removeLast();
    
    // Novedad: Lógica inversa inteligente para Deshacer
    if (currentMode == StopwatchMode.continuo) {
      _lastRecordedTimeMs = currentList.isNotEmpty ? currentList.last['cumulative_time'] as int : 0;
      _baseTimeMs = _lastRecordedTimeMs; // Retrocedemos el contador
      
      bool wasRunning = _stopwatch.isRunning;
      _stopwatch.reset();
      if (wasRunning) _stopwatch.start();
    }
    
    saveTimeData();
    calculateStatistics();
    notifyListeners();
    
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _showSnackBar('Último registro deshecho.', Icons.undo, Colors.orangeAccent);
  }

  void calculateStatistics() {
    final currentList = activeRecordedTimes;
    if (currentList.isEmpty) { averageTime = minTime = maxTime = stdDev = 0.0; return; }
    final validTimes = currentList.map((e) => e['time'] as int).where((t) => t > 0 || currentList.length == 1).toList();
    if (validTimes.isEmpty) { averageTime = minTime = maxTime = stdDev = 0.0; return; }
    
    averageTime = validTimes.reduce((a, b) => a + b) / validTimes.length;
    minTime = validTimes.reduce(min).toDouble();
    maxTime = validTimes.reduce(max).toDouble();
    if (validTimes.length > 1) {
      final variance = validTimes.map((t) => pow(t - averageTime, 2)).reduce((a, b) => a + b) / (validTimes.length - 1);
      stdDev = sqrt(variance);
    } else { stdDev = 0.0; }
  }

  void resetAll() {
    triggerHaptic();
    stopTimerLogic();
    _stopwatch.reset();
    _baseTimeMs = 0; // Reseteo total
    activeRecordedTimes.clear();
    saveTimeData();
    calculateStatistics();
    _lastRecordedTimeMs = 0;
    hasExported = true;
    notifyListeners();
  }

  Future<void> exportData() async {
    final currentList = activeRecordedTimes;
    if (currentList.isEmpty) {
      _showSnackBar('No hay datos para exportar.', Icons.warning_amber_rounded, Colors.orange);
      return;
    }
    try {
      List<List<dynamic>> csvData;
      List<String> headers;
      String modeName = currentMode == StopwatchMode.continuo ? "Continuo" : "RegresoACero";
      if (currentMode == StopwatchMode.continuo) {
        headers = ['#', 'Nombre', 'TC (ms)', 'TC Formateado', 'TO (ms)', 'TO Formateado'];
        csvData = [headers, ...currentList.asMap().entries.map((entry) {
            int index = entry.key; Map<String, dynamic> timeData = entry.value;
            return [index + 1, timeData['name'], timeData['cumulative_time'] ?? 0, formatTime((timeData['cumulative_time'] ?? 0).toDouble()), timeData['time'], formatTime(timeData['time'].toDouble())];
          })];
      } else {
        headers = ['#', 'Nombre', 'Tiempo (ms)', 'Tiempo Formateado'];
        csvData = [headers, ...currentList.asMap().entries.map((entry) {
            int index = entry.key; Map<String, dynamic> timeData = entry.value;
            return [index + 1, timeData['name'], timeData['time'], formatTime(timeData['time'].toDouble())];
          })];
      }
      final csv = const ListToCsvConverter().convert(csvData);
      final bytes = Uint8List.fromList(csv.codeUnits);
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'Tiempos_IE_${modeName}_$timestamp';
      final result = await FileSaver.instance.saveAs(name: fileName, bytes: bytes, ext: 'csv', mimeType: MimeType.csv);
      if (result != null) {
        hasExported = true;
        _showSnackBar('Exportado: $fileName.csv', Icons.check_circle, Colors.tealAccent);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Icons.error_outline, Colors.redAccent);
    }
  }

  String formatTime(double milliseconds) {
    if (milliseconds < 0) return "00:00.00";
    
    if (timeFormat == TimeFormat.seconds) {
      return '${(milliseconds / 1000).toStringAsFixed(2)} s';
    } else if (timeFormat == TimeFormat.minutes) {
      return '${(milliseconds / 60000).toStringAsFixed(3)} min';
    } else {
      final minutes = (milliseconds / 60000).truncate();
      final seconds = (milliseconds / 1000).truncate() % 60;
      final hundredths = (milliseconds / 10).truncate() % 100;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
    }
  }

  void _showSnackBar(String message, IconData icon, Color iconColor) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(children: [Icon(icon, color: iconColor), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _showSnackBarWithUndo(String message, IconData icon, Color iconColor) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(children: [Icon(icon, color: iconColor), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'DESHACER', textColor: Colors.orangeAccent, onPressed: undoLastRecord),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    taskNameController.dispose();
    platform.setMethodCallHandler(null);
    super.dispose();
  }
}