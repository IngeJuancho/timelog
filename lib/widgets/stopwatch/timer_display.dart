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
            children: [
              Text(
                state.currentMode == StopwatchMode.regresoACero ? "REGRESO A CERO" : "CONTINUO", 
                style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white38, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  notifier.formatTime(notifier.elapsedMilliseconds.toDouble()), 
                  style: const TextStyle(
                    fontSize: 80, 
                    fontWeight: FontWeight.w300, 
                    color: Colors.white, 
                    fontFeatures: [FontFeature.tabularFigures()], 
                    letterSpacing: -2.0
                  )
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
