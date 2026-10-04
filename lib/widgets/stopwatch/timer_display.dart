import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../time_log_controller.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.isRunning
                    ? Colors.greenAccent.withValues(alpha: 0.4)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
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
                          color: Colors.greenAccent.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  state.currentMode == StopwatchMode.regresoACero ? "POR CICLO" : "POR ELEMENTO",
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
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
