import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_log_controller.dart';
import 'models.dart';

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

  @override
  Widget build(BuildContext context) {
    final useHaptic = ref.watch(timeLogProvider.select((s) => s.useHapticFeedback));
    final hapticLvl = ref.watch(timeLogProvider.select((s) => s.hapticLevel));
    final usePhysical = ref.watch(timeLogProvider.select((s) => s.usePhysicalButtons));
    final recOnPause = ref.watch(timeLogProvider.select((s) => s.recordOnPause));
    final tFormat = ref.watch(timeLogProvider.select((s) => s.timeFormat));
    
    final vUpRAC = ref.watch(timeLogProvider.select((s) => s.volUpActionRAC));
    final vDownRAC = ref.watch(timeLogProvider.select((s) => s.volDownActionRAC));
    final vUpCont = ref.watch(timeLogProvider.select((s) => s.volUpActionCont));
    final vDownCont = ref.watch(timeLogProvider.select((s) => s.volDownActionCont));
    final isAmoled = ref.watch(timeLogProvider.select((s) => s.isAmoledMode));

    final controller = ref.read(timeLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), backgroundColor: Colors.transparent, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          _buildSectionHeader("Personalización", Theme.of(context).colorScheme.primary),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            title: const Text('Modo Oscuro AMOLED', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Optimizado para pantallas OLED.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 12)),
            value: isAmoled,
            onChanged: (v) {
              controller.updateSetting(isAmoledMode: v);
            }
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("Visualización", Theme.of(context).colorScheme.primary),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unidad de Medida', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Formato en el que se muestran y exportan los tiempos.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54), fontSize: 12)),
            trailing: DropdownButton<TimeFormat>(
              value: tFormat,
              
              underline: Container(),
              items: const [
                DropdownMenuItem(value: TimeFormat.standard, child: Text('Estándar (mm:ss.cc)', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: TimeFormat.seconds, child: Text('Segundos (s)', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: TimeFormat.minutes, child: Text('Minutos (min)', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (v) {
                if (v != null) {
                  controller.updateSetting(timeFormat: v);
                }
              },
            ),
          ),
          
          const SizedBox(height: 20),
          _buildSectionHeader("Feedback", Theme.of(context).colorScheme.primary),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: Theme.of(context).colorScheme.primary, title: const Text('Vibración Háptica', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Confirmación táctil al registrar.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54), fontSize: 12)), value: useHaptic, onChanged: (v) { controller.updateSetting(useHapticFeedback: v); }),
          if (useHaptic) Padding(padding: const EdgeInsets.only(left: 10, bottom: 20), child: Row(children: [Text("Intensidad:", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54))), const SizedBox(width: 15), DropdownButton<HapticLevel>(value: hapticLvl,  underline: Container(), items: HapticLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { controller.updateSetting(hapticLevel: v!); })])),
          
          const SizedBox(height: 20),
          _buildSectionHeader("Hardware", Theme.of(context).colorScheme.primary),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: Theme.of(context).colorScheme.primary, title: const Text('Botones de Volumen', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Usar botones físicos para controlar.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54), fontSize: 12)), value: usePhysical, onChanged: (v) { controller.updateSetting(usePhysicalButtons: v); }),
          
          if (usePhysical) ...[
            SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: Theme.of(context).colorScheme.primary, title: const Text('¿Registrar al pausar?', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Registra el tiempo automáticamente al pausar con el botón físico.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54), fontSize: 12)), value: recOnPause, onChanged: (v) { controller.updateSetting(recordOnPause: v); }),
            const SizedBox(height: 20),
            // SOLUCIÓN BUG: Eliminada la altura fija de 350. 
            // Ahora usamos AnimatedSize y mostramos condicionalmente las páginas.
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min, // El contenedor tomará solo el alto necesario
                children: [
                  TabBar(
                    controller: _tabController, 
                    indicatorColor: Theme.of(context).colorScheme.primary, 
                    labelColor: Theme.of(context).colorScheme.primary, 
                    unselectedLabelColor: Colors.white38, 
                    tabs: const [Tab(text: "Por Ciclo"), Tab(text: "Por Elemento")]
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: _tabController.index == 0
                        ? _buildButtonConfigPage("Botón Subir", vUpRAC, (v) { controller.updateSetting(volUpActionRAC: v!); }, "Botón Bajar", vDownRAC, (v) { controller.updateSetting(volDownActionRAC: v!); })
                        : _buildButtonConfigPage("Botón Subir", vUpCont, (v) { controller.updateSetting(volUpActionCont: v!); }, "Botón Bajar", vDownCont, (v) { controller.updateSetting(volDownActionCont: v!); }),
                  )
                ]
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)));
  }

  Widget _buildButtonConfigPage(String l1, PhysicalButtonAction v1, ValueChanged<PhysicalButtonAction?> c1, String l2, PhysicalButtonAction v2, ValueChanged<PhysicalButtonAction?> c2) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l1, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54), fontSize: 12)),
      DropdownButton<PhysicalButtonAction>(isExpanded: true, value: v1,  underline: Container(height: 1, color: Theme.of(context).dividerColor), items: _getActionItems(), onChanged: c1),
      const SizedBox(height: 20),
      Text(l2, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54), fontSize: 12)),
      DropdownButton<PhysicalButtonAction>(isExpanded: true, value: v2,  underline: Container(height: 1, color: Theme.of(context).dividerColor), items: _getActionItems(), onChanged: c2),
    ]));
  }

  List<DropdownMenuItem<PhysicalButtonAction>> _getActionItems() {
    return PhysicalButtonAction.values.map((e) {
      String text;
      switch (e) {
        case PhysicalButtonAction.none: text = 'Ninguna'; break;
        case PhysicalButtonAction.startStop: text = 'Iniciar / Pausar'; break;
        case PhysicalButtonAction.lapSnapback: text = 'Vuelta / Lap'; break;
        case PhysicalButtonAction.stopAndRecord: text = 'Parar y Registrar'; break;
        case PhysicalButtonAction.reset: text = 'Reiniciar Todo'; break;
      }
      return DropdownMenuItem(value: e, child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)));
    }).toList();
  }
}
