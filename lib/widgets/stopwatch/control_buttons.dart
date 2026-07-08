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
          width: 95,
          height: 80,
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: primaryColor.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1)
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CALIFICACIÓN', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              SizedBox(
                height: 28,
                child: TextField(
                  controller: notifier.ratingController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    suffixText: '%',
                    suffixStyle: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (val) => notifier.updateGlobalRating(val),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => notifier.applyRatingToCurrentCycle(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('A CICLO', style: TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              )
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
