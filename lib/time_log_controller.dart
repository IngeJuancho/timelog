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
import 'time_log_state.dart';

final timeLogProvider = NotifierProvider<TimeLogNotifier, TimeLogState>(TimeLogNotifier.new);

class TimeLogNotifier extends Notifier<TimeLogState> {
  final StorageService _storage = StorageService();
  final ExportService _export = ExportService();
  
  final Stopwatch _stopwatch = Stopwatch();
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController ratingController = TextEditingController(text: "100");

  static const platform = MethodChannel('com.timelog/volume_buttons');

  int get elapsedMilliseconds => state.baseTimeMs + _stopwatch.elapsedMilliseconds;
  bool get isRunning => _stopwatch.isRunning;

  @override
  TimeLogState build() {
    _initNativeButtonListener();
    loadAllData();
    ref.onDispose(() {
      platform.setMethodCallHandler(null);
      taskNameController.dispose();
    });
    return const TimeLogState();
  }

  void _setMasterName(String name) {
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(savedTaskNameRAC: name);
    } else {
      state = state.copyWith(savedTaskNameCont: name);
    }
  }

  void _recalculateLastRecordedTime() {
    if (state.currentMode != StopwatchMode.continuo) {
      state = state.copyWith(lastRecordedTimeMs: 0);
      return;
    }
    
    final doneItems = state.recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
    if (doneItems.isEmpty) {
      state = state.copyWith(lastRecordedTimeMs: 0);
      return;
    }
    
    if (state.activeTemplate != null && doneItems.length % state.activeTemplate!.steps.length == 0) {
      state = state.copyWith(lastRecordedTimeMs: 0);
    } else {
      state = state.copyWith(lastRecordedTimeMs: doneItems.last['cumulative_time'] as int);
    }
  }

  void loadTemplate(OperationTemplate template) {
    if (template.steps.isEmpty) return;
    resetAll(); 
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(activeTemplateRAC: () => template, currentTemplateStepIndexRAC: 0);
    } else {
      state = state.copyWith(activeTemplateCont: () => template, currentTemplateStepIndexCont: 0);
    }
    
    _appendTemplatePlaceholders();
    _setMasterName(template.name);
    taskNameController.text = template.steps[0];
    
    saveTimerState();
  }

  void _appendTemplatePlaceholders() {
    if (state.activeTemplate == null) return;
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    
    for (int i = 0; i < state.activeTemplate!.steps.length; i++) {
      currentList.add({
        'name': state.activeTemplate!.steps[i],
        'time': 0,
        'cumulative_time': 0,
        'type': 'normal',
        'status': 'pending',
        'step_index': i 
      });
    }
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }
  }

  void _restorePlaceholdersForList(List<Map<String, dynamic>> list, OperationTemplate template) {
    int remainder = list.length % template.steps.length;
    if (remainder != 0) {
      for (int i = remainder; i < template.steps.length; i++) {
        list.add({
          'name': template.steps[i],
          'time': 0,
          'cumulative_time': 0,
          'type': 'normal',
          'status': 'pending',
          'step_index': i 
        });
      }
    } else {
      for (int i = 0; i < template.steps.length; i++) {
        list.add({
          'name': template.steps[i],
          'time': 0,
          'cumulative_time': 0,
          'type': 'normal',
          'status': 'pending',
          'step_index': i 
        });
      }
    }
  }

  void clearTemplate() {
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(activeTemplateRAC: () => null, currentTemplateStepIndexRAC: 0);
    } else {
      state = state.copyWith(activeTemplateCont: () => null, currentTemplateStepIndexCont: 0);
    }
    
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    currentList.removeWhere((e) => e['status'] == 'pending');
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }
    
    _recalculateLastRecordedTime(); 

    taskNameController.clear();
    _setMasterName('');
    saveTimerState();
  }

  Future<void> loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    bool usePhysicalButtons = prefs.getBool('usePhysicalButtons') ?? false;
    bool useHapticFeedback = prefs.getBool('useHapticFeedback') ?? false;
    bool recordOnPause = prefs.getBool('recordOnPause') ?? false;
    
    int hapticIndex = prefs.getInt('hapticLevel') ?? HapticLevel.medium.index;
    HapticLevel hapticLevel = HapticLevel.values[hapticIndex];

    int formatIndex = prefs.getInt('timeFormat') ?? TimeFormat.standard.index;
    TimeFormat timeFormat = TimeFormat.values[formatIndex];

    PhysicalButtonAction volUpActionRAC = PhysicalButtonAction.values[prefs.getInt('volUpActionRAC') ?? PhysicalButtonAction.lapSnapback.index];
    PhysicalButtonAction volDownActionRAC = PhysicalButtonAction.values[prefs.getInt('volDownActionRAC') ?? PhysicalButtonAction.stopAndRecord.index];
    PhysicalButtonAction volUpActionCont = PhysicalButtonAction.values[prefs.getInt('volUpActionCont') ?? PhysicalButtonAction.lapSnapback.index];
    PhysicalButtonAction volDownActionCont = PhysicalButtonAction.values[prefs.getInt('volDownActionCont') ?? PhysicalButtonAction.stopAndRecord.index];

    List<Map<String, dynamic>> racTimes = [];
    String? racJson = prefs.getString('times_rac');
    if (racJson != null) racTimes = List<Map<String, dynamic>>.from(jsonDecode(racJson));

    List<Map<String, dynamic>> contTimes = [];
    String? contJson = prefs.getString('times_cont');
    if (contJson != null) contTimes = List<Map<String, dynamic>>.from(jsonDecode(contJson));

    String savedTaskNameRAC = prefs.getString('taskNameRAC') ?? prefs.getString('taskName') ?? '';
    String savedTaskNameCont = prefs.getString('taskNameCont') ?? prefs.getString('taskName') ?? '';
    
    Map<int, int> loadMap(String key) {
      String? jsonStr = prefs.getString(key);
      if (jsonStr == null) return {};
      try {
        Map<String, dynamic> rawMap = jsonDecode(jsonStr);
        return rawMap.map((k, v) => MapEntry(int.parse(k), v as int));
      } catch (e) {
        return {};
      }
    }
    Map<int, int> cycleRatingsRAC = loadMap('cycleRatingsRAC');
    Map<int, int> cycleRatingsCont = loadMap('cycleRatingsCont');

    StopwatchMode currentMode = StopwatchMode.values[prefs.getInt('currentMode') ?? StopwatchMode.regresoACero.index];
    
    int? activeStudyIdRAC = prefs.getInt('activeStudyIdRAC') ?? prefs.getInt('activeStudyId'); 
    int? activeStudyIdCont = prefs.getInt('activeStudyIdCont') ?? prefs.getInt('activeStudyId'); 

    int templateIdRAC = prefs.getInt('activeTemplateIdRAC') ?? prefs.getInt('activeTemplateId') ?? -1;
    int templateIdCont = prefs.getInt('activeTemplateIdCont') ?? prefs.getInt('activeTemplateId') ?? -1;
    final templates = await _storage.getAllTemplates(); 
    
    OperationTemplate? activeTemplateRAC;
    if (templateIdRAC != -1) {
      activeTemplateRAC = templates.cast<OperationTemplate?>().firstWhere((t) => t?.id == templateIdRAC, orElse: () => null);
    } else {
      String? vNameRAC = prefs.getString('virtualTemplateNameRAC');
      List<String>? vStepsRAC = prefs.getStringList('virtualTemplateStepsRAC');
      if (vNameRAC != null && vStepsRAC != null) {
        activeTemplateRAC = OperationTemplate()..id = -1..name = vNameRAC..steps = vStepsRAC;
      }
    }

    int currentTemplateStepIndexRAC = 0;
    if (activeTemplateRAC != null) {
      currentTemplateStepIndexRAC = racTimes.length; 
      if (currentMode == StopwatchMode.regresoACero) _restorePlaceholdersForList(racTimes, activeTemplateRAC);
    }

    OperationTemplate? activeTemplateCont;
    if (templateIdCont != -1) {
      activeTemplateCont = templates.cast<OperationTemplate?>().firstWhere((t) => t?.id == templateIdCont, orElse: () => null);
    } else {
      String? vNameCont = prefs.getString('virtualTemplateNameCont');
      List<String>? vStepsCont = prefs.getStringList('virtualTemplateStepsCont');
      if (vNameCont != null && vStepsCont != null) {
        activeTemplateCont = OperationTemplate()..id = -1..name = vNameCont..steps = vStepsCont;
      }
    }

    int currentTemplateStepIndexCont = 0;
    if (activeTemplateCont != null) {
      currentTemplateStepIndexCont = contTimes.length; 
      if (currentMode == StopwatchMode.continuo) _restorePlaceholdersForList(contTimes, activeTemplateCont);
    }

    state = state.copyWith(
      usePhysicalButtons: usePhysicalButtons,
      useHapticFeedback: useHapticFeedback,
      recordOnPause: recordOnPause,
      hapticLevel: hapticLevel,
      timeFormat: timeFormat,
      volUpActionRAC: volUpActionRAC,
      volDownActionRAC: volDownActionRAC,
      volUpActionCont: volUpActionCont,
      volDownActionCont: volDownActionCont,
      recordedTimesRegresoACero: racTimes,
      recordedTimesContinuo: contTimes,
      savedTaskNameRAC: savedTaskNameRAC,
      savedTaskNameCont: savedTaskNameCont,
      currentMode: currentMode,
      activeStudyIdRAC: () => activeStudyIdRAC,
      activeStudyIdCont: () => activeStudyIdCont,
      activeTemplateRAC: () => activeTemplateRAC,
      currentTemplateStepIndexRAC: currentTemplateStepIndexRAC,
      activeTemplateCont: () => activeTemplateCont,
      currentTemplateStepIndexCont: currentTemplateStepIndexCont,
      cycleRatingsRAC: cycleRatingsRAC,
      cycleRatingsCont: cycleRatingsCont,
    );

    _recalculateLastRecordedTime();

    if (state.activeTemplate != null) {
      taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
    } else {
      taskNameController.text = currentMode == StopwatchMode.regresoACero ? state.savedTaskNameRAC : state.savedTaskNameCont;
    }

    bool wasRunning = prefs.getBool('isRunning') ?? false;
    int savedStartTime = prefs.getInt('startTimeEpoch') ?? 0;
    int baseTimeMs = prefs.getInt('baseTimeMs') ?? (currentMode == StopwatchMode.continuo ? state.lastRecordedTimeMs : 0);
    
    state = state.copyWith(baseTimeMs: baseTimeMs);

    if (wasRunning && savedStartTime > 0) {
      int missedTime = DateTime.now().millisecondsSinceEpoch - savedStartTime;
      state = state.copyWith(baseTimeMs: missedTime);
      _stopwatch.start();
      _syncStartTime();
    }

    calculateStatistics();
  }

  Future<void> saveSettings(TimeLogState newState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useHapticFeedback', newState.useHapticFeedback);
    await prefs.setInt('timeFormat', newState.timeFormat.index);
    await prefs.setInt('hapticLevel', newState.hapticLevel.index);
    await prefs.setBool('usePhysicalButtons', newState.usePhysicalButtons);
    await prefs.setBool('recordOnPause', newState.recordOnPause);
    await prefs.setInt('volUpActionRAC', newState.volUpActionRAC.index);
    await prefs.setInt('volDownActionRAC', newState.volDownActionRAC.index);
    await prefs.setInt('volUpActionCont', newState.volUpActionCont.index);
    await prefs.setInt('volDownActionCont', newState.volDownActionCont.index);
  }

  void updateSetting({
    TimeFormat? timeFormat,
    bool? useHapticFeedback,
    HapticLevel? hapticLevel,
    bool? usePhysicalButtons,
    bool? recordOnPause,
    PhysicalButtonAction? volUpActionRAC,
    PhysicalButtonAction? volDownActionRAC,
    PhysicalButtonAction? volUpActionCont,
    PhysicalButtonAction? volDownActionCont,
  }) {
    final newState = state.copyWith(
      timeFormat: timeFormat,
      useHapticFeedback: useHapticFeedback,
      hapticLevel: hapticLevel,
      usePhysicalButtons: usePhysicalButtons,
      recordOnPause: recordOnPause,
      volUpActionRAC: volUpActionRAC,
      volDownActionRAC: volDownActionRAC,
      volUpActionCont: volUpActionCont,
      volDownActionCont: volDownActionCont,
    );
    state = newState;
    saveSettings(newState);
  }

  Future<void> saveTimeData() async {
    final prefs = await SharedPreferences.getInstance();
    final racDone = state.recordedTimesRegresoACero.where((e) => e['status'] != 'pending').toList();
    final contDone = state.recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
    await prefs.setString('times_rac', jsonEncode(racDone));
    await prefs.setString('times_cont', jsonEncode(contDone));
  }

  Future<void> saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRunning', _stopwatch.isRunning);
    await prefs.setInt('baseTimeMs', state.baseTimeMs);
    await prefs.setInt('startTimeEpoch', state.startTimeEpoch ?? 0);
    await prefs.setInt('currentMode', state.currentMode.index);
    
    await prefs.setString('taskNameRAC', state.savedTaskNameRAC);
    await prefs.setString('taskNameCont', state.savedTaskNameCont);
    
    await prefs.setString('cycleRatingsRAC', jsonEncode(state.cycleRatingsRAC.map((k, v) => MapEntry(k.toString(), v))));
    await prefs.setString('cycleRatingsCont', jsonEncode(state.cycleRatingsCont.map((k, v) => MapEntry(k.toString(), v))));
    
    if (state.activeStudyIdRAC != null) {
      await prefs.setInt('activeStudyIdRAC', state.activeStudyIdRAC!);
    } else {
      await prefs.remove('activeStudyIdRAC');
    }

    if (state.activeStudyIdCont != null) {
      await prefs.setInt('activeStudyIdCont', state.activeStudyIdCont!);
    } else {
      await prefs.remove('activeStudyIdCont');
    }
    
    if (state.activeTemplateRAC != null) {
      await prefs.setInt('activeTemplateIdRAC', state.activeTemplateRAC!.id);
      if (state.activeTemplateRAC!.id == -1) {
        await prefs.setString('virtualTemplateNameRAC', state.activeTemplateRAC!.name);
        await prefs.setStringList('virtualTemplateStepsRAC', state.activeTemplateRAC!.steps);
      } else {
        await prefs.remove('virtualTemplateNameRAC');
        await prefs.remove('virtualTemplateStepsRAC');
      }
    } else {
      await prefs.remove('activeTemplateIdRAC');
      await prefs.remove('virtualTemplateNameRAC');
      await prefs.remove('virtualTemplateStepsRAC');
    }

    if (state.activeTemplateCont != null) {
      await prefs.setInt('activeTemplateIdCont', state.activeTemplateCont!.id);
      if (state.activeTemplateCont!.id == -1) {
        await prefs.setString('virtualTemplateNameCont', state.activeTemplateCont!.name);
        await prefs.setStringList('virtualTemplateStepsCont', state.activeTemplateCont!.steps);
      } else {
        await prefs.remove('virtualTemplateNameCont');
        await prefs.remove('virtualTemplateStepsCont');
      }
    } else {
      await prefs.remove('activeTemplateIdCont');
      await prefs.remove('virtualTemplateNameCont');
      await prefs.remove('virtualTemplateStepsCont');
    }
  }

  Future<void> updateTaskName(String value) async {
    if (state.activeTemplate != null) return;
    
    _setMasterName(value);
    final prefs = await SharedPreferences.getInstance();
    if (state.currentMode == StopwatchMode.regresoACero) {
      await prefs.setString('taskNameRAC', value);
    } else {
      await prefs.setString('taskNameCont', value);
    }
  }

  void updateGlobalRating(String value) {
    int parsed = int.tryParse(value) ?? 100;
    if (parsed < 1) parsed = 1;
    state = state.copyWith(globalRating: parsed, hasExported: false);
  }

  void applyRatingToCurrentCycle() {
    int parsed = int.tryParse(ratingController.text) ?? 100;
    if (parsed < 1) parsed = 1;
    
    int stepCount = state.activeTemplate?.steps.length ?? 1;
    if (stepCount == 0) stepCount = 1;
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      int currentCycle = state.currentTemplateStepIndexRAC ~/ stepCount;
      Map<int, int> newRatings = Map.from(state.cycleRatingsRAC);
      newRatings[currentCycle] = parsed;
      state = state.copyWith(cycleRatingsRAC: newRatings, hasExported: false);
    } else {
      int currentCycle = state.currentTemplateStepIndexCont ~/ stepCount;
      Map<int, int> newRatings = Map.from(state.cycleRatingsCont);
      newRatings[currentCycle] = parsed;
      state = state.copyWith(cycleRatingsCont: newRatings, hasExported: false);
    }
    saveTimerState();
    _showSnackBarWithUndo('Calificación de $parsed% aplicada al ciclo ${state.activeTemplate != null ? (state.currentMode == StopwatchMode.regresoACero ? (state.currentTemplateStepIndexRAC ~/ stepCount) + 1 : (state.currentTemplateStepIndexCont ~/ stepCount) + 1) : "actual"}', Icons.check_circle, Colors.tealAccent);
  }

  void syncActiveStudyName(String newName) {
    _setMasterName(newName);
    if (state.activeTemplate == null) {
      taskNameController.text = newName;
    }
  }

  void _syncStartTime() {
    int? newEpoch;
    if (_stopwatch.isRunning) {
      newEpoch = DateTime.now().millisecondsSinceEpoch - state.baseTimeMs;
    }
    state = state.copyWith(startTimeEpoch: () => newEpoch, isRunning: _stopwatch.isRunning);
    saveTimerState();
  }

  void _initNativeButtonListener() {
    platform.setMethodCallHandler((call) async {
      if (!state.usePhysicalButtons) return;
      if (call.method == 'volumeUp') {
        _handleNativeButtonPress(isVolumeUp: true);
      } else if (call.method == 'volumeDown') {
        _handleNativeButtonPress(isVolumeUp: false);
      }
    });
  }

  void triggerHaptic() {
    if (state.useHapticFeedback) {
      switch (state.hapticLevel) {
        case HapticLevel.light: HapticFeedback.lightImpact(); break;
        case HapticLevel.medium: HapticFeedback.mediumImpact(); break;
        case HapticLevel.heavy: HapticFeedback.heavyImpact(); break;
      }
    }
  }

  void setMode(StopwatchMode mode) {
    if (state.currentMode != mode) {
      final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
      currentList.removeWhere((e) => e['status'] == 'pending');

      if (state.activeTemplate == null) {
        _setMasterName(taskNameController.text);
      }
      
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(recordedTimesRegresoACero: currentList);
      } else {
        state = state.copyWith(recordedTimesContinuo: currentList);
      }

      state = state.copyWith(currentMode: mode);
      
      bool wasRunning = _stopwatch.isRunning;
      _stopwatch.reset(); 
      
      _recalculateLastRecordedTime();
      state = state.copyWith(baseTimeMs: state.currentMode == StopwatchMode.continuo ? state.lastRecordedTimeMs : 0);
      
      if (wasRunning) _stopwatch.start();
      _syncStartTime();

      if (state.activeTemplate != null) {
        if (state.currentMode == StopwatchMode.regresoACero) {
          state = state.copyWith(currentTemplateStepIndexRAC: state.recordedTimesRegresoACero.length);
        } else {
          state = state.copyWith(currentTemplateStepIndexCont: state.recordedTimesContinuo.length);
        }
        _restorePlaceholdersForList(
            state.currentMode == StopwatchMode.regresoACero ? state.recordedTimesRegresoACero : state.recordedTimesContinuo, 
            state.activeTemplate!);
        
        taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
      } else {
        taskNameController.text = state.currentMode == StopwatchMode.regresoACero ? state.savedTaskNameRAC : state.savedTaskNameCont;
      }

      calculateStatistics();
      _showSnackBar('Modo: ${mode == StopwatchMode.regresoACero ? "Por Ciclo" : "Por Elemento"}', Icons.settings, Colors.tealAccent);
    }
  }

  void toggleElementType(int index) {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    if (index >= 0 && index < currentList.length) {
      final item = Map<String, dynamic>.from(currentList[index]);
      final currentType = item['type'] ?? 'normal';
      item['type'] = currentType == 'normal' ? 'outlier' : 'normal';
      currentList[index] = item;
      
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(recordedTimesRegresoACero: currentList);
      } else {
        state = state.copyWith(recordedTimesContinuo: currentList);
      }
      
      triggerHaptic();
      saveTimeData();
      calculateStatistics();
    }
  }

  void deleteItem(int index) {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    currentList.removeAt(index);
    
    if (state.activeTemplate != null && index < state.currentTemplateStepIndex) {
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(currentTemplateStepIndexRAC: state.currentTemplateStepIndexRAC - 1);
      } else {
        state = state.copyWith(currentTemplateStepIndexCont: state.currentTemplateStepIndexCont - 1);
      }
    }
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }

    _recalculateLastRecordedTime();
    
    saveTimeData();
    calculateStatistics();
  }

  void mergeWithPrevious(int index) {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
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
      'step_index': prev['step_index'] 
    };

    if (state.currentMode == StopwatchMode.continuo) {
      mergedEntry['cumulative_time'] = curr['cumulative_time'];
    }

    currentList[index - 1] = mergedEntry;
    currentList.removeAt(index);
    
    if (state.activeTemplate != null && index <= state.currentTemplateStepIndex) {
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(currentTemplateStepIndexRAC: state.currentTemplateStepIndexRAC - 1);
      } else {
        state = state.copyWith(currentTemplateStepIndexCont: state.currentTemplateStepIndexCont - 1);
      }
    }
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }

    _recalculateLastRecordedTime();

    triggerHaptic();
    saveTimeData();
    calculateStatistics();
    
    _showSnackBar('Elementos fusionados correctamente.', Icons.call_merge, Colors.tealAccent);
  }

  void _handleNativeButtonPress({required bool isVolumeUp}) {
    PhysicalButtonAction action = state.currentMode == StopwatchMode.regresoACero 
        ? (isVolumeUp ? state.volUpActionRAC : state.volDownActionRAC)
        : (isVolumeUp ? state.volUpActionCont : state.volDownActionCont);
    if (action != PhysicalButtonAction.none) {
      executePhysicalAction(action);
    }
  }

  void executePhysicalAction(PhysicalButtonAction action) {
    switch (action) {
      case PhysicalButtonAction.startStop:
        if (_stopwatch.isRunning) {
          stopTimerLogic();
          if (state.recordOnPause) {
            recordTime(resetStopwatch: state.currentMode == StopwatchMode.regresoACero, keepRunning: false);
          }
        } else {
          startTimerLogic();
        }
        state = state.copyWith(animateStartTrigger: state.animateStartTrigger + 1);
        break;
      case PhysicalButtonAction.lapSnapback:
        if (_stopwatch.isRunning) {
          if (state.currentMode == StopwatchMode.regresoACero) {
            recordTime(resetStopwatch: true, keepRunning: true);
            state = state.copyWith(animateSecondaryTrigger: state.animateSecondaryTrigger + 1);
          } else {
            recordTime(resetStopwatch: false, keepRunning: true);
            state = state.copyWith(animateStartTrigger: state.animateStartTrigger + 1);
          }
        }
        break;
      case PhysicalButtonAction.stopAndRecord:
        if (_stopwatch.isRunning) {
          stopTimerLogic();
          recordTime(resetStopwatch: true, keepRunning: false);
          state = state.copyWith(animateStartTrigger: state.animateStartTrigger + 1);
        }
        break;
      case PhysicalButtonAction.reset:
        state = state.copyWith(
          animateResetTrigger: state.animateResetTrigger + 1,
          showResetDialogTrigger: state.showResetDialogTrigger + 1
        );
        break;
      case PhysicalButtonAction.none:
        break;
    }
  }

  void startTimerLogic() {
    if (!_stopwatch.isRunning) {
      triggerHaptic();
      if (state.currentMode == StopwatchMode.continuo && state.baseTimeMs == 0 && _stopwatch.elapsedMilliseconds == 0) {
        state = state.copyWith(lastRecordedTimeMs: 0);
      }
      _stopwatch.start();
      _syncStartTime();
    }
  }

  void stopTimerLogic() {
    if (_stopwatch.isRunning) {
      triggerHaptic();
      state = state.copyWith(baseTimeMs: state.baseTimeMs + _stopwatch.elapsedMilliseconds);
      _stopwatch.reset();
      _stopwatch.stop();
      _syncStartTime();
    }
  }

  void recordTime({required bool resetStopwatch, required bool keepRunning}) {
    final currentTimeMs = elapsedMilliseconds;
    int individualTimeMs = 0;
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);

    if (currentTimeMs == 0) return;

    if (state.currentMode == StopwatchMode.continuo) {
      int lastTime = state.lastRecordedTimeMs;
      if (currentTimeMs <= lastTime && lastTime > 0) return;
      individualTimeMs = currentTimeMs - lastTime;
    } else {
      individualTimeMs = currentTimeMs;
    }

    if (individualTimeMs >= 0) {
      triggerHaptic();
      bool cycleJustFinished = false;
      
      if (state.activeTemplate != null && state.currentTemplateStepIndex < currentList.length) {
        final item = Map<String, dynamic>.from(currentList[state.currentTemplateStepIndex]);
        item['time'] = individualTimeMs;
        if (state.currentMode == StopwatchMode.continuo) {
          item['cumulative_time'] = currentTimeMs;
        }
        item['status'] = 'done';
        currentList[state.currentTemplateStepIndex] = item;
        
        int nextIndex = state.currentTemplateStepIndex + 1;
        if (state.currentMode == StopwatchMode.regresoACero) {
          state = state.copyWith(currentTemplateStepIndexRAC: nextIndex);
        } else {
          state = state.copyWith(currentTemplateStepIndexCont: nextIndex);
        }
        
        if (nextIndex % state.activeTemplate!.steps.length == 0) {
          cycleJustFinished = true;
        }

        if (state.currentMode == StopwatchMode.regresoACero) {
          state = state.copyWith(recordedTimesRegresoACero: currentList);
        } else {
          state = state.copyWith(recordedTimesContinuo: currentList);
        }

        if (nextIndex >= currentList.length) {
          _appendTemplatePlaceholders();
        }
        
        taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
      } 
      else {
        Map<String, dynamic> timeEntry = {};
        if (state.currentMode == StopwatchMode.continuo) {
          timeEntry['cumulative_time'] = currentTimeMs;
        }
        String baseName = taskNameController.text.trim();
        final name = baseName.isNotEmpty ? baseName : 'Ciclo ${currentList.length + 1}';
        
        timeEntry['name'] = name;
        timeEntry['time'] = individualTimeMs;
        timeEntry['type'] = 'normal';
        timeEntry['status'] = 'done';

        currentList.add(timeEntry);
        
        if (state.currentMode == StopwatchMode.regresoACero) {
          state = state.copyWith(recordedTimesRegresoACero: currentList);
        } else {
          state = state.copyWith(recordedTimesContinuo: currentList);
        }
      }

      state = state.copyWith(hasExported: false);
      saveTimeData();
      calculateStatistics();
      _showSnackBarWithUndo('Registrado: ${formatTime(individualTimeMs.toDouble())}', Icons.check_circle, Colors.tealAccent);
      
      if (state.currentMode == StopwatchMode.continuo) {
        state = state.copyWith(lastRecordedTimeMs: currentTimeMs);
      }

      bool shouldReset = resetStopwatch;
      if (state.currentMode == StopwatchMode.continuo && cycleJustFinished) {
        shouldReset = true;
      }

      if (shouldReset) {
        _stopwatch.reset();
        state = state.copyWith(baseTimeMs: 0);
        if (state.currentMode == StopwatchMode.continuo) {
           state = state.copyWith(lastRecordedTimeMs: 0);
        }
      }
      
      if (keepRunning) {
        if (!_stopwatch.isRunning) _stopwatch.start();
        _syncStartTime();
      } else {
        stopTimerLogic();
      }
    }
  }

  void undoLastRecord() {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    if (currentList.isEmpty) return;

    if (state.activeTemplate != null) {
      if (state.currentTemplateStepIndex > 0) {
        int newIndex = state.currentTemplateStepIndex - 1;
        if (state.currentMode == StopwatchMode.regresoACero) {
          state = state.copyWith(currentTemplateStepIndexRAC: newIndex);
        } else {
          state = state.copyWith(currentTemplateStepIndexCont: newIndex);
        }
        
        final item = Map<String, dynamic>.from(currentList[newIndex]);
        item['time'] = 0;
        if (state.currentMode == StopwatchMode.continuo) {
          item['cumulative_time'] = 0;
        }
        item['status'] = 'pending';
        item['type'] = 'normal';
        currentList[newIndex] = item;
        
        taskNameController.text = state.activeTemplate!.steps[newIndex % state.activeTemplate!.steps.length];
        
        int targetLength = newIndex + (state.activeTemplate!.steps.length - (newIndex % state.activeTemplate!.steps.length));
        if (currentList.length > targetLength) {
          currentList.removeRange(targetLength, currentList.length);
        }
      }
    } else {
      currentList.removeLast();
    }
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }
    
    _recalculateLastRecordedTime();
    
    saveTimeData();
    calculateStatistics();
    
    scaffoldMessengerKey.currentState?.clearSnackBars();
    _showSnackBar('Último registro deshecho.', Icons.undo, Colors.orangeAccent);
  }

  void calculateStatistics() {
    final currentList = state.activeRecordedTimes;
    if (currentList.isEmpty) {
      state = state.copyWith(averageTime: 0.0, minTime: 0.0, maxTime: 0.0, stdDev: 0.0);
      return;
    }
    
    final validTimes = currentList
        .where((e) => (e['type'] ?? 'normal') != 'outlier' && (e['time'] as int) > 0 && e['status'] != 'pending')
        .map((e) => e['time'] as int)
        .toList();
        
    if (validTimes.isEmpty) {
      state = state.copyWith(averageTime: 0.0, minTime: 0.0, maxTime: 0.0, stdDev: 0.0);
      return;
    }
    
    double avg = validTimes.reduce((a, b) => a + b) / validTimes.length;
    double mTime = validTimes.reduce(min).toDouble();
    double mxTime = validTimes.reduce(max).toDouble();
    double sDev = 0.0;
    
    if (validTimes.length > 1) {
      final variance = validTimes.map((t) => pow(t - avg, 2)).reduce((a, b) => a + b) / (validTimes.length - 1);
      sDev = sqrt(variance);
    }
    
    state = state.copyWith(averageTime: avg, minTime: mTime, maxTime: mxTime, stdDev: sDev);
  }

  void resetAll() {
    triggerHaptic();
    stopTimerLogic();
    _stopwatch.reset();
    
    state = state.copyWith(
      baseTimeMs: 0,
      activeStudyIdRAC: () => state.currentMode == StopwatchMode.regresoACero ? null : state.activeStudyIdRAC,
      activeStudyIdCont: () => state.currentMode == StopwatchMode.continuo ? null : state.activeStudyIdCont,
      recordedTimesRegresoACero: state.currentMode == StopwatchMode.regresoACero ? [] : state.recordedTimesRegresoACero,
      recordedTimesContinuo: state.currentMode == StopwatchMode.continuo ? [] : state.recordedTimesContinuo,
      lastRecordedTimeMs: 0,
      hasExported: true
    );
    
    _syncStartTime();
    
    if (state.activeTemplate != null && state.activeTemplate!.steps.isNotEmpty) {
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(currentTemplateStepIndexRAC: 0);
      } else {
        state = state.copyWith(currentTemplateStepIndexCont: 0);
      }
      _appendTemplatePlaceholders();
      taskNameController.text = state.activeTemplate!.steps[0];
    } else {
      taskNameController.text = ''; 
      _setMasterName('');
    }

    saveTimeData();
    calculateStatistics();
  }

  Future<void> exportData() async {
    state = state.copyWith(animateExportTrigger: state.animateExportTrigger + 1);
    final dataToExport = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToExport.isEmpty) {
      _showSnackBar('No hay datos para exportar.', Icons.warning_amber_rounded, Colors.orange);
      return;
    }
    try {
      final fileName = await _export.exportDataToExcel(
        data: dataToExport,
        mode: state.currentMode,
        activeTemplate: state.activeTemplate,
        studyName: state.masterStudyName.isNotEmpty ? state.masterStudyName : 'Estudio_General',
        globalRating: state.globalRating,
        cycleRatings: state.currentMode == StopwatchMode.regresoACero ? state.cycleRatingsRAC : state.cycleRatingsCont,
      );
      
      if (fileName != null) {
        state = state.copyWith(hasExported: true);
        _showSnackBar('Exportado: $fileName', Icons.check_circle, Colors.tealAccent);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Icons.error_outline, Colors.redAccent);
    }
  }

  Future<void> importExcel() async {
    try {
      final result = await _export.importDataFromExcel();
      if (result != null) {
        final StopwatchMode importedMode = result['mode'];
        final List<Map<String, dynamic>> importedTimes = result['times'];

        setMode(importedMode); 
        clearTemplate(); 
        resetAll();
        
        if (importedMode == StopwatchMode.regresoACero) {
          state = state.copyWith(recordedTimesRegresoACero: importedTimes);
        } else {
          state = state.copyWith(recordedTimesContinuo: importedTimes);
        }
        
        _recalculateLastRecordedTime();
        if (state.currentMode == StopwatchMode.continuo) {
          state = state.copyWith(baseTimeMs: state.lastRecordedTimeMs);
        }
        
        state = state.copyWith(hasExported: true); 
        saveTimeData();
        calculateStatistics();
        _syncStartTime(); 
        
        _showSnackBar('Estudio importado correctamente.', Icons.file_download_done, Colors.tealAccent);
      }
    } catch (e) {
      _showSnackBar(e.toString(), Icons.error_outline, Colors.redAccent);
    }
  }

  Future<void> saveCurrentStudyToHistory(String studyName) async {
    final dataToSave = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToSave.isEmpty) return;
    
    int newId = await _storage.saveStudyToHistory(
      name: studyName,
      mode: state.currentMode,
      times: dataToSave,
      template: state.activeTemplate, 
    );
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(activeStudyIdRAC: () => newId);
    } else {
      state = state.copyWith(activeStudyIdCont: () => newId);
    }
    
    _setMasterName(studyName);
    
    if (state.activeTemplate == null) {
      taskNameController.text = studyName;
    }

    saveTimerState(); 

    _showSnackBar('Estudio "$studyName" guardado con éxito.', Icons.save, Colors.tealAccent);
  }

  Future<void> updateCurrentStudy() async {
    final dataToSave = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToSave.isEmpty || state.activeStudyId == null) return;
    
    await _storage.updateExistingStudy(
      id: state.activeStudyId!,
      mode: state.currentMode,
      times: dataToSave,
      template: state.activeTemplate, 
    );
    
    saveTimerState();

    _showSnackBar('Estudio actualizado correctamente.', Icons.update, Colors.tealAccent);
  }

  void loadStudyFromHistory(StudyModel study) {
    setMode(study.mode); 
    clearTemplate(); 
    resetAll();
    
    if (study.mode == StopwatchMode.regresoACero) {
      state = state.copyWith(activeStudyIdRAC: () => study.id);
    } else {
      state = state.copyWith(activeStudyIdCont: () => study.id);
    }
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
      state = state.copyWith(recordedTimesRegresoACero: convertedTimes);
    } else {
      state = state.copyWith(recordedTimesContinuo: convertedTimes);
    }
    
    if (study.isTemplate && study.templateSteps.isNotEmpty) {
      final t = OperationTemplate()
        ..id = -1 
        ..name = study.name
        ..steps = study.templateSteps;
        
      if (study.mode == StopwatchMode.regresoACero) {
        state = state.copyWith(activeTemplateRAC: () => t, currentTemplateStepIndexRAC: convertedTimes.length);
      } else {
        state = state.copyWith(activeTemplateCont: () => t, currentTemplateStepIndexCont: convertedTimes.length);
      }
      
      _restorePlaceholdersForList(state.activeRecordedTimes, state.activeTemplate!);
      
      taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
    } else {
      taskNameController.text = study.name;
    }
    
    _recalculateLastRecordedTime();
    if (state.currentMode == StopwatchMode.continuo) {
      state = state.copyWith(baseTimeMs: state.lastRecordedTimeMs);
    }

    saveTimeData();
    saveTimerState();
    calculateStatistics();
    _showSnackBar('Estudio cargado: ${study.name}', Icons.folder_open, Colors.blueAccent);
  }

  void clearActiveStudyId() {
    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(activeStudyIdRAC: () => null);
    } else {
      state = state.copyWith(activeStudyIdCont: () => null);
    }
    saveTimerState();
  }

  String formatTime(double milliseconds, {bool forExport = false}) {
    if (milliseconds < 0) return "00:00.00";
    
    if (state.timeFormat == TimeFormat.seconds) {
      String val = (milliseconds / 1000).toStringAsFixed(2);
      return forExport ? val : '$val s';
    } else if (state.timeFormat == TimeFormat.minutes) {
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
}