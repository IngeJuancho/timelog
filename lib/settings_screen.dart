import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_log_controller.dart';
import 'models.dart';
import 'theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Escuchar cambios de pestaña para redibujar dinámicamente y adaptar la altura
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCardGroup({
    required BuildContext context,
    required String sectionTitle,
    required IconData sectionIcon,
    required Color sectionColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(sectionIcon, size: 14, color: sectionColor),
              const SizedBox(width: 6),
              Text(
                sectionTitle.toUpperCase(),
                style: TextStyle(
                  color: sectionColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _buildDropdownTile<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.skyPrecision.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTheme.skyPrecision),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.amoledSurfaceContainerHighest : AppTheme.lightSurfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useHaptic = ref.watch(timeLogProvider.select((s) => s.useHapticFeedback));
    final hapticLvl = ref.watch(timeLogProvider.select((s) => s.hapticLevel));
    final usePhysical = ref.watch(timeLogProvider.select((s) => s.usePhysicalButtons));
    final recOnPauseRAC = ref.watch(timeLogProvider.select((s) => s.recordOnPauseRAC));
    final recOnPauseCont = ref.watch(timeLogProvider.select((s) => s.recordOnPauseCont));
    final tFormat = ref.watch(timeLogProvider.select((s) => s.timeFormat));
    
    final vUpRAC = ref.watch(timeLogProvider.select((s) => s.volUpActionRAC));
    final vDownRAC = ref.watch(timeLogProvider.select((s) => s.volDownActionRAC));
    final vUpCont = ref.watch(timeLogProvider.select((s) => s.volUpActionCont));
    final vDownCont = ref.watch(timeLogProvider.select((s) => s.volDownActionCont));
    final isAmoled = ref.watch(timeLogProvider.select((s) => s.isAmoledMode));
    final undoTimeout = ref.watch(timeLogProvider.select((s) => s.undoTimeoutSeconds));

    final controller = ref.read(timeLogProvider.notifier);
    final theme = Theme.of(context);
    final tealColor = AppTheme.getTealAccent(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. APARIENCIA
          _buildCardGroup(
            context: context,
            sectionTitle: "Apariencia y Pantalla",
            sectionIcon: Icons.palette_outlined,
            sectionColor: tealColor,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                activeTrackColor: tealColor.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(tealColor),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tealColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAmoled ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: tealColor,
                    size: 20,
                  ),
                ),
                title: const Text('Modo Oscuro AMOLED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isAmoled ? 'Negro puro (#000000) optimizado para pantallas OLED.' : 'Interfaz clara con fondo slate de alta legibilidad.',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
                value: isAmoled,
                onChanged: (v) => controller.updateSetting(isAmoledMode: v),
              ),
            ],
          ),

          // 2. MEDICIÓN Y REGISTRO
          _buildCardGroup(
            context: context,
            sectionTitle: "Medición y Registro",
            sectionIcon: Icons.timer_outlined,
            sectionColor: AppTheme.skyPrecision,
            children: [
              _buildDropdownTile<TimeFormat>(
                context: context,
                icon: Icons.access_time_rounded,
                title: 'Unidad de Medida',
                subtitle: 'Formato de visualización y exportación.',
                value: tFormat,
                items: const [
                  DropdownMenuItem(value: TimeFormat.standard, child: Text('Estándar (mm:ss.cc)')),
                  DropdownMenuItem(value: TimeFormat.seconds, child: Text('Segundos (s)')),
                  DropdownMenuItem(value: TimeFormat.minutes, child: Text('Minutos (min)')),
                ],
                onChanged: (v) {
                  if (v != null) controller.updateSetting(timeFormat: v);
                },
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
              _buildDropdownTile<int>(
                context: context,
                icon: Icons.undo_rounded,
                title: 'Tiempo de Botón Deshacer',
                subtitle: 'Permanencia del botón flotante para revertir tomas.',
                value: [2, 3, 4, 5, 7, 10].contains(undoTimeout) ? undoTimeout : 4,
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2 seg')),
                  DropdownMenuItem(value: 3, child: Text('3 seg')),
                  DropdownMenuItem(value: 4, child: Text('4 seg')),
                  DropdownMenuItem(value: 5, child: Text('5 seg')),
                  DropdownMenuItem(value: 7, child: Text('7 seg')),
                  DropdownMenuItem(value: 10, child: Text('10 seg')),
                ],
                onChanged: (v) {
                  if (v != null) controller.updateSetting(undoTimeoutSeconds: v);
                },
              ),
            ],
          ),

          // 3. RESPUESTA TÁCTIL (FEEDBACK)
          _buildCardGroup(
            context: context,
            sectionTitle: "Feedback Háptico",
            sectionIcon: Icons.vibration_rounded,
            sectionColor: AppTheme.amberIndustrial,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                activeTrackColor: tealColor.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(tealColor),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.amberIndustrial.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vibration_rounded, color: AppTheme.amberIndustrial, size: 20),
                ),
                title: const Text('Vibración Háptica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Confirmación física en dedos al presionar disparadores.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                value: useHaptic,
                onChanged: (v) => controller.updateSetting(useHapticFeedback: v),
              ),
              if (useHaptic) ...[
                Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor),
                _buildDropdownTile<HapticLevel>(
                  context: context,
                  title: 'Intensidad de Vibración',
                  subtitle: 'Nivel de respuesta táctil.',
                  value: hapticLvl,
                  items: HapticLevel.values.map((e) {
                    String label;
                    switch (e) {
                      case HapticLevel.light: label = 'Suave (Light)'; break;
                      case HapticLevel.medium: label = 'Medio (Medium)'; break;
                      case HapticLevel.heavy: label = 'Fuerte (Heavy)'; break;
                    }
                    return DropdownMenuItem(value: e, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) controller.updateSetting(hapticLevel: v);
                  },
                ),
              ],
            ],
          ),

          // 4. HARDWARE Y BOTONES FÍSICOS
          _buildCardGroup(
            context: context,
            sectionTitle: "Botones Físicos de Hardware",
            sectionIcon: Icons.volume_up_outlined,
            sectionColor: tealColor,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                activeTrackColor: tealColor.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(tealColor),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tealColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.volume_up_rounded, color: tealColor, size: 20),
                ),
                title: const Text('Botones de Volumen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Usa las teclas físicas del dispositivo como disparador.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                value: usePhysical,
                onChanged: (v) => controller.updateSetting(usePhysicalButtons: v),
              ),
              if (usePhysical) ...[
                Divider(height: 1, color: theme.dividerColor),
                TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicatorColor: tealColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: tealColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelColor: theme.textTheme.bodySmall?.color,
                  dividerColor: theme.dividerColor,
                  tabs: const [
                    Tab(text: "Por Ciclo"),
                    Tab(text: "Por Elemento"),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: _tabController.index == 0
                      ? _buildButtonConfigPage(
                          l1: "Botón Subir Volumen (+)",
                          v1: vUpRAC,
                          c1: (v) { controller.updateSetting(volUpActionRAC: v!); },
                          l2: "Botón Bajar Volumen (-)",
                          v2: vDownRAC,
                          c2: (v) { controller.updateSetting(volDownActionRAC: v!); },
                          recOnPause: recOnPauseRAC,
                          onRecOnPauseChanged: (v) { controller.updateSetting(recordOnPauseRAC: v); },
                          recSubtitle: "Registra el ciclo automáticamente al pausar con el botón físico.",
                        )
                      : _buildButtonConfigPage(
                          l1: "Botón Subir Volumen (+)",
                          v1: vUpCont,
                          c1: (v) { controller.updateSetting(volUpActionCont: v!); },
                          l2: "Botón Bajar Volumen (-)",
                          v2: vDownCont,
                          c2: (v) { controller.updateSetting(volDownActionCont: v!); },
                          recOnPause: recOnPauseCont,
                          onRecOnPauseChanged: (v) { controller.updateSetting(recordOnPauseCont: v); },
                          recSubtitle: "Registra el elemento automáticamente al pausar con el botón físico.",
                        ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtonConfigPage({
    required String l1,
    required PhysicalButtonAction v1,
    required ValueChanged<PhysicalButtonAction?> c1,
    required String l2,
    required PhysicalButtonAction v2,
    required ValueChanged<PhysicalButtonAction?> c2,
    required bool recOnPause,
    required ValueChanged<bool> onRecOnPauseChanged,
    required String recSubtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealColor = AppTheme.getTealAccent(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l1,
            style: TextStyle(
              color: tealColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.amoledSurfaceContainerHighest : AppTheme.lightSurfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PhysicalButtonAction>(
                isExpanded: true,
                value: v1,
                items: _getActionItems(),
                onChanged: c1,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l2,
            style: const TextStyle(
              color: AppTheme.skyPrecision,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.amoledSurfaceContainerHighest : AppTheme.lightSurfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PhysicalButtonAction>(
                isExpanded: true,
                value: v2,
                items: _getActionItems(),
                onChanged: c2,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: theme.dividerColor, height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: tealColor.withValues(alpha: 0.5),
            thumbColor: WidgetStatePropertyAll(tealColor),
            title: const Text('¿Registrar al pausar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text(
              recSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
            ),
            value: recOnPause,
            onChanged: onRecOnPauseChanged,
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<PhysicalButtonAction>> _getActionItems() {
    return PhysicalButtonAction.values.map((e) {
      String text;
      switch (e) {
        case PhysicalButtonAction.none: text = 'Ninguna acción'; break;
        case PhysicalButtonAction.startStop: text = 'Iniciar / Pausar cronómetro'; break;
        case PhysicalButtonAction.lapSnapback: text = 'Vuelta / Vuelta a cero (Lap)'; break;
        case PhysicalButtonAction.stopAndRecord: text = 'Detener y Registrar tiempo'; break;
        case PhysicalButtonAction.reset: text = 'Reiniciar todo (Reset)'; break;
      }
      return DropdownMenuItem(
        value: e,
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      );
    }).toList();
  }
}
