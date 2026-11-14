import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'theme.dart';
import 'time_log_controller.dart';
import 'time_log_state.dart';
import 'widgets/stopwatch/control_buttons.dart';
import 'widgets/stopwatch/export_options_sheet.dart';
import 'widgets/stopwatch/statistics_panel.dart';
import 'widgets/stopwatch/stopwatch_dialogs.dart';
import 'widgets/stopwatch/stopwatch_drawer.dart';
import 'widgets/stopwatch/task_name_input.dart';
import 'widgets/stopwatch/time_records_list.dart';
import 'widgets/stopwatch/timer_display.dart';

class StopwatchScreen extends ConsumerStatefulWidget {
  const StopwatchScreen({super.key});
  @override
  ConsumerState<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends ConsumerState<StopwatchScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late AnimationController _viewChangeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _viewChangeAnimation;

  late AnimationController _startButtonController;
  late AnimationController _resetButtonController;
  late AnimationController _secondaryButtonController;
  late AnimationController _exportButtonController;

  late Animation<double> _startButtonAnimation;
  late Animation<double> _resetButtonAnimation;
  late Animation<double> _secondaryButtonAnimation;
  late Animation<double> _exportButtonAnimation;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _taskNameFocusNode = FocusNode();
  double _previousBottomInset = 0.0;
  bool _showingAnalysis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();

    _taskNameFocusNode.addListener(() {
      if (!_taskNameFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(timeLogProvider).isRunning && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final bottomInset = view.viewInsets.bottom;
      if (_previousBottomInset > 0.0 && bottomInset == 0.0 && _taskNameFocusNode.hasFocus) {
        _taskNameFocusNode.unfocus();
      }
      _previousBottomInset = bottomInset;
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _viewChangeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    const buttonDuration = Duration(milliseconds: 100);
    _startButtonController = AnimationController(duration: buttonDuration, vsync: this);
    _resetButtonController = AnimationController(duration: buttonDuration, vsync: this);
    _secondaryButtonController = AnimationController(duration: buttonDuration, vsync: this);
    _exportButtonController = AnimationController(duration: buttonDuration, vsync: this);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _viewChangeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _viewChangeController, curve: Curves.easeOutCubic),
    );
    _startButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _startButtonController, curve: Curves.easeOutQuad),
    );
    _resetButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _resetButtonController, curve: Curves.easeOutQuad),
    );
    _secondaryButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _secondaryButtonController, curve: Curves.easeOutQuad),
    );
    _exportButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _exportButtonController, curve: Curves.easeOutQuad),
    );
  }

  void _animateButton(AnimationController controller) {
    controller.forward().then((_) => controller.reverse());
  }

  void _toggleView() {
    setState(() => _showingAnalysis = !_showingAnalysis);
    _viewChangeController.forward().then((_) => _viewChangeController.reverse());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _viewChangeController.dispose();
    _startButtonController.dispose();
    _resetButtonController.dispose();
    _secondaryButtonController.dispose();
    _exportButtonController.dispose();
    _scrollController.dispose();
    _taskNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timeLogProvider.select((s) => s.animateStartTrigger), (_, __) => _animateButton(_startButtonController));
    ref.listen(timeLogProvider.select((s) => s.animateSecondaryTrigger), (_, __) => _animateButton(_secondaryButtonController));
    ref.listen(timeLogProvider.select((s) => s.animateResetTrigger), (_, __) => _animateButton(_resetButtonController));
    ref.listen(timeLogProvider.select((s) => s.animateExportTrigger), (_, __) => _animateButton(_exportButtonController));
    ref.listen(timeLogProvider.select((s) => s.showResetDialogTrigger), (_, __) {
      final state = ref.read(timeLogProvider);
      final notifier = ref.read(timeLogProvider.notifier);
      StopwatchDialogs.confirmReset(context, state, notifier);
    });

    ref.listen(timeLogProvider.select((s) => s.isRunning), (_, isRunning) {
      if (isRunning && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (!isRunning && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);

    return TapRegion(
      onTapOutside: (_) {
        if (_taskNameFocusNode.hasFocus) {
          _taskNameFocusNode.unfocus();
        }
      },
      child: Scaffold(
        drawer: StopwatchDrawer(
          onSaveStudyRequested: () => StopwatchDialogs.promptSaveStudy(context, state, notifier),
        ),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              const Text('TimeLog', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Column(
                children: [
                  TimerDisplay(pulseAnimation: _pulseAnimation),
                  const SizedBox(height: 12),
                  TaskNameInput(
                    focusNode: _taskNameFocusNode,
                    state: state,
                    notifier: notifier,
                  ),
                  const SizedBox(height: 12),
                  ControlButtons(
                    startButtonAnimation: _startButtonAnimation,
                    secondaryButtonAnimation: _secondaryButtonAnimation,
                    resetButtonAnimation: _resetButtonAnimation,
                    exportButtonAnimation: _exportButtonAnimation,
                    onStartPressed: () {
                      _animateButton(_startButtonController);
                      if (state.isRunning) {
                        if (state.currentMode == StopwatchMode.continuo) {
                          notifier.recordTime(resetStopwatch: false, keepRunning: true);
                        } else {
                          notifier.stopTimerLogic();
                          notifier.recordTime(resetStopwatch: true, keepRunning: false);
                        }
                      } else {
                        notifier.startTimerLogic();
                      }
                    },
                    onSecondaryPressed: () {
                      _animateButton(_secondaryButtonController);
                      if (state.currentMode == StopwatchMode.regresoACero) {
                        notifier.recordTime(resetStopwatch: true, keepRunning: true);
                      } else {
                        notifier.stopTimerLogic();
                        notifier.recordTime(resetStopwatch: true, keepRunning: false);
                      }
                    },
                    onResetPressed: () {
                      _animateButton(_resetButtonController);
                      StopwatchDialogs.confirmReset(context, state, notifier);
                    },
                    onExportPressed: () {
                      _animateButton(_exportButtonController);
                      ExportOptionsSheet.show(
                        context,
                        onImportPressed: () => notifier.importExcel(),
                        onExportPressed: () => notifier.exportData(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: _buildStatsCard(state, notifier)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(TimeLogState state, TimeLogNotifier notifier) {
    final emerald = AppTheme.getTealAccent(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AnimatedBuilder(
      animation: _viewChangeAnimation,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF0F1116),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: isLight ? 0.8 : 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF14171E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: emerald.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _showingAnalysis ? Icons.pie_chart_outline_rounded : Icons.table_chart_outlined,
                            color: emerald,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _showingAnalysis ? 'MÉTRICAS & ANÁLISIS' : 'REGISTROS DE TIEMPO',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_showingAnalysis && state.currentMode == StopwatchMode.continuo) ...[
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => StopwatchDialogs.promptSaveCurrentTemplate(context, state, notifier),
                            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                            tooltip: 'Guardar como Plantilla',
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.amberIndustrial.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.amberIndustrial,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: _toggleView,
                          icon: Icon(
                            _showingAnalysis ? Icons.list_alt_rounded : Icons.analytics_outlined,
                            size: 15,
                          ),
                          label: Text(
                            _showingAnalysis ? 'Ver Tabla' : 'Métricas',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                              width: 1,
                            ),
                            foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                            backgroundColor: isLight ? Colors.white : const Color(0xFF1B2028),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
            Expanded(
              child: Container(
                color: isLight ? Colors.white : const Color(0xFF0F1116),
                child: _showingAnalysis
                    ? const AnalysisViewWidget()
                    : (state.currentMode == StopwatchMode.continuo
                        ? ContinuousTableWidget(
                            scrollController: _scrollController,
                            onMergeRequest: (i) => StopwatchDialogs.promptMerge(context, i, notifier),
                          )
                        : SimpleRecordsListWidget(
                            scrollController: _scrollController,
                            onMergeRequest: (i) => StopwatchDialogs.promptMerge(context, i, notifier),
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
