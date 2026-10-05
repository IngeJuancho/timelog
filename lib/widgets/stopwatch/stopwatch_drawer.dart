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
          // Header estilo Perfil de Estudio Frosted/M3
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getTealAccent(context).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.getTealAccent(context).withValues(alpha: 0.4), width: 1),
                          ),
                          child: Icon(Icons.timer_outlined, color: AppTheme.getTealAccent(context), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'TimeLog',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    if (updateInfo != null && updateInfo.isUpdateAvailable)
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
                                'v${updateInfo.latestVersion}',
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  "ESTUDIO EN CURSO",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.getTealAccent(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.masterStudyName.isNotEmpty ? state.masterStudyName : 'Estudio Libre (Sin guardar)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildHeaderBadge(
                      context,
                      Icons.repeat,
                      state.currentMode == StopwatchMode.regresoACero ? "Por Ciclo" : "Por Elemento",
                    ),
                    _buildHeaderBadge(
                      context,
                      Icons.format_list_numbered_rounded,
                      "${state.activeRecordedTimes.where((e) => e['status'] != 'pending').length} registros",
                    ),
                    _buildHeaderBadge(
                      context,
                      Icons.pie_chart_outline,
                      "PF&D ${state.pfd.percentageText}",
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              "MODO DE CRONOMETRAJE",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),
          _buildDrawerOption(context, 'Por Ciclo', 'Clásico. Reinicia al registrar.', Icons.replay, StopwatchMode.regresoACero, state, notifier),
          _buildDrawerOption(context, 'Por Elemento', 'Acumulativo. Calcula tiempo individual.', Icons.timeline, StopwatchMode.continuo, state, notifier),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), indent: 20, endIndent: 20, height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "GESTIÓN DE DATOS",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.save_outlined,
            title: 'Guardar Estudio',
            iconColor: Colors.tealAccent.shade700,
            onTap: () {
              Navigator.pop(context);
              onSaveStudyRequested();
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history,
            title: 'Historial de Estudios',
            iconColor: Colors.blueAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudiesHistoryScreen()));
            },
          ),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), indent: 20, endIndent: 20, height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              "HERRAMIENTAS",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.route_outlined,
            title: 'Gestor de Plantillas',
            iconColor: Colors.purpleAccent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateManagerScreen()));
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.calculate_outlined,
            title: 'Calculadora Muestra',
            iconColor: Colors.amberAccent.shade700,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SampleCalculatorScreen()));
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Configuración',
            iconColor: Colors.grey,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.getTealAccent(context)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? tealFill : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            notifier.setMode(mode);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? tealColor.withValues(alpha: 0.6)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.25),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tealColor.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? tealColor : Theme.of(context).iconTheme.color?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? tealColor : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? tealColor.withValues(alpha: 0.85)
                              : Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isSelected ? tealColor : Theme.of(context).disabledColor.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: effectiveIconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
