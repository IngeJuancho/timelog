import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../storage_service.dart';
import '../time_log_state.dart';

class TimeLogPreferencesService {
  final StorageService _storage = StorageService();

  Future<TimeLogStateLoadedData> loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    bool usePhysicalButtons = prefs.getBool('usePhysicalButtons') ?? false;
    bool useHapticFeedback = prefs.getBool('useHapticFeedback') ?? false;
    bool recordOnPause = prefs.getBool('recordOnPause') ?? false;
    bool isAmoledMode = prefs.getBool('isAmoledMode') ?? true;

    T safeEnum<T>(List<T> values, int index, T fallback) {
      if (index >= 0 && index < values.length) return values[index];
      return fallback;
    }

    int hapticIndex = prefs.getInt('hapticLevel') ?? HapticLevel.medium.index;
    HapticLevel hapticLevel = safeEnum(HapticLevel.values, hapticIndex, HapticLevel.medium);

    int formatIndex = prefs.getInt('timeFormat') ?? TimeFormat.standard.index;
    TimeFormat timeFormat = safeEnum(TimeFormat.values, formatIndex, TimeFormat.standard);

    PhysicalButtonAction volUpActionRAC = safeEnum(
        PhysicalButtonAction.values,
        prefs.getInt('volUpActionRAC') ?? PhysicalButtonAction.lapSnapback.index,
        PhysicalButtonAction.lapSnapback);
    PhysicalButtonAction volDownActionRAC = safeEnum(
        PhysicalButtonAction.values,
        prefs.getInt('volDownActionRAC') ?? PhysicalButtonAction.stopAndRecord.index,
        PhysicalButtonAction.stopAndRecord);
    PhysicalButtonAction volUpActionCont = safeEnum(
        PhysicalButtonAction.values,
        prefs.getInt('volUpActionCont') ?? PhysicalButtonAction.lapSnapback.index,
        PhysicalButtonAction.lapSnapback);
    PhysicalButtonAction volDownActionCont = safeEnum(
        PhysicalButtonAction.values,
        prefs.getInt('volDownActionCont') ?? PhysicalButtonAction.stopAndRecord.index,
        PhysicalButtonAction.stopAndRecord);

    List<Map<String, dynamic>> racTimes = [];
    String? racJson = prefs.getString('times_rac');
    if (racJson != null) {
      try {
        racTimes = List<Map<String, dynamic>>.from(jsonDecode(racJson));
      } catch (e) {
        racTimes = [];
      }
    }

    List<Map<String, dynamic>> contTimes = [];
    String? contJson = prefs.getString('times_cont');
    if (contJson != null) {
      try {
        contTimes = List<Map<String, dynamic>>.from(jsonDecode(contJson));
      } catch (e) {
        contTimes = [];
      }
    }

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

    StopwatchMode currentMode = safeEnum(
        StopwatchMode.values,
        prefs.getInt('currentMode') ?? StopwatchMode.regresoACero.index,
        StopwatchMode.regresoACero);

    int? activeStudyIdRAC = prefs.getInt('activeStudyIdRAC') ?? prefs.getInt('activeStudyId');
    int? activeStudyIdCont = prefs.getInt('activeStudyIdCont') ?? prefs.getInt('activeStudyId');

    int templateIdRAC = prefs.getInt('activeTemplateIdRAC') ?? prefs.getInt('activeTemplateId') ?? -1;
    int templateIdCont = prefs.getInt('activeTemplateIdCont') ?? prefs.getInt('activeTemplateId') ?? -1;
    final templates = await _storage.getAllTemplates();

    OperationTemplate? activeTemplateRAC;
    if (templateIdRAC != -1) {
      activeTemplateRAC = templates
          .cast<OperationTemplate?>()
          .firstWhere((t) => t?.id == templateIdRAC, orElse: () => null);
    } else {
      String? vNameRAC = prefs.getString('virtualTemplateNameRAC');
      List<String>? vStepsRAC = prefs.getStringList('virtualTemplateStepsRAC');
      if (vNameRAC != null && vStepsRAC != null) {
        activeTemplateRAC = OperationTemplate()..id = -1..name = vNameRAC..steps = vStepsRAC;
      }
    }

    OperationTemplate? activeTemplateCont;
    if (templateIdCont != -1) {
      activeTemplateCont = templates
          .cast<OperationTemplate?>()
          .firstWhere((t) => t?.id == templateIdCont, orElse: () => null);
    } else {
      String? vNameCont = prefs.getString('virtualTemplateNameCont');
      List<String>? vStepsCont = prefs.getStringList('virtualTemplateStepsCont');
      if (vNameCont != null && vStepsCont != null) {
        activeTemplateCont = OperationTemplate()..id = -1..name = vNameCont..steps = vStepsCont;
      }
    }

    bool wasRunning = prefs.getBool('isRunning') ?? false;
    int savedStartTime = prefs.getInt('startTimeEpoch') ?? 0;
    int baseTimeMs = prefs.getInt('baseTimeMs') ?? 0;

    return TimeLogStateLoadedData(
      usePhysicalButtons: usePhysicalButtons,
      useHapticFeedback: useHapticFeedback,
      recordOnPause: recordOnPause,
      isAmoledMode: isAmoledMode,
      hapticLevel: hapticLevel,
      timeFormat: timeFormat,
      volUpActionRAC: volUpActionRAC,
      volDownActionRAC: volDownActionRAC,
      volUpActionCont: volUpActionCont,
      volDownActionCont: volDownActionCont,
      racTimes: racTimes,
      contTimes: contTimes,
      savedTaskNameRAC: savedTaskNameRAC,
      savedTaskNameCont: savedTaskNameCont,
      cycleRatingsRAC: cycleRatingsRAC,
      cycleRatingsCont: cycleRatingsCont,
      currentMode: currentMode,
      activeStudyIdRAC: activeStudyIdRAC,
      activeStudyIdCont: activeStudyIdCont,
      activeTemplateRAC: activeTemplateRAC,
      activeTemplateCont: activeTemplateCont,
      wasRunning: wasRunning,
      savedStartTime: savedStartTime,
      baseTimeMs: baseTimeMs,
    );
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
    await prefs.setBool('isAmoledMode', newState.isAmoledMode);
  }

  Future<void> saveTimeData(TimeLogState state) async {
    final prefs = await SharedPreferences.getInstance();
    final racDone = state.recordedTimesRegresoACero.where((e) => e['status'] != 'pending').toList();
    final contDone = state.recordedTimesContinuo.where((e) => e['status'] != 'pending').toList();
    await prefs.setString('times_rac', jsonEncode(racDone));
    await prefs.setString('times_cont', jsonEncode(contDone));
  }

  Future<void> saveTimerState({
    required TimeLogState state,
    required bool isRunning,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRunning', isRunning);
    await prefs.setInt('baseTimeMs', state.baseTimeMs);
    await prefs.setInt('startTimeEpoch', state.startTimeEpoch ?? 0);
    await prefs.setInt('currentMode', state.currentMode.index);

    await prefs.setString('taskNameRAC', state.savedTaskNameRAC);
    await prefs.setString('taskNameCont', state.savedTaskNameCont);

    await prefs.setString(
        'cycleRatingsRAC', jsonEncode(state.cycleRatingsRAC.map((k, v) => MapEntry(k.toString(), v))));
    await prefs.setString(
        'cycleRatingsCont', jsonEncode(state.cycleRatingsCont.map((k, v) => MapEntry(k.toString(), v))));

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
}

class TimeLogStateLoadedData {
  final bool usePhysicalButtons;
  final bool useHapticFeedback;
  final bool recordOnPause;
  final bool isAmoledMode;
  final HapticLevel hapticLevel;
  final TimeFormat timeFormat;
  final PhysicalButtonAction volUpActionRAC;
  final PhysicalButtonAction volDownActionRAC;
  final PhysicalButtonAction volUpActionCont;
  final PhysicalButtonAction volDownActionCont;
  final List<Map<String, dynamic>> racTimes;
  final List<Map<String, dynamic>> contTimes;
  final String savedTaskNameRAC;
  final String savedTaskNameCont;
  final Map<int, int> cycleRatingsRAC;
  final Map<int, int> cycleRatingsCont;
  final StopwatchMode currentMode;
  final int? activeStudyIdRAC;
  final int? activeStudyIdCont;
  final OperationTemplate? activeTemplateRAC;
  final OperationTemplate? activeTemplateCont;
  final bool wasRunning;
  final int savedStartTime;
  final int baseTimeMs;

  const TimeLogStateLoadedData({
    required this.usePhysicalButtons,
    required this.useHapticFeedback,
    required this.recordOnPause,
    required this.isAmoledMode,
    required this.hapticLevel,
    required this.timeFormat,
    required this.volUpActionRAC,
    required this.volDownActionRAC,
    required this.volUpActionCont,
    required this.volDownActionCont,
    required this.racTimes,
    required this.contTimes,
    required this.savedTaskNameRAC,
    required this.savedTaskNameCont,
    required this.cycleRatingsRAC,
    required this.cycleRatingsCont,
    required this.currentMode,
    required this.activeStudyIdRAC,
    required this.activeStudyIdCont,
    required this.activeTemplateRAC,
    required this.activeTemplateCont,
    required this.wasRunning,
    required this.savedStartTime,
    required this.baseTimeMs,
  });
}
