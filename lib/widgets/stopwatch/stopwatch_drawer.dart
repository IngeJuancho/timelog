import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../time_log_controller.dart';
import '../../time_log_state.dart';
import '../../update_service.dart';
import '../../studies_history_screen.dart';
import '../../template_manager_screen.dart';
import '../../calculator_screen.dart';
import '../../settings_screen.dart';

class StopwatchDrawer extends ConsumerWidget {
  final VoidCallback onSaveStudyRequested;

  const StopwatchDrawer({
    super.key,
    required this.onSaveStudyRequested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    final updateInfo = ref.watch(updateProvider).value;

    return Drawer(
      backgroundColor: Theme.of(context).drawerTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 160,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade800, Theme.of(context).colorScheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.timer, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('TimeLog', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (updateInfo != null && updateInfo.isUpdateAvailable) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse(updateInfo.releaseUrl), mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.orangeAccent, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.system_update_alt, color: Colors.orangeAccent, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '¡Actualización ${updateInfo.latestVersion}!',
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            child: Text(
              "MODO",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _buildDrawerOption(context, 'Por Ciclo', 'Clásico. Reinicia al registrar.', Icons.replay, StopwatchMode.regresoACero, state, notifier),
          _buildDrawerOption(context, 'Por Elemento', 'Acumulativo. Calcula TO.', Icons.timeline, StopwatchMode.continuo, state, notifier),
          Divider(color: Theme.of(context).dividerColor, indent: 24, endIndent: 24, height: 40),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(
              "DATOS",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.save_outlined, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
            title: Text('Guardar Estudio', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            onTap: () {
              Navigator.pop(context);
              onSaveStudyRequested();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.history, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
            title: Text('Historial', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudiesHistoryScreen()));
            },
          ),
          Divider(color: Theme.of(context).dividerColor, indent: 24, endIndent: 24, height: 40),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(
              "UTILIDADES",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.route, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
            title: Text('Rutas Estándar', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateManagerScreen()));
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.calculate_outlined, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
            title: Text('Calculadora Muestra', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SampleCalculatorScreen()));
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
            title: Text('Configuración', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    StopwatchMode mode,
    TimeLogState state,
    TimeLogNotifier notifier,
  ) {
    bool isSelected = state.currentMode == mode;
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? tealColor : Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? tealColor : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? tealColor.withValues(alpha: 0.7) : Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
        tileColor: isSelected ? tealFill : null,
        onTap: () {
          notifier.setMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }
}
