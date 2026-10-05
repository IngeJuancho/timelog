import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../time_log_controller.dart';
import '../../models.dart';
import '../../theme.dart';

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
        const SizedBox(height: 10),
        _buildSecondaryButtons(context, state),
      ]);
  }

  Widget _buildPrimaryButton(BuildContext context, WidgetRef ref, dynamic state) {
    String primaryLabel; 
    IconData primaryIcon; 
    Color primaryColor;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tealColor = AppTheme.getTealAccent(context);
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      if (state.isRunning) { 
        primaryLabel = 'Parar'; primaryIcon = Icons.pause_circle_filled; primaryColor = Colors.redAccent; 
      } else { 
        primaryLabel = 'Iniciar'; primaryIcon = Icons.play_circle_fill; primaryColor = tealColor; 
      }
    } else {
      if (state.isRunning) { 
        primaryLabel = 'Lap'; primaryIcon = Icons.flag; primaryColor = isLight ? const Color(0xFF303F9F) : Colors.indigoAccent; 
      } else { 
        primaryLabel = 'Iniciar'; primaryIcon = Icons.play_circle_fill; primaryColor = tealColor; 
      }
    }
    
    return AnimatedBuilder(
      animation: startButtonAnimation,
      builder: (context, child) => Transform.scale(
        scale: startButtonAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: state.isRunning
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: isLight ? 0.35 : 0.45),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onStartPressed,
              icon: Icon(primaryIcon, size: 24),
              label: Text(
                primaryLabel.toUpperCase(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withValues(alpha: isLight ? 0.22 : 0.18),
                foregroundColor: primaryColor,
                elevation: 0,
                side: BorderSide(
                  color: primaryColor.withValues(alpha: state.isRunning ? 0.9 : (isLight ? 0.7 : 0.45)),
                  width: state.isRunning ? 2.0 : 1.5,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons(BuildContext context, dynamic state) {
    String secondaryLabel = state.currentMode == StopwatchMode.regresoACero ? 'Vuelta' : 'Finalizar';
    IconData secondaryIcon = state.currentMode == StopwatchMode.regresoACero ? Icons.replay : Icons.stop_circle_outlined;
    bool isEnabled = state.isRunning;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: AnimatedBuilder(
            animation: secondaryButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: secondaryButtonAnimation.value,
              child: _buildM3CardButton(
                context: context,
                icon: secondaryIcon,
                label: secondaryLabel,
                onPressed: isEnabled ? onSecondaryPressed : null,
                color: isEnabled ? Colors.orangeAccent : Theme.of(context).disabledColor,
                backgroundColor: isEnabled
                    ? Colors.orangeAccent.withValues(alpha: isLight ? 0.16 : 0.12)
                    : Theme.of(context).cardColor.withValues(alpha: 0.5),
                borderColor: isEnabled
                    ? Colors.orangeAccent.withValues(alpha: 0.6)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: AnimatedBuilder(
            animation: resetButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: resetButtonAnimation.value,
              child: _buildM3CardButton(
                context: context,
                icon: Icons.restart_alt,
                label: 'Reset',
                onPressed: onResetPressed,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8) ?? Colors.grey,
                backgroundColor: Theme.of(context).cardColor,
                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: AnimatedBuilder(
            animation: exportButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: exportButtonAnimation.value,
              child: _buildM3CardButton(
                context: context,
                icon: Icons.folder_open_outlined,
                label: 'Archivos',
                onPressed: onExportPressed,
                color: Colors.blueAccent,
                backgroundColor: Colors.blueAccent.withValues(alpha: isLight ? 0.10 : 0.08),
                borderColor: Colors.blueAccent.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildM3CardButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
