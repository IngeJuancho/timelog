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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryAccent = AppTheme.getTealAccent(context);

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
          // --- CÁPSULA INSTRUMENTAL DE CONTROL ---
          Container(
            decoration: BoxDecoration(
              color: isLight 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: state.isRunning
                    ? primaryAccent.withValues(alpha: isLight ? 0.6 : 0.5)
                    : Theme.of(context).dividerColor.withValues(alpha: isLight ? 0.8 : 0.4),
                width: 1.2,
              ),
              boxShadow: state.isRunning
                  ? [
                      BoxShadow(
                        color: primaryAccent.withValues(alpha: isLight ? 0.15 : 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de Estado y Modo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isRunning) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryAccent,
                            boxShadow: [
                              BoxShadow(
                                color: primaryAccent.withValues(alpha: 0.9),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        Icon(
                          state.currentMode == StopwatchMode.regresoACero ? Icons.replay_rounded : Icons.timeline_rounded,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        state.currentMode == StopwatchMode.regresoACero ? "REGRESO A CERO" : "CONTINUO",
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.1,
                          color: state.isRunning
                              ? primaryAccent
                              : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Separador vertical
                Container(
                  width: 1,
                  height: 16,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),

                // Botón selector de Suplementos PF&D
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
                    onTap: () {
                      PfdSelectorSheet.show(
                        context,
                        selectedCategory: state.pfd,
                        onCategorySelected: (cat) => notifier.setPfdCategory(cat),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 13,
                            color: isLight ? AppTheme.emeraldDark : AppTheme.skyPrecision,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "PF&D: ${state.pfd.percentageText}",
                            style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              color: isLight ? AppTheme.emeraldDark : AppTheme.skyPrecision,
                              fontWeight: FontWeight.w700,
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
          
          const SizedBox(height: 8),

          // --- DÍGITOS CRONOGRÁFICOS DE ALTA PRECISIÓN ---
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: mainPart,
                    style: TextStyle(
                      fontSize: 58,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -1.0,
                      shadows: state.isRunning
                          ? [
                              Shadow(
                                color: primaryAccent.withValues(alpha: isLight ? 0.2 : 0.35),
                                blurRadius: 18,
                              )
                            ]
                          : null,
                    ),
                  ),
                  if (decimalPart.isNotEmpty)
                    TextSpan(
                      text: decimalPart,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w500,
                        color: state.isRunning
                            ? primaryAccent
                            : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
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
