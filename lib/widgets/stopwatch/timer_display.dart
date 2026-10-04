import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../time_log_controller.dart';
import '../../models.dart';

class TimerDisplay extends ConsumerWidget {
  final Animation<double> pulseAnimation;

  const TimerDisplay({
    super.key,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: state.isRunning ? pulseAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  state.currentMode == StopwatchMode.regresoACero ? "POR CICLO" : "POR ELEMENTO",
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  notifier.formatTime(notifier.elapsedMilliseconds.toDouble()),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
