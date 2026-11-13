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
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, WidgetRef ref, dynamic state) {
    String primaryLabel; 
    IconData primaryIcon; 
    Color primaryColor;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final emerald = AppTheme.getTealAccent(context);
    
    if (state.currentMode == StopwatchMode.regresoACero) {
      if (state.isRunning) { 
        primaryLabel = 'Parar'; 
        primaryIcon = Icons.stop_rounded; 
        primaryColor = AppTheme.crimsonOutlier; 
      } else { 
        primaryLabel = 'Iniciar'; 
        primaryIcon = Icons.play_arrow_rounded; 
        primaryColor = emerald; 
      }
    } else {
      if (state.isRunning) { 
        primaryLabel = 'Lap / Registrar'; 
        primaryIcon = Icons.add_circle_outline_rounded; 
        primaryColor = isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision; 
      } else { 
        primaryLabel = 'Iniciar'; 
        primaryIcon = Icons.play_arrow_rounded; 
        primaryColor = emerald; 
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
                      color: primaryColor.withValues(alpha: isLight ? 0.35 : 0.40),
                      blurRadius: 18,
                      spreadRadius: 1.5,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: emerald.withValues(alpha: isLight ? 0.20 : 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: onStartPressed,
              icon: Icon(primaryIcon, size: 26),
              label: Text(
                primaryLabel.toUpperCase(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withValues(alpha: isLight ? 0.22 : 0.16),
                foregroundColor: primaryColor,
                elevation: 0,
                side: BorderSide(
                  color: primaryColor.withValues(alpha: state.isRunning ? 0.95 : (isLight ? 0.8 : 0.6)),
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
    IconData secondaryIcon = state.currentMode == StopwatchMode.regresoACero ? Icons.replay_rounded : Icons.stop_circle_rounded;
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
                color: isEnabled ? AppTheme.amberIndustrial : Theme.of(context).disabledColor,
                backgroundColor: isEnabled
                    ? AppTheme.amberIndustrial.withValues(alpha: isLight ? 0.16 : 0.12)
                    : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF14171E)),
                borderColor: isEnabled
                    ? AppTheme.amberIndustrial.withValues(alpha: 0.65)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: AnimatedBuilder(
            animation: resetButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: resetButtonAnimation.value,
              child: _buildM3CardButton(
                context: context,
                icon: Icons.restart_alt_rounded,
                label: 'Reset',
                onPressed: onResetPressed,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85) ?? Colors.grey,
                backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF14171E),
                borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: AnimatedBuilder(
            animation: exportButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: exportButtonAnimation.value,
              child: _buildM3CardButton(
                context: context,
                icon: Icons.folder_open_rounded,
                label: 'Archivos',
                onPressed: onExportPressed,
                color: isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision,
                backgroundColor: (isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision).withValues(alpha: isLight ? 0.12 : 0.09),
                borderColor: (isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision).withValues(alpha: 0.4),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
