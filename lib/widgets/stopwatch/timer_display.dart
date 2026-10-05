import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../time_log_controller.dart';
import 'pfd_selector_sheet.dart';

class TimerDisplay extends ConsumerStatefulWidget {
  final Animation<double> pulseAnimation;

  const TimerDisplay({
    super.key,
    required this.pulseAnimation,
  });

  @override
  ConsumerState<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends ConsumerState<TimerDisplay> with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncTicker(ref.read(timeLogProvider).isRunning);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _syncTicker(bool isRunning) {
    if (isRunning) {
      if (!_ticker.isTicking) {
        _ticker.start();
      }
    } else {
      if (_ticker.isTicking) {
        _ticker.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(timeLogProvider.select((s) => s.isRunning), (_, isRunning) {
      _syncTicker(isRunning);
    });

    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    _syncTicker(state.isRunning);

    final currentMs = notifier.elapsedMilliseconds.toDouble();
    final fullTime = notifier.formatTime(currentMs);

    String mainPart = fullTime;
    String decimalPart = '';
    int dotIndex = fullTime.indexOf('.');
    if (dotIndex != -1) {
      mainPart = fullTime.substring(0, dotIndex);
      decimalPart = fullTime.substring(dotIndex);
    }
    
    return Transform.scale(
      scale: state.isRunning ? widget.pulseAnimation.value : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.isRunning
                    ? Colors.greenAccent.withValues(alpha: 0.45)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    onTap: () {
                      final newMode = state.currentMode == StopwatchMode.regresoACero
                          ? StopwatchMode.continuo
                          : StopwatchMode.regresoACero;
                      notifier.setMode(newMode);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.isRunning) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(alpha: 0.9),
                                    blurRadius: 7,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                          ] else ...[
                            Icon(
                              state.currentMode == StopwatchMode.regresoACero ? Icons.replay : Icons.timeline,
                              size: 13,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            state.currentMode == StopwatchMode.regresoACero ? "POR CICLO" : "POR ELEMENTO",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    onTap: () {
                      PfdSelectorSheet.show(
                        context,
                        selectedCategory: state.pfd,
                        onCategorySelected: (cat) => notifier.setPfdCategory(cat),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 13,
                            color: AppTheme.getTealAccent(context),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "PF&D: ${state.pfd.percentageText}",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              color: AppTheme.getTealAccent(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: mainPart,
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -1.0,
                    ),
                  ),
                  if (decimalPart.isNotEmpty)
                    TextSpan(
                      text: decimalPart,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.65),
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: -0.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
