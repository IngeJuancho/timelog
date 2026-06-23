import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'main.dart'; 
import 'storage_service.dart';
import 'export_service.dart';

final timeLogProvider = ChangeNotifierProvider<TimeLogController>((ref) => TimeLogController());

class TimeLogController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ExportService _export = ExportService();
  
  final Stopwatch _stopwatch = Stopwatch();
  
  int _baseTimeMs = 0;
  int? _startTimeEpoch; 
  
  // --- INDEPENDENCIA TOTAL DE MODOS ---
  int? _activeStudyIdRAC;
  int? _activeStudyIdCont;

  OperationTemplate? _activeTemplateRAC;
  int _currentTemplateStepIndexRAC = 0;

  OperationTemplate? _activeTemplateCont;
  int _currentTemplateStepIndexCont = 0;

  // Variables para guardar el "Nombre Maestro" independiente de los pasos
  String _savedTaskNameRAC = '';
  String _savedTaskNameCont = '';

  int? get activeStudyId => currentMode == StopwatchMode.regresoACero ? _activeStudyIdRAC : _activeStudyIdCont;
  set activeStudyId(int? id) {
    if (currentMode == StopwatchMode.regresoACero) _activeStudyIdRAC = id;
    else _activeStudyIdCont = id;
  }

  OperationTemplate? get activeTemplate => currentMode == StopwatchMode.regresoACero ? _activeTemplateRAC : _activeTemplateCont;
  set activeTemplate(OperationTemplate? template) {
    if (currentMode == StopwatchMode.regresoACero) _activeTemplateRAC = template;
    else _activeTemplateCont = template;
  }

  int get currentTemplateStepIndex => currentMode == StopwatchMode.regresoACero ? _currentTemplateStepIndexRAC : _currentTemplateStepIndexCont;
  set currentTemplateStepIndex(int index) {
    if (currentMode == StopwatchMode.regresoACero) _currentTemplateStepIndexRAC = index;
    else _currentTemplateStepIndexCont = index;
  }

  // Getter que devuelve el Nombre Maestro real para usarlo al exportar o guardar
  String get masterStudyName {
    String name = currentMode == StopwatchMode.regresoACero ? _savedTaskNameRAC : _savedTaskNameCont;
    if (name.isNotEmpty) return name;
    if (activeTemplate != null) return activeTemplate!.name;
    if (taskNameController.text.trim().isNotEmpty) return taskNameController.text.trim();
    return '';
  }

  // -------------------------------------

  int animateStartTrigger = 0;
  int animateSecondaryTrigger = 0;
  int animateResetTrigger = 0;
  int animateExportTrigger = 0;
  int showResetDialogTrigger = 0;

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
  int get elapsedMilliseconds => _baseTimeMs + _stopwatch.elapsedMilliseconds;

  TimeLogController() {
    _initNativeButtonListener();
    loadAllData();
  }

  // Helper interno para actualizar el nombre maestro
  void _setMasterName(String name) {
    if (currentMode == StopwatchMode.regresoACero) {
      _savedTaskNameRAC = name;
    } else {
      _savedTaskNameCont = name;
    }
  }

  void loadTemplate(OperationTemplate template) {
    if (template.steps.isEmpty) return;
    resetAll(); 
    activeTemplate = template;
    currentTemplateStepIndex = 0;
    
    _appendTemplatePlaceholders();
    
    // Asignamos el nombre maestro a la plantilla
    _setMasterName(template.name);
    
    // Pero en la interfaz mostramos el primer paso
    taskNameController.text = template.steps[0];
    saveTimerState();
    notifyListeners();
  }

  void _appendTemplatePlaceholders() {
    if (activeTemplate == null) return;
    final currentList = activeRecordedTimes;
    for (int i = 0; i < activeTemplate!.steps.length; i++) {
      currentList.add({
        'name': activeTemplate!.steps[i],
        'time': 0,
        'cumulative_time': 0,
        'type': 'normal',
        'status': 'pending',
        'step_index': i 
      });
    }
  }

  void clearTemplate() {
    activeTemplate = null;
    currentTemplateStepIndex = 0;
    
    activeRecordedTimes.removeWhere((e) => e['status'] == 'pending');
    
    taskNameController.clear();
    _setMasterName('');
    saveTimerState();
    notifyListeners();
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

    _savedTaskNameRAC = prefs.getString('taskNameRAC') ?? prefs.getString('taskName') ?? '';
    _savedTaskNameCont = prefs.getString('taskNameCont') ?? prefs.getString('taskName') ?? '';

    currentMode = StopwatchMode.values[prefs.getInt('currentMode') ?? StopwatchMode.regresoACero.index];
    
    _activeStudyIdRAC = prefs.getInt('activeStudyIdRAC') ?? prefs.getInt('activeStudyId'); 
    _activeStudyIdCont = prefs.getInt('activeStudyIdCont') ?? prefs.getInt('activeStudyId'); 
    
    if (currentMode == StopwatchMode.continuo) {
      final doneItems = recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
      _lastRecordedTimeMs = doneItems.isNotEmpty ? doneItems.last['cumulative_time'] as int : 0;
    } else {
      _lastRecordedTimeMs = 0;
    }

    // RESTAURAR PLANTILLAS
    int templateIdRAC = prefs.getInt('activeTemplateIdRAC') ?? prefs.getInt('activeTemplateId') ?? -1;
    int templateIdCont = prefs.getInt('activeTemplateIdCont') ?? prefs.getInt('activeTemplateId') ?? -1;
    final templates = await _storage.getAllTemplates(); // CORRECCIÓN: Busca en TODAS las carpetas, no solo en la raíz
    
    if (templateIdRAC != -1) {
      _activeTemplateRAC = templates.cast<OperationTemplate?>().firstWhere((t) => t?.id == templateIdRAC, orElse: () => null);
      if (_activeTemplateRAC != null) {
        _currentTemplateStepIndexRAC = recordedTimesRegresoACero.length % _activeTemplateRAC!.steps.length;
        if (currentMode == StopwatchMode.regresoACero) _appendTemplatePlaceholders();
      }
    }

    if (templateIdCont != -1) {
      _activeTemplateCont = templates.cast<OperationTemplate?>().firstWhere((t) => t?.id == templateIdCont, orElse: () => null);
      if (_activeTemplateCont != null) {
        _currentTemplateStepIndexCont = recordedTimesContinuo.length % _activeTemplateCont!.steps.length;
        if (currentMode == StopwatchMode.continuo) _appendTemplatePlaceholders();
      }
    }

    // Restaurar lo que se ve en el TextField
    if (activeTemplate != null) {
      taskNameController.text = activeTemplate!.steps[currentTemplateStepIndex];
    } else {
      taskNameController.text = currentMode == StopwatchMode.regresoACero ? _savedTaskNameRAC : _savedTaskNameCont;
    }

    bool wasRunning = prefs.getBool('isRunning') ?? false;
    int savedStartTime = prefs.getInt('startTimeEpoch') ?? 0;
    
    if (wasRunning && savedStartTime > 0) {
      int missedTime = DateTime.now().millisecondsSinceEpoch - savedStartTime;
      _baseTimeMs = missedTime;
      _stopwatch.start();
      _syncStartTime();
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
    final racDone = recordedTimesRegresoACero.where((e) => e['status'] != 'pending').toList();
    final contDone = recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
    await prefs.setString('times_rac', jsonEncode(racDone));
    await prefs.setString('times_cont', jsonEncode(contDone));
  }

  Future<void> saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRunning', _stopwatch.isRunning);
    await prefs.setInt('baseTimeMs', _baseTimeMs);
    await prefs.setInt('startTimeEpoch', _startTimeEpoch ?? 0);
    await prefs.setInt('currentMode', currentMode.index);
    
    await prefs.setString('taskNameRAC', _savedTaskNameRAC);
    await prefs.setString('taskNameCont', _savedTaskNameCont);
    
    if (_activeStudyIdRAC != null) await prefs.setInt('activeStudyIdRAC', _activeStudyIdRAC!);
    else await prefs.remove('activeStudyIdRAC');

    if (_activeStudyIdCont != null) await prefs.setInt('activeStudyIdCont', _activeStudyIdCont!);
    else await prefs.remove('activeStudyIdCont');
    
    if (_activeTemplateRAC != null) await prefs.setInt('activeTemplateIdRAC', _activeTemplateRAC!.id);
    else await prefs.remove('activeTemplateIdRAC');

    if (_activeTemplateCont != null) await prefs.setInt('activeTemplateIdCont', _activeTemplateCont!.id);
    else await prefs.remove('activeTemplateIdCont');
  }

  Future<void> updateTaskName(String value) async {
    // Si hay plantilla activa, lo que escribe el usuario no debe sobreescribir el Nombre Maestro
    if (activeTemplate != null) return;
    
    _setMasterName(value);
    final prefs = await SharedPreferences.getInstance();
    if (currentMode == StopwatchMode.regresoACero) {
      await prefs.setString('taskNameRAC', value);
    } else {
      await prefs.setString('taskNameCont', value);
    }
  }

  void syncActiveStudyName(String newName) {
    _setMasterName(newName);
    if (activeTemplate == null) {
      taskNameController.text = newName;
    }
    notifyListeners();
  }

  void _syncStartTime() {
    if (_stopwatch.isRunning) {
      _startTimeEpoch = DateTime.now().millisecondsSinceEpoch - _baseTimeMs;
    } else {
      _startTimeEpoch = null;
    }
    saveTimerState();
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
      activeRecordedTimes.removeWhere((e) => e['status'] == 'pending');

      if (activeTemplate == null) {
        _setMasterName(taskNameController.text);
      }

      currentMode = mode;
      
      bool wasRunning = _stopwatch.isRunning;
      _stopwatch.reset(); 
      
      if (currentMode == StopwatchMode.continuo) {
         final doneItems = recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
         _lastRecordedTimeMs = doneItems.isNotEmpty ? doneItems.last['cumulative_time'] as int : 0;
         _baseTimeMs = _lastRecordedTimeMs;
      } else {
         _lastRecordedTimeMs = 0;
         _baseTimeMs = 0;
      }
      
      if (wasRunning) _stopwatch.start();
      _syncStartTime();

      if (activeTemplate != null) {
        int completedItemsCount = activeRecordedTimes.length; 
        currentTemplateStepIndex = completedItemsCount % activeTemplate!.steps.length;
        _appendTemplatePlaceholders();
        
        taskNameController.text = activeTemplate!.steps[currentTemplateStepIndex];
      } else {
        taskNameController.text = currentMode == StopwatchMode.regresoACero ? _savedTaskNameRAC : _savedTaskNameCont;
      }

      calculateStatistics();
      _showSnackBar('Modo: ${mode == StopwatchMode.regresoACero ? "Regreso a Cero" : "Continuo"}', Icons.settings, Colors.tealAccent);
      notifyListeners();
    }
  }

  void toggleElementType(int index) {
    final currentList = activeRecordedTimes;
    if (index >= 0 && index < currentList.length) {
      final currentType = currentList[index]['type'] ?? 'normal';
      currentList[index]['type'] = currentType == 'normal' ? 'outlier' : 'normal';
      
      triggerHaptic();
      saveTimeData();
      calculateStatistics();
      notifyListeners();
    }
  }

  void deleteItem(int index) {
    final currentList = activeRecordedTimes;
    currentList.removeAt(index);
    
    if (activeTemplate != null && index < currentTemplateStepIndex) {
      currentTemplateStepIndex--;
    }

    if (currentMode == StopwatchMode.continuo) {
      final doneItems = currentList.where((e) => e['status'] != 'pending').toList();
      _lastRecordedTimeMs = doneItems.isNotEmpty ? doneItems.last['cumulative_time'] as int : 0;
    }
    
    saveTimeData();
    calculateStatistics();
    notifyListeners();
  }

  void mergeWithPrevious(int index) {
    final currentList = activeRecordedTimes;
    if (index <= 0 || index >= currentList.length) return;

    final prev = currentList[index - 1];
    final curr = currentList[index];

    int mergedTime = (prev['time'] as int) + (curr['time'] as int);
    String mergedName = '${prev['name']} + ${curr['name']}';

    Map<String, dynamic> mergedEntry = {
      'name': mergedName,
      'time': mergedTime,
      'type': 'normal', 
      'status': 'done',
      'step_index': prev['step_index'] // CORRECCIÓN: Ahora se ancla al paso donde inició la acción
    };

    if (currentMode == StopwatchMode.continuo) {
      mergedEntry['cumulative_time'] = curr['cumulative_time'];
    }

    currentList[index - 1] = mergedEntry;
    currentList.removeAt(index);
    
    if (activeTemplate != null && index <= currentTemplateStepIndex) {
      currentTemplateStepIndex--;
    }

    triggerHaptic();
    saveTimeData();
    calculateStatistics();
    notifyListeners();
    
    _showSnackBar('Elementos fusionados correctamente.', Icons.call_merge, Colors.tealAccent);
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
        animateStartTrigger++;
        break;
      case PhysicalButtonAction.lapSnapback:
        if (_stopwatch.isRunning) {
          if (currentMode == StopwatchMode.regresoACero) {
            recordTime(resetStopwatch: true, keepRunning: true);
            animateSecondaryTrigger++;
          } else {
            recordTime(resetStopwatch: false, keepRunning: true);
            animateStartTrigger++;
          }
        }
        break;
      case PhysicalButtonAction.stopAndRecord:
        if (_stopwatch.isRunning) {
          stopTimerLogic();
          recordTime(resetStopwatch: true, keepRunning: false);
          animateStartTrigger++;
        }
        break;
      case PhysicalButtonAction.reset:
        animateResetTrigger++;
        showResetDialogTrigger++; 
        break;
      case PhysicalButtonAction.none:
        break;
    }
    notifyListeners();
  }

  void startTimerLogic() {
    if (!_stopwatch.isRunning) {
      triggerHaptic();
      if (currentMode == StopwatchMode.continuo && _baseTimeMs == 0 && _stopwatch.elapsedMilliseconds == 0) {
        _lastRecordedTimeMs = 0;
      }
      _stopwatch.start();
      _syncStartTime();
      // Ya no llamamos a Timer.periodic. La interfaz gráfica se encargará de consultar el tiempo.
      notifyListeners();
    }
  }

  void stopTimerLogic() {
    if (_stopwatch.isRunning) {
      triggerHaptic();
      _baseTimeMs += _stopwatch.elapsedMilliseconds;
      _stopwatch.reset();
      _stopwatch.stop();
      _syncStartTime();
      notifyListeners();
    }
  }

  void recordTime({required bool resetStopwatch, required bool keepRunning}) {
    final currentTimeMs = elapsedMilliseconds;
    int individualTimeMs = 0;
    final currentList = activeRecordedTimes;

    if (currentTimeMs == 0) return;

    if (currentMode == StopwatchMode.continuo) {
      final doneItems = currentList.where((e) => e['status'] != 'pending').toList();
      int lastTime = doneItems.isNotEmpty ? doneItems.last['cumulative_time'] as int : 0;
      
      if (currentTimeMs <= lastTime && doneItems.isNotEmpty) return;
      individualTimeMs = currentTimeMs - lastTime;
      _lastRecordedTimeMs = currentTimeMs;
    } else {
      individualTimeMs = currentTimeMs;
    }

    if (individualTimeMs >= 0) {
      triggerHaptic();
      
      if (activeTemplate != null && currentTemplateStepIndex < currentList.length) {
        currentList[currentTemplateStepIndex]['time'] = individualTimeMs;
        if (currentMode == StopwatchMode.continuo) {
          currentList[currentTemplateStepIndex]['cumulative_time'] = currentTimeMs;
        }
        currentList[currentTemplateStepIndex]['status'] = 'done';
        
        currentTemplateStepIndex++;
        
        if (currentTemplateStepIndex >= currentList.length) {
          _appendTemplatePlaceholders();
        }
        
        taskNameController.text = currentList[currentTemplateStepIndex]['name'];
      } 
      else {
        Map<String, dynamic> timeEntry = {};
        if (currentMode == StopwatchMode.continuo) {
          timeEntry['cumulative_time'] = currentTimeMs;
        }
        String baseName = taskNameController.text.trim();
        final name = baseName.isNotEmpty ? baseName : 'Ciclo ${currentList.length + 1}';
        
        timeEntry['name'] = name;
        timeEntry['time'] = individualTimeMs;
        timeEntry['type'] = 'normal';
        timeEntry['status'] = 'done';

        currentList.add(timeEntry);
      }

      hasExported = false;
      saveTimeData();
      calculateStatistics();
      _showSnackBarWithUndo('Registrado: ${formatTime(individualTimeMs.toDouble())}', Icons.check_circle, Colors.tealAccent);
    }

    if (resetStopwatch) {
      if (currentMode == StopwatchMode.regresoACero) {
        _stopwatch.reset();
        _baseTimeMs = 0; 
      }
    }
    
    if (keepRunning) {
      if (!_stopwatch.isRunning) _stopwatch.start();
      _syncStartTime();
    } else {
      stopTimerLogic();
    }
    
    notifyListeners();
  }

  void undoLastRecord() {
    final currentList = activeRecordedTimes;
    if (currentList.isEmpty) return;

    if (activeTemplate != null) {
      if (currentTemplateStepIndex > 0) {
        // Deshacer normal dentro de un mismo ciclo
        currentTemplateStepIndex--;
        currentList[currentTemplateStepIndex]['time'] = 0;
        if (currentMode == StopwatchMode.continuo) currentList[currentTemplateStepIndex]['cumulative_time'] = 0;
        currentList[currentTemplateStepIndex]['status'] = 'pending';
        currentList[currentTemplateStepIndex]['type'] = 'normal';
        
        taskNameController.text = currentList[currentTemplateStepIndex]['name'];
      } else if (currentList.length > activeTemplate!.steps.length) {
        // CORRECCIÓN BUG 3: El usuario quiere retroceder al ciclo anterior estando en el Paso 0
        int stepCount = activeTemplate!.steps.length;
        // 1. Eliminamos todos los espacios vacíos generados para este ciclo
        currentList.removeRange(currentList.length - stepCount, currentList.length);
        // 2. Colocamos el índice en el último paso del ciclo anterior
        currentTemplateStepIndex = stepCount - 1;
        // 3. Devolvemos su estado a pendiente
        currentList.last['time'] = 0;
        if (currentMode == StopwatchMode.continuo) currentList.last['cumulative_time'] = 0;
        currentList.last['status'] = 'pending';
        currentList.last['type'] = 'normal';
        
        taskNameController.text = currentList.last['name'];
      } else {
         // Si quiere deshacer estando en el mero principio absoluto, solo limpiamos el primero
         currentList[0]['time'] = 0;
         if (currentMode == StopwatchMode.continuo) currentList[0]['cumulative_time'] = 0;
         currentList[0]['status'] = 'pending';
         currentList[0]['type'] = 'normal';
         taskNameController.text = currentList[0]['name'];
      }
    } else {
      currentList.removeLast();
    }
    
    if (currentMode == StopwatchMode.continuo) {
      final doneItems = currentList.where((e) => e['status'] != 'pending').toList();
      _lastRecordedTimeMs = doneItems.isNotEmpty ? doneItems.last['cumulative_time'] as int : 0;
    }
    
    saveTimeData();
    calculateStatistics();
    notifyListeners();
    
    scaffoldMessengerKey.currentState?.clearSnackBars();
    _showSnackBar('Último registro deshecho.', Icons.undo, Colors.orangeAccent);
  }

  void calculateStatistics() {
    final currentList = activeRecordedTimes;
    if (currentList.isEmpty) { averageTime = minTime = maxTime = stdDev = 0.0; return; }
    
    final validTimes = currentList
        .where((e) => (e['type'] ?? 'normal') != 'outlier' && (e['time'] as int) > 0 && e['status'] != 'pending')
        .map((e) => e['time'] as int)
        .toList();
        
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
    _baseTimeMs = 0; 
    activeStudyId = null; 
    _syncStartTime();
    activeRecordedTimes.clear();
    
    if (activeTemplate != null && activeTemplate!.steps.isNotEmpty) {
      currentTemplateStepIndex = 0;
      _appendTemplatePlaceholders();
      taskNameController.text = activeTemplate!.steps[0];
    } else {
      taskNameController.text = ''; 
      _setMasterName('');
    }

    saveTimeData();
    calculateStatistics();
    _lastRecordedTimeMs = 0;
    hasExported = true;
    notifyListeners();
  }

  Future<void> exportData() async {
    final dataToExport = activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToExport.isEmpty) {
      _showSnackBar('No hay datos para exportar.', Icons.warning_amber_rounded, Colors.orange);
      return;
    }
    try {
      final fileName = await _export.exportDataToCsv(
        data: dataToExport,
        mode: currentMode,
        timeFormatter: (val) => formatTime(val, forExport: true),
        activeTemplate: activeTemplate,
        studyName: masterStudyName.isNotEmpty ? masterStudyName : 'Estudio_General',
      );
      
      if (fileName != null) {
        hasExported = true;
        _showSnackBar('Exportado: $fileName', Icons.check_circle, Colors.tealAccent);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Icons.error_outline, Colors.redAccent);
    }
  }

  Future<void> importCsv() async {
    try {
      final result = await _export.importDataFromCsv();
      if (result != null) {
        final StopwatchMode importedMode = result['mode'];
        final List<Map<String, dynamic>> importedTimes = result['times'];

        setMode(importedMode); 
        clearTemplate(); 
        resetAll();
        
        if (importedMode == StopwatchMode.regresoACero) {
          recordedTimesRegresoACero = importedTimes;
        } else {
          recordedTimesContinuo = importedTimes;
          if (recordedTimesContinuo.isNotEmpty) {
            _lastRecordedTimeMs = recordedTimesContinuo.last['cumulative_time'] as int;
            _baseTimeMs = _lastRecordedTimeMs;
          }
        }
        
        hasExported = true; 
        saveTimeData();
        calculateStatistics();
        _syncStartTime(); 
        notifyListeners();
        
        _showSnackBar('Estudio importado correctamente.', Icons.file_download_done, Colors.tealAccent);
      }
    } catch (e) {
      _showSnackBar(e.toString(), Icons.error_outline, Colors.redAccent);
    }
  }

  Future<void> saveCurrentStudyToHistory(String studyName) async {
    final dataToSave = activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToSave.isEmpty) return;
    
    activeStudyId = await _storage.saveStudyToHistory(
      name: studyName,
      mode: currentMode,
      times: dataToSave,
      template: activeTemplate, 
    );
    _setMasterName(studyName);
    
    if (activeTemplate == null) {
      taskNameController.text = studyName;
    }

    saveTimerState(); 
    notifyListeners();

    _showSnackBar('Estudio "$studyName" guardado con éxito.', Icons.save, Colors.tealAccent);
  }

  Future<void> updateCurrentStudy() async {
    final dataToSave = activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToSave.isEmpty || activeStudyId == null) return;
    
    await _storage.updateExistingStudy(
      id: activeStudyId!,
      mode: currentMode,
      times: dataToSave,
      template: activeTemplate, 
    );
    
    saveTimerState();
    notifyListeners();

    _showSnackBar('Estudio actualizado correctamente.', Icons.update, Colors.tealAccent);
  }

  void loadStudyFromHistory(StudyModel study) {
    setMode(study.mode); 
    clearTemplate(); 
    resetAll();
    
    activeStudyId = study.id; 
    _setMasterName(study.name);
    
    final convertedTimes = study.times.map((t) => {
      'name': t.name,
      'time': t.time,
      'type': t.type,
      'cumulative_time': t.cumulativeTime,
      'status': 'done',
      'step_index': t.stepIndex 
    }).toList();

    if (study.mode == StopwatchMode.regresoACero) {
      recordedTimesRegresoACero = convertedTimes;
    } else {
      recordedTimesContinuo = convertedTimes;
      if (recordedTimesContinuo.isNotEmpty) {
        _lastRecordedTimeMs = recordedTimesContinuo.last['cumulative_time'] as int;
        _baseTimeMs = _lastRecordedTimeMs;
      }
    }
    
    if (study.isTemplate && study.templateSteps.isNotEmpty) {
      activeTemplate = OperationTemplate()
        ..id = -1 
        ..name = study.name
        ..steps = study.templateSteps;
      
      currentTemplateStepIndex = convertedTimes.length % activeTemplate!.steps.length;
      _appendTemplatePlaceholders();
      taskNameController.text = activeTemplate!.steps[currentTemplateStepIndex];
    } else {
      taskNameController.text = study.name;
    }
    
    saveTimeData();
    saveTimerState();
    calculateStatistics();
    notifyListeners();
    _showSnackBar('Estudio cargado: ${study.name}', Icons.folder_open, Colors.blueAccent);
  }

  void clearActiveStudyId() {
    activeStudyId = null;
    saveTimerState();
    notifyListeners();
  }

  String formatTime(double milliseconds, {bool forExport = false}) {
    if (milliseconds < 0) return "00:00.00";
    
    if (timeFormat == TimeFormat.seconds) {
      String val = (milliseconds / 1000).toStringAsFixed(2);
      return forExport ? val : '$val s';
    } else if (timeFormat == TimeFormat.minutes) {
      String val = (milliseconds / 60000).toStringAsFixed(3);
      return forExport ? val : '$val min';
    } else {
      final minutes = (milliseconds / 60000).truncate();
      final seconds = (milliseconds / 1000).truncate() % 60;
      final hundredths = (milliseconds / 10).truncate() % 100;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';
    }
  }

  void _showSnackBar(String message, IconData icon, Color iconColor) {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    double bottomMargin = 16.0;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final screenHeight = view.physicalSize.height / view.devicePixelRatio;
      bottomMargin = screenHeight - 140; 
      if (bottomMargin < 16.0) bottomMargin = 16.0;
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(children: [Icon(icon, color: iconColor), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: bottomMargin, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(milliseconds: 2000), 
        dismissDirection: DismissDirection.up, 
      ),
    );
  }

  void _showSnackBarWithUndo(String message, IconData icon, Color iconColor) {
    scaffoldMessengerKey.currentState?.clearSnackBars(); 
    double bottomMargin = 16.0;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final screenHeight = view.physicalSize.height / view.devicePixelRatio;
      bottomMargin = screenHeight - 140; 
      if (bottomMargin < 16.0) bottomMargin = 16.0;
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(children: [Icon(icon, color: iconColor), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))]),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: bottomMargin, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'DESHACER', textColor: Colors.orangeAccent, onPressed: undoLastRecord),
      ),
    );
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null);
    super.dispose();
  }
}