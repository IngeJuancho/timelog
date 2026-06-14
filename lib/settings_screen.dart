// lib/settings_screen.dart
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timeLogProvider);
    
    bool hasStartStop = state.volUpActionRAC == PhysicalButtonAction.startStop ||
                        state.volDownActionRAC == PhysicalButtonAction.startStop ||
                        state.volUpActionCont == PhysicalButtonAction.startStop ||
                        state.volDownActionCont == PhysicalButtonAction.startStop;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), backgroundColor: Colors.transparent, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("Visualización"),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unidad de Medida', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Formato en el que se muestran y exportan los tiempos.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: DropdownButton<TimeFormat>(
              value: state.timeFormat,
              dropdownColor: const Color(0xFF2C2C2C),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: TimeFormat.standard, child: Text('Estándar (mm:ss.cc)', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: TimeFormat.seconds, child: Text('Segundos (s)', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: TimeFormat.minutes, child: Text('Minutos (min)', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (v) {
                if (v != null) {
                  state.timeFormat = v;
                  state.saveSettings();
                }
              },
            ),
          ),
          
          const SizedBox(height: 20),
          _buildSectionHeader("Feedback"),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: Colors.tealAccent, title: const Text('Vibración Háptica', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Confirmación táctil al registrar.', style: TextStyle(color: Colors.white54, fontSize: 12)), value: state.useHapticFeedback, onChanged: (v) { state.useHapticFeedback = v; state.saveSettings(); }),
          if (state.useHapticFeedback) Padding(padding: const EdgeInsets.only(left: 10, bottom: 20), child: Row(children: [const Text("Intensidad:", style: TextStyle(color: Colors.white54)), const SizedBox(width: 15), DropdownButton<HapticLevel>(value: state.hapticLevel, dropdownColor: const Color(0xFF2C2C2C), underline: Container(), items: HapticLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { state.hapticLevel = v!; state.saveSettings(); })])),
          
          const SizedBox(height: 20),
          _buildSectionHeader("Hardware"),
          SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: Colors.tealAccent, title: const Text('Botones de Volumen', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Usar botones físicos para controlar.', style: TextStyle(color: Colors.white54, fontSize: 12)), value: state.usePhysicalButtons, onChanged: (v) { state.usePhysicalButtons = v; state.saveSettings(); }),
          
          if (state.usePhysicalButtons && hasStartStop)
            SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: Colors.tealAccent, title: const Text('¿Registrar al pausar?', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Registra el tiempo automáticamente al pausar con el botón físico.', style: TextStyle(color: Colors.white54, fontSize: 12)), value: state.recordOnPause, onChanged: (v) { state.recordOnPause = v; state.saveSettings(); }),

          if (state.usePhysicalButtons) ...[
            const SizedBox(height: 20),
            Container(
              height: 350,
              decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                TabBar(controller: _tabController, indicatorColor: Colors.tealAccent, labelColor: Colors.tealAccent, unselectedLabelColor: Colors.white38, tabs: const [Tab(text: "Regreso a Cero"), Tab(text: "Continuo")]),
                Expanded(child: TabBarView(controller: _tabController, children: [
                  _buildButtonConfigPage("Botón Subir", state.volUpActionRAC, (v) { state.volUpActionRAC = v!; state.saveSettings(); }, "Botón Bajar", state.volDownActionRAC, (v) { state.volDownActionRAC = v!; state.saveSettings(); }),
                  _buildButtonConfigPage("Botón Subir", state.volUpActionCont, (v) { state.volUpActionCont = v!; state.saveSettings(); }, "Botón Bajar", state.volDownActionCont, (v) { state.volDownActionCont = v!; state.saveSettings(); })
                ]))
              ]),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)));
  }

  Widget _buildButtonConfigPage(String l1, PhysicalButtonAction v1, ValueChanged<PhysicalButtonAction?> c1, String l2, PhysicalButtonAction v2, ValueChanged<PhysicalButtonAction?> c2) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l1, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      DropdownButton<PhysicalButtonAction>(isExpanded: true, value: v1, dropdownColor: const Color(0xFF333333), underline: Container(height: 1, color: Colors.white10), items: _getActionItems(), onChanged: c1),
      const SizedBox(height: 20),
      Text(l2, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      DropdownButton<PhysicalButtonAction>(isExpanded: true, value: v2, dropdownColor: const Color(0xFF333333), underline: Container(height: 1, color: Colors.white10), items: _getActionItems(), onChanged: c2),
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
      return DropdownMenuItem(value: e, child: Text(text, style: const TextStyle(color: Colors.white)));
    }).toList();
  }
}