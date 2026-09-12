import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'main.dart';
import 'storage_service.dart';
import 'export_service.dart';
import 'time_log_state.dart';
import 'theme.dart';
import 'services/time_log_calculator.dart';
import 'services/hardware_button_service.dart';
import 'services/time_log_preferences_service.dart';

final timeLogProvider = NotifierProvider<TimeLogNotifier, TimeLogState>(TimeLogNotifier.new);

class TimeLogNotifier extends Notifier<TimeLogState> {
  final StorageService _storage = StorageService();
  final ExportService _export = ExportService();
  final TimeLogPreferencesService _prefsService = TimeLogPreferencesService();

  final Stopwatch _stopwatch = Stopwatch();
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController ratingController = TextEditingController(text: "100");
  Timer? _snackBarTimer;

  int get elapsedMilliseconds => state.baseTimeMs + _stopwatch.elapsedMilliseconds;
  bool get isRunning => _stopwatch.isRunning;

  @override
  TimeLogState build() {
    _initNativeButtonListener();
    loadAllData();
    ref.onDispose(() {
      HardwareButtonService.dispose();
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
    final lastTime = TimeLogCalculator.recalculateLastRecordedTime(
      mode: state.currentMode,
      recordedTimesContinuo: state.recordedTimesContinuo,
      activeTemplate: state.activeTemplate,
    );
    state = state.copyWith(lastRecordedTimeMs: lastTime);
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

  void attachLiveTemplate(OperationTemplate template) {
    if (template.steps.isEmpty) return;

    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    currentList.removeWhere((e) => e['status'] == 'pending');

    for (int i = 0; i < currentList.length; i++) {
      final item = Map<String, dynamic>.from(currentList[i]);
      item['step_index'] = i % template.steps.length;
      currentList[i] = item;
    }

    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(
        activeTemplateRAC: () => template,
        currentTemplateStepIndexRAC: currentList.length,
        recordedTimesRegresoACero: currentList,
      );
    } else {
      state = state.copyWith(
        activeTemplateCont: () => template,
        currentTemplateStepIndexCont: currentList.length,
        recordedTimesContinuo: currentList,
      );
    }

    _appendTemplatePlaceholders();
    _setMasterName(template.name);
    taskNameController.text = template.steps[state.currentTemplateStepIndex % template.steps.length];

    _recalculateLastRecordedTime();
    saveTimeData();
    saveTimerState();
    calculateStatistics();
  }

  void _appendTemplatePlaceholders() {
    if (state.activeTemplate == null) return;
    final template = state.activeTemplate!;
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);

    final doneCount = currentList.where((e) => e['status'] != 'pending').length;
    final currentStepInCycle = doneCount % template.steps.length;

    for (int i = currentStepInCycle; i < template.steps.length; i++) {
      currentList.add({
        'name': template.steps[i],
        'time': 0,
        'cumulative_time': 0,
        'type': 'normal',
        'status': 'pending',
        'step_index': i,
      });
    }

    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }
  }

  void _restorePlaceholdersForList(List<Map<String, dynamic>> list, OperationTemplate template) {
    if (template.steps.isEmpty) return;

    list.removeWhere((e) => e['status'] == 'pending');
    final doneCount = list.length;
    final currentStepInCycle = doneCount % template.steps.length;

    for (int i = currentStepInCycle; i < template.steps.length; i++) {
      list.add({
        'name': template.steps[i],
        'time': 0,
        'cumulative_time': 0,
        'type': 'normal',
        'status': 'pending',
        'step_index': i,
      });
    }
  }

  void clearTemplate() {
    if (state.currentMode == StopwatchMode.regresoACero) {
      final list = List<Map<String, dynamic>>.from(state.recordedTimesRegresoACero);
      list.removeWhere((e) => e['status'] == 'pending');
      state = state.copyWith(
        activeTemplateRAC: () => null,
        currentTemplateStepIndexRAC: 0,
        recordedTimesRegresoACero: list,
      );
    } else {
      final list = List<Map<String, dynamic>>.from(state.recordedTimesContinuo);
      list.removeWhere((e) => e['status'] == 'pending');
      state = state.copyWith(
        activeTemplateCont: () => null,
        currentTemplateStepIndexCont: 0,
        recordedTimesContinuo: list,
      );
    }

    _recalculateLastRecordedTime();

    taskNameController.clear();
    _setMasterName('');
    saveTimerState();
  }

  Future<void> loadAllData() async {
    final loaded = await _prefsService.loadAllData();

    int currentTemplateStepIndexRAC = 0;
    if (loaded.activeTemplateRAC != null) {
      currentTemplateStepIndexRAC = loaded.racTimes.length;
      if (loaded.currentMode == StopwatchMode.regresoACero) {
        _restorePlaceholdersForList(loaded.racTimes, loaded.activeTemplateRAC!);
      }
    }

    int currentTemplateStepIndexCont = 0;
    if (loaded.activeTemplateCont != null) {
      currentTemplateStepIndexCont = loaded.contTimes.length;
      if (loaded.currentMode == StopwatchMode.continuo) {
        _restorePlaceholdersForList(loaded.contTimes, loaded.activeTemplateCont!);
      }
    }

    state = state.copyWith(
      usePhysicalButtons: loaded.usePhysicalButtons,
      useHapticFeedback: loaded.useHapticFeedback,
      recordOnPause: loaded.recordOnPause,
      hapticLevel: loaded.hapticLevel,
      timeFormat: loaded.timeFormat,
      volUpActionRAC: loaded.volUpActionRAC,
      volDownActionRAC: loaded.volDownActionRAC,
      volUpActionCont: loaded.volUpActionCont,
      volDownActionCont: loaded.volDownActionCont,
      isAmoledMode: loaded.isAmoledMode,
      recordedTimesRegresoACero: loaded.racTimes,
      recordedTimesContinuo: loaded.contTimes,
      savedTaskNameRAC: loaded.savedTaskNameRAC,
      savedTaskNameCont: loaded.savedTaskNameCont,
      currentMode: loaded.currentMode,
      activeStudyIdRAC: () => loaded.activeStudyIdRAC,
      activeStudyIdCont: () => loaded.activeStudyIdCont,
      activeTemplateRAC: () => loaded.activeTemplateRAC,
      currentTemplateStepIndexRAC: currentTemplateStepIndexRAC,
      activeTemplateCont: () => loaded.activeTemplateCont,
      currentTemplateStepIndexCont: currentTemplateStepIndexCont,
      cycleRatingsRAC: loaded.cycleRatingsRAC,
      cycleRatingsCont: loaded.cycleRatingsCont,
    );

    _recalculateLastRecordedTime();

    if (state.activeTemplate != null) {
      taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
    } else {
      taskNameController.text = loaded.currentMode == StopwatchMode.regresoACero ? state.savedTaskNameRAC : state.savedTaskNameCont;
    }

    int baseTimeMs = loaded.baseTimeMs != 0 ? loaded.baseTimeMs : (loaded.currentMode == StopwatchMode.continuo ? state.lastRecordedTimeMs : 0);
    state = state.copyWith(baseTimeMs: baseTimeMs);

    if (loaded.wasRunning && loaded.savedStartTime > 0) {
      int missedTime = DateTime.now().millisecondsSinceEpoch - loaded.savedStartTime;
      state = state.copyWith(baseTimeMs: missedTime);
      _stopwatch.start();
      _syncStartTime();
    }

    calculateStatistics();
  }

  Future<void> saveSettings(TimeLogState newState) async {
    await _prefsService.saveSettings(newState);
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
    bool? isAmoledMode,
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
      isAmoledMode: isAmoledMode,
    );
    state = newState;
    saveSettings(newState);
  }

  Future<void> saveTimeData() async {
    await _prefsService.saveTimeData(state);
  }

  Future<void> saveTimerState() async {
    await _prefsService.saveTimerState(state: state, isRunning: _stopwatch.isRunning);
  }

  Future<void> updateTaskName(String value) async {
    _setMasterName(value);
    if (state.activeStudyId != null) {
      clearActiveStudyId();
    }
    saveTimerState();
  }

  void updateGlobalRating(String value) {
    int? parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      state = state.copyWith(globalRating: parsed);
    }
  }

  void applyRatingToCurrentCycle() {
    int? rating = int.tryParse(ratingController.text.trim());
    if (rating == null || rating < 10 || rating > 300) {
      _showSnackBar('Ingresa un rating válido (ej. 100)', Icons.warning_amber_rounded, Colors.orangeAccent);
      return;
    }

    int currentCycle = 0;
    if (state.activeTemplate != null && state.activeTemplate!.steps.isNotEmpty) {
      currentCycle = state.currentTemplateStepIndex ~/ state.activeTemplate!.steps.length;
    } else {
      currentCycle = state.activeRecordedTimes.where((e) => e['status'] != 'pending').length;
    }

    applyRatingToCycle(currentCycle, rating);

    _showSnackBar('Rating $rating% asignado al Ciclo ${currentCycle + 1}', Icons.star_rounded, Colors.amber);
  }

  void applyRatingToCycle(int cycleIndex, int rating) {
    if (state.currentMode == StopwatchMode.regresoACero) {
      final newMap = Map<int, int>.from(state.cycleRatingsRAC);
      newMap[cycleIndex] = rating;
      state = state.copyWith(cycleRatingsRAC: newMap);
    } else {
      final newMap = Map<int, int>.from(state.cycleRatingsCont);
      newMap[cycleIndex] = rating;
      state = state.copyWith(cycleRatingsCont: newMap);
    }
    saveTimerState();
  }

  void syncActiveStudyName(String newName) {
    _setMasterName(newName);
    if (state.activeTemplate == null) {
      taskNameController.text = newName;
    }
    saveTimerState();
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
    HardwareButtonService.initialize(
      shouldHandle: () => state.usePhysicalButtons,
      onButtonPressed: _handleNativeButtonPress,
    );
  }

  void triggerHaptic() {
    HardwareButtonService.triggerHaptic(
      enabled: state.useHapticFeedback,
      level: state.hapticLevel,
    );
  }

  void setMode(StopwatchMode mode) {
    if (state.currentMode == mode) return;

    triggerHaptic();
    stopTimerLogic();
    _stopwatch.reset();

    state = state.copyWith(
      currentMode: mode,
      baseTimeMs: 0,
      hasExported: true,
    );

    _recalculateLastRecordedTime();

    if (state.activeTemplate != null && state.activeTemplate!.steps.isNotEmpty) {
      taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
    } else {
      taskNameController.text = mode == StopwatchMode.regresoACero ? state.savedTaskNameRAC : state.savedTaskNameCont;
    }

    _syncStartTime();
    calculateStatistics();
  }

  void toggleElementType(int index) {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    if (index >= currentList.length || currentList[index]['status'] == 'pending') return;

    final item = Map<String, dynamic>.from(currentList[index]);
    item['type'] = item['type'] == 'normal' ? 'outlier' : 'normal';
    currentList[index] = item;

    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(recordedTimesRegresoACero: currentList);
    } else {
      state = state.copyWith(recordedTimesContinuo: currentList);
    }

    saveTimeData();
    calculateStatistics();
  }

  void deleteItem(int index) {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    if (index >= currentList.length) return;

    currentList.removeAt(index);

    if (state.currentMode == StopwatchMode.regresoACero) {
      state = state.copyWith(
        recordedTimesRegresoACero: currentList,
        currentTemplateStepIndexRAC: state.activeTemplate != null
            ? (state.currentTemplateStepIndexRAC > 0 ? state.currentTemplateStepIndexRAC - 1 : 0)
            : state.currentTemplateStepIndexRAC,
      );
    } else {
      state = state.copyWith(
        recordedTimesContinuo: currentList,
        currentTemplateStepIndexCont: state.activeTemplate != null
            ? (state.currentTemplateStepIndexCont > 0 ? state.currentTemplateStepIndexCont - 1 : 0)
            : state.currentTemplateStepIndexCont,
      );
    }

    _recalculateLastRecordedTime();
    saveTimeData();
    calculateStatistics();
  }

  void mergeWithPrevious(int index) {
    final currentList = List<Map<String, dynamic>>.from(state.activeRecordedTimes);
    if (index <= 0 || index >= currentList.length) return;

    final current = currentList[index];
    final previous = currentList[index - 1];

    if (current['status'] == 'pending' || previous['status'] == 'pending') return;

    final int mergedTime = (previous['time'] as int) + (current['time'] as int);

    final mergedItem = Map<String, dynamic>.from(previous);
    mergedItem['time'] = mergedTime;

    if (state.currentMode == StopwatchMode.continuo) {
      mergedItem['cumulative_time'] = current['cumulative_time'];
    }

    currentList[index - 1] = mergedItem;
    currentList.removeAt(index);

    if (state.activeTemplate != null) {
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(
          currentTemplateStepIndexRAC: state.currentTemplateStepIndexRAC > 0
              ? state.currentTemplateStepIndexRAC - 1
              : 0,
        );
      } else {
        state = state.copyWith(
          currentTemplateStepIndexCont: state.currentTemplateStepIndexCont > 0
              ? state.currentTemplateStepIndexCont - 1
              : 0,
        );
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
          showResetDialogTrigger: state.showResetDialogTrigger + 1,
        );
        break;
      case PhysicalButtonAction.none:
        break;
    }
  }

  void startTimerLogic() {
    triggerHaptic();
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _syncStartTime();
    }
  }

  void stopTimerLogic() {
    triggerHaptic();
    if (_stopwatch.isRunning) {
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
      } else {
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
        item['status'] = 'pending';
        currentList[newIndex] = item;

        int lastCycleStart = (newIndex ~/ state.activeTemplate!.steps.length + 1) * state.activeTemplate!.steps.length;
        if (currentList.length > lastCycleStart) {
          currentList.removeRange(lastCycleStart, currentList.length);
        }

        if (state.currentMode == StopwatchMode.regresoACero) {
          state = state.copyWith(recordedTimesRegresoACero: currentList);
        } else {
          state = state.copyWith(recordedTimesContinuo: currentList);
        }

        taskNameController.text = state.activeTemplate!.steps[newIndex % state.activeTemplate!.steps.length];
      }
    } else {
      currentList.removeLast();
      if (state.currentMode == StopwatchMode.regresoACero) {
        state = state.copyWith(recordedTimesRegresoACero: currentList);
      } else {
        state = state.copyWith(recordedTimesContinuo: currentList);
      }
    }

    _recalculateLastRecordedTime();

    saveTimeData();
    calculateStatistics();

    scaffoldMessengerKey.currentState?.clearSnackBars();
    _showSnackBar('Último registro deshecho.', Icons.undo, Colors.orangeAccent);
  }

  void calculateStatistics() {
    final stats = TimeLogCalculator.calculate(state.activeRecordedTimes);
    state = state.copyWith(
      averageTime: stats.averageTime,
      minTime: stats.minTime,
      maxTime: stats.maxTime,
      stdDev: stats.stdDev,
    );
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
      cycleRatingsRAC: state.currentMode == StopwatchMode.regresoACero ? const {} : state.cycleRatingsRAC,
      cycleRatingsCont: state.currentMode == StopwatchMode.continuo ? const {} : state.cycleRatingsCont,
      lastRecordedTimeMs: 0,
      hasExported: true,
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
        final List<String> stepNames = (result['stepNames'] as List<dynamic>?)?.cast<String>() ?? [];
        final Map<int, int> cycleRatings = (result['cycleRatings'] as Map<dynamic, dynamic>?)?.cast<int, int>() ?? {};
        final String? studyName = result['studyName'];

        setMode(importedMode);
        clearTemplate();
        resetAll();

        if (importedMode == StopwatchMode.regresoACero) {
          state = state.copyWith(
            recordedTimesRegresoACero: importedTimes,
            cycleRatingsRAC: cycleRatings,
          );
        } else {
          state = state.copyWith(
            recordedTimesContinuo: importedTimes,
            cycleRatingsCont: cycleRatings,
          );
        }

        if (stepNames.isNotEmpty) {
          OperationTemplate importedTemplate = OperationTemplate()
            ..id = -1
            ..name = studyName ?? 'Estudio Importado'
            ..steps = stepNames;

          if (importedMode == StopwatchMode.regresoACero) {
            state = state.copyWith(
              activeTemplateRAC: () => importedTemplate,
              currentTemplateStepIndexRAC: importedTimes.length,
            );
          } else {
            state = state.copyWith(
              activeTemplateCont: () => importedTemplate,
              currentTemplateStepIndexCont: importedTimes.length,
            );
          }

          _restorePlaceholdersForList(
            state.currentMode == StopwatchMode.regresoACero
                ? state.recordedTimesRegresoACero
                : state.recordedTimesContinuo,
            state.activeTemplate!,
          );

          taskNameController.text = state.activeTemplate!.steps[state.currentTemplateStepIndex % state.activeTemplate!.steps.length];
        } else {
          clearTemplate();
          if (studyName != null && studyName.isNotEmpty) {
            taskNameController.text = studyName;
          }
        }

        if (studyName != null && studyName.isNotEmpty) {
          syncActiveStudyName(studyName);
        }

        _recalculateLastRecordedTime();
        if (state.currentMode == StopwatchMode.continuo) {
          state = state.copyWith(baseTimeMs: state.lastRecordedTimeMs);
        }

        state = state.copyWith(hasExported: true);
        saveTimeData();
        saveTimerState();
        calculateStatistics();
        _syncStartTime();

        final ratingMsg = cycleRatings.isNotEmpty ? " con calificaciones" : "";
        _showSnackBar('Estudio "$studyName" importado correctamente$ratingMsg.', Icons.file_download_done, AppTheme.primaryTeal);
      }
    } catch (e) {
      _showSnackBar(e.toString(), Icons.error_outline, Colors.redAccent);
    }
  }

  Future<void> saveCurrentStudyToHistory(String studyName) async {
    final dataToSave = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToSave.isEmpty) return;

    final activeRatings = state.currentMode == StopwatchMode.regresoACero ? state.cycleRatingsRAC : state.cycleRatingsCont;
    int newId = await _storage.saveStudyToHistory(
      name: studyName,
      mode: state.currentMode,
      times: dataToSave,
      template: state.activeTemplate,
      cycleRatings: activeRatings,
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

    _showSnackBar('Estudio "$studyName" guardado con éxito.', Icons.save, AppTheme.primaryTeal);
  }

  Future<void> updateCurrentStudy() async {
    final dataToSave = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (dataToSave.isEmpty || state.activeStudyId == null) return;

    final activeRatings = state.currentMode == StopwatchMode.regresoACero ? state.cycleRatingsRAC : state.cycleRatingsCont;
    await _storage.updateExistingStudy(
      id: state.activeStudyId!,
      mode: state.currentMode,
      times: dataToSave,
      template: state.activeTemplate,
      cycleRatings: activeRatings,
    );

    saveTimerState();

    _showSnackBar('Estudio actualizado correctamente.', Icons.update, AppTheme.primaryTeal);
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
      'step_index': t.stepIndex,
    }).toList();

    if (study.mode == StopwatchMode.regresoACero) {
      state = state.copyWith(
        recordedTimesRegresoACero: convertedTimes,
        cycleRatingsRAC: study.cycleRatingsMap,
      );
    } else {
      state = state.copyWith(
        recordedTimesContinuo: convertedTimes,
        cycleRatingsCont: study.cycleRatingsMap,
      );
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
    _snackBarTimer?.cancel();
    double bottomMargin = 16.0;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final screenHeight = view.physicalSize.height / view.devicePixelRatio;
      bottomMargin = screenHeight - 140;
      if (bottomMargin < 16.0) bottomMargin = 16.0;
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: bottomMargin, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.up,
      ),
    );
    _snackBarTimer = Timer(const Duration(seconds: 2), () {
      scaffoldMessengerKey.currentState?.clearSnackBars();
    });
  }

  void _showSnackBarWithUndo(String message, IconData icon, Color iconColor) {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    _snackBarTimer?.cancel();
    double bottomMargin = 16.0;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final screenHeight = view.physicalSize.height / view.devicePixelRatio;
      bottomMargin = screenHeight - 140;
      if (bottomMargin < 16.0) bottomMargin = 16.0;
    }

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: bottomMargin, left: 16, right: 16),
        elevation: 6,
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.up,
        action: SnackBarAction(label: 'DESHACER', textColor: Colors.orangeAccent, onPressed: undoLastRecord),
      ),
    );
    _snackBarTimer = Timer(const Duration(seconds: 4), () {
      scaffoldMessengerKey.currentState?.clearSnackBars();
    });
  }
}