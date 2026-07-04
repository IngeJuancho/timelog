import 'package:flutter/foundation.dart';
import 'models.dart';

@immutable
class TimeLogState {
  final int baseTimeMs;
  final int? startTimeEpoch;
  final int? activeStudyIdRAC;
  final int? activeStudyIdCont;
  final OperationTemplate? activeTemplateRAC;
  final int currentTemplateStepIndexRAC;
  final OperationTemplate? activeTemplateCont;
  final int currentTemplateStepIndexCont;
  final String savedTaskNameRAC;
  final String savedTaskNameCont;

  final int animateStartTrigger;
  final int animateSecondaryTrigger;
  final int animateResetTrigger;
  final int animateExportTrigger;
  final int showResetDialogTrigger;

  final List<Map<String, dynamic>> recordedTimesRegresoACero;
  final List<Map<String, dynamic>> recordedTimesContinuo;

  final double averageTime;
  final double minTime;
  final double maxTime;
  final double stdDev;

  final StopwatchMode currentMode;
  final int lastRecordedTimeMs;
  final bool hasExported;
  final int globalRating;
  final bool isRunning;

  // Settings
  final bool usePhysicalButtons;
  final bool useHapticFeedback;
  final HapticLevel hapticLevel;
  final bool recordOnPause;
  final TimeFormat timeFormat;
  final PhysicalButtonAction volUpActionRAC;
  final PhysicalButtonAction volDownActionRAC;
  final PhysicalButtonAction volUpActionCont;
  final PhysicalButtonAction volDownActionCont;

  const TimeLogState({
    this.baseTimeMs = 0,
    this.startTimeEpoch,
    this.activeStudyIdRAC,
    this.activeStudyIdCont,
    this.activeTemplateRAC,
    this.currentTemplateStepIndexRAC = 0,
    this.activeTemplateCont,
    this.currentTemplateStepIndexCont = 0,
    this.savedTaskNameRAC = '',
    this.savedTaskNameCont = '',
    this.animateStartTrigger = 0,
    this.animateSecondaryTrigger = 0,
    this.animateResetTrigger = 0,
    this.animateExportTrigger = 0,
    this.showResetDialogTrigger = 0,
    this.recordedTimesRegresoACero = const [],
    this.recordedTimesContinuo = const [],
    this.averageTime = 0.0,
    this.minTime = 0.0,
    this.maxTime = 0.0,
    this.stdDev = 0.0,
    this.currentMode = StopwatchMode.regresoACero,
    this.lastRecordedTimeMs = 0,
    this.hasExported = true,
    this.globalRating = 100,
    this.isRunning = false,
    this.usePhysicalButtons = false,
    this.useHapticFeedback = false,
    this.hapticLevel = HapticLevel.medium,
    this.recordOnPause = false,
    this.timeFormat = TimeFormat.standard,
    this.volUpActionRAC = PhysicalButtonAction.lapSnapback,
    this.volDownActionRAC = PhysicalButtonAction.stopAndRecord,
    this.volUpActionCont = PhysicalButtonAction.lapSnapback,
    this.volDownActionCont = PhysicalButtonAction.stopAndRecord,
  });

  // Getters auxiliares basados en el modo actual
  int? get activeStudyId => currentMode == StopwatchMode.regresoACero ? activeStudyIdRAC : activeStudyIdCont;
  OperationTemplate? get activeTemplate => currentMode == StopwatchMode.regresoACero ? activeTemplateRAC : activeTemplateCont;
  int get currentTemplateStepIndex => currentMode == StopwatchMode.regresoACero ? currentTemplateStepIndexRAC : currentTemplateStepIndexCont;
  
  List<Map<String, dynamic>> get activeRecordedTimes => 
      currentMode == StopwatchMode.regresoACero ? recordedTimesRegresoACero : recordedTimesContinuo;

  String get masterStudyName {
    String name = currentMode == StopwatchMode.regresoACero ? savedTaskNameRAC : savedTaskNameCont;
    if (name.isNotEmpty) return name;
    if (activeTemplate != null) return activeTemplate!.name;
    return ''; // El fallback final al text controller se maneja en el Notifier
  }

  TimeLogState copyWith({
    int? baseTimeMs,
    int? Function()? startTimeEpoch,
    int? Function()? activeStudyIdRAC,
    int? Function()? activeStudyIdCont,
    OperationTemplate? Function()? activeTemplateRAC,
    int? currentTemplateStepIndexRAC,
    OperationTemplate? Function()? activeTemplateCont,
    int? currentTemplateStepIndexCont,
    String? savedTaskNameRAC,
    String? savedTaskNameCont,
    int? animateStartTrigger,
    int? animateSecondaryTrigger,
    int? animateResetTrigger,
    int? animateExportTrigger,
    int? showResetDialogTrigger,
    List<Map<String, dynamic>>? recordedTimesRegresoACero,
    List<Map<String, dynamic>>? recordedTimesContinuo,
    double? averageTime,
    double? minTime,
    double? maxTime,
    double? stdDev,
    StopwatchMode? currentMode,
    int? lastRecordedTimeMs,
    bool? hasExported,
    bool? isRunning,
    bool? usePhysicalButtons,
    bool? useHapticFeedback,
    HapticLevel? hapticLevel,
    bool? recordOnPause,
    TimeFormat? timeFormat,
    PhysicalButtonAction? volUpActionRAC,
    PhysicalButtonAction? volDownActionRAC,
    PhysicalButtonAction? volUpActionCont,
    PhysicalButtonAction? volDownActionCont,
  }) {
    return TimeLogState(
      baseTimeMs: baseTimeMs ?? this.baseTimeMs,
      startTimeEpoch: startTimeEpoch != null ? startTimeEpoch() : this.startTimeEpoch,
      activeStudyIdRAC: activeStudyIdRAC != null ? activeStudyIdRAC() : this.activeStudyIdRAC,
      activeStudyIdCont: activeStudyIdCont != null ? activeStudyIdCont() : this.activeStudyIdCont,
      activeTemplateRAC: activeTemplateRAC != null ? activeTemplateRAC() : this.activeTemplateRAC,
      currentTemplateStepIndexRAC: currentTemplateStepIndexRAC ?? this.currentTemplateStepIndexRAC,
      activeTemplateCont: activeTemplateCont != null ? activeTemplateCont() : this.activeTemplateCont,
      currentTemplateStepIndexCont: currentTemplateStepIndexCont ?? this.currentTemplateStepIndexCont,
      savedTaskNameRAC: savedTaskNameRAC ?? this.savedTaskNameRAC,
      savedTaskNameCont: savedTaskNameCont ?? this.savedTaskNameCont,
      animateStartTrigger: animateStartTrigger ?? this.animateStartTrigger,
      animateSecondaryTrigger: animateSecondaryTrigger ?? this.animateSecondaryTrigger,
      animateResetTrigger: animateResetTrigger ?? this.animateResetTrigger,
      animateExportTrigger: animateExportTrigger ?? this.animateExportTrigger,
      showResetDialogTrigger: showResetDialogTrigger ?? this.showResetDialogTrigger,
      // Hacemos una copia profunda superficial para que cambie la referencia
      recordedTimesRegresoACero: recordedTimesRegresoACero ?? List.from(this.recordedTimesRegresoACero),
      recordedTimesContinuo: recordedTimesContinuo ?? List.from(this.recordedTimesContinuo),
      averageTime: averageTime ?? this.averageTime,
      minTime: minTime ?? this.minTime,
      maxTime: maxTime ?? this.maxTime,
      stdDev: stdDev ?? this.stdDev,
      currentMode: currentMode ?? this.currentMode,
      lastRecordedTimeMs: lastRecordedTimeMs ?? this.lastRecordedTimeMs,
      hasExported: hasExported ?? this.hasExported,
      globalRating: globalRating ?? this.globalRating,
      isRunning: isRunning ?? this.isRunning,
      usePhysicalButtons: usePhysicalButtons ?? this.usePhysicalButtons,
      useHapticFeedback: useHapticFeedback ?? this.useHapticFeedback,
      hapticLevel: hapticLevel ?? this.hapticLevel,
      recordOnPause: recordOnPause ?? this.recordOnPause,
      timeFormat: timeFormat ?? this.timeFormat,
      volUpActionRAC: volUpActionRAC ?? this.volUpActionRAC,
      volDownActionRAC: volDownActionRAC ?? this.volDownActionRAC,
      volUpActionCont: volUpActionCont ?? this.volUpActionCont,
      volDownActionCont: volDownActionCont ?? this.volDownActionCont,
    );
  }
}
