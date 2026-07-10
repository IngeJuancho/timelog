import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../time_log_controller.dart';
import '../../models.dart';

class ControlButtons extends ConsumerWidget {
  final Animation<double> startButtonAnimation;
  final Animation<double> secondaryButtonAnimation;
  final Animation<double> resetButtonAnimation;
  final Animation<double> exportButtonAnimation;

  final VoidCallback onStartPressed;
  final VoidCallback onSecondaryPressed;
  final VoidCallback onResetPressed;
  final VoidCallback onExportPressed;

  const ControlButtons({
    super.key,
    required this.startButtonAnimation,
    required this.secondaryButtonAnimation,
    required this.resetButtonAnimation,
    required this.exportButtonAnimation,
    required this.onStartPressed,
    required this.onSecondaryPressed,
    required this.onResetPressed,
    required this.onExportPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    
    return Column(
      children: [
        _buildPrimaryButton(context, ref, state),
        const SizedBox(height: 16),
        _buildSecondaryButtons(state),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, WidgetRef ref, dynamic state) {
    String primaryLabel; 
    IconData primaryIcon; 
    Color primaryColor;
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      if (state.isRunning) { 
        primaryLabel = 'Parar'; primaryIcon = Icons.pause_circle_filled; primaryColor = Colors.redAccent; 
      } else { 
        primaryLabel = 'Iniciar'; primaryIcon = Icons.play_circle_fill; primaryColor = Colors.tealAccent; 
      }
    } else {
      if (state.isRunning) { 
        primaryLabel = 'Lap'; primaryIcon = Icons.flag; primaryColor = Colors.indigoAccent; 
      } else { 
        primaryLabel = 'Iniciar'; primaryIcon = Icons.play_circle_fill; primaryColor = Colors.tealAccent; 
      }
    }
    
    final notifier = ref.read(timeLogProvider.notifier);
    
    return Row(
      children: [
        Container(
          width: 88,
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white12,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calificación',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 36,
                    height: 24,
                    child: TextField(
                      controller: notifier.ratingController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (val) => notifier.updateGlobalRating(val),
                    ),
                  ),
                  const SizedBox(width: 1),
                  const Text(
                    '%',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => notifier.applyRatingToCurrentCycle(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'A CICLO',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: startButtonAnimation,
            builder: (context, child) => Transform.scale(
              scale: startButtonAnimation.value,
              child: SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: onStartPressed,
                  icon: Icon(primaryIcon, size: 28),
                  label: Text(primaryLabel.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withValues(alpha: 0.15), 
                    foregroundColor: primaryColor, 
                    elevation: 0, 
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5), 
                    shape: const StadiumBorder()
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButtons(dynamic state) {
    String secondaryLabel = state.currentMode == StopwatchMode.regresoACero ? 'Vuelta' : 'Finalizar';
    IconData secondaryIcon = state.currentMode == StopwatchMode.regresoACero ? Icons.replay : Icons.stop_circle_outlined;
    bool isEnabled = state.isRunning;

    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: secondaryButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: secondaryButtonAnimation.value, 
              child: _buildIconButton(
                icon: secondaryIcon, 
                label: secondaryLabel, 
                onPressed: isEnabled ? onSecondaryPressed : null, 
                color: Colors.orangeAccent
              )
            ),
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: resetButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: resetButtonAnimation.value, 
              child: _buildIconButton(
                icon: Icons.refresh, 
                label: 'Reset', 
                onPressed: onResetPressed, 
                color: Colors.white70
              )
            ),
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: exportButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: exportButtonAnimation.value, 
              child: _buildIconButton(
                icon: Icons.import_export, 
                label: 'Archivos',         
                onPressed: onExportPressed, 
                color: Colors.blueAccent
              )
            ),
          )
        ),
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required String label, required VoidCallback? onPressed, required Color color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF252525), 
        foregroundColor: color, 
        elevation: 0, 
        padding: const EdgeInsets.symmetric(vertical: 16), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Icon(icon, size: 22), 
          const SizedBox(height: 6), 
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
        ]
      ),
    );
  }
}
