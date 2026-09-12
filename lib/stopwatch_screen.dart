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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToIndex(int index, bool isContinuous) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        double estimatedItemHeight = isContinuous ? 48.0 : 72.0;
        double headerOffset = isContinuous ? 56.0 : 0.0;

        double targetItemOffset = (index * estimatedItemHeight) + headerOffset;
        double currentOffset = _scrollController.offset;
        double viewportHeight = _scrollController.position.viewportDimension;

        if (targetItemOffset < currentOffset ||
            targetItemOffset > currentOffset + viewportHeight - estimatedItemHeight) {
          double targetScroll = targetItemOffset - (viewportHeight / 2) + (estimatedItemHeight / 2);

          if (targetScroll < 0) targetScroll = 0;
          if (targetScroll > _scrollController.position.maxScrollExtent) {
            targetScroll = _scrollController.position.maxScrollExtent;
          }

          _scrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
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

    ref.listen<int>(
      timeLogProvider.select((s) => s.activeRecordedTimes.length),
      (previous, next) {
        final state = ref.read(timeLogProvider);
        if (previous != null && next > previous && !_showingAnalysis) {
          if (state.activeTemplate == null) {
            _scrollToBottom();
          } else {
            _scrollToIndex(state.currentTemplateStepIndex, state.currentMode == StopwatchMode.continuo);
          }
        }
      },
    );

    ref.listen<int>(
      timeLogProvider.select((s) => s.currentTemplateStepIndex),
      (previous, next) {
        final state = ref.read(timeLogProvider);
        if (previous != null && next != previous && !_showingAnalysis && state.activeTemplate != null) {
          _scrollToIndex(next, state.currentMode == StopwatchMode.continuo);
        }
      },
    );

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                children: [
                  TimerDisplay(pulseAnimation: _pulseAnimation),
                  const SizedBox(height: 24),
                  TaskNameInput(
                    focusNode: _taskNameFocusNode,
                    state: state,
                    notifier: notifier,
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
    final tealColor = AppTheme.getTealAccent(context);
    return AnimatedBuilder(
      animation: _viewChangeAnimation,
      builder: (_, __) => Card(
        color: Theme.of(context).cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_showingAnalysis ? Icons.pie_chart_outline : Icons.list_alt, color: tealColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _showingAnalysis ? 'ESTADÍSTICAS' : 'REGISTROS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!_showingAnalysis && state.currentMode == StopwatchMode.continuo) ...[
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => StopwatchDialogs.promptSaveCurrentTemplate(context, state, notifier),
                            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                            tooltip: 'Guardar como Ruta Estándar',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.amber.withValues(alpha: 0.2),
                              foregroundColor: Colors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: _toggleView,
                          icon: Icon(_showingAnalysis ? Icons.list : Icons.analytics, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).dividerColor,
                            foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
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
