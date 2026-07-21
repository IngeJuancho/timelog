import 'dart:io';

void main() {
  final path = 'lib/stopwatch_screen.dart';
  final file = File(path);
  var content = file.readAsStringSync();
  
  if (!content.contains("import 'l10n.dart';")) {
    content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'l10n.dart';");
  }
  
  // Create a helper method in _StopwatchScreenState to get translated string safely anywhere in the State class
  if (!content.contains("String _tr(String key)")) {
    content = content.replaceFirst(
      'class _StopwatchScreenState extends ConsumerState<StopwatchScreen> with SingleTickerProviderStateMixin {',
      'class _StopwatchScreenState extends ConsumerState<StopwatchScreen> with SingleTickerProviderStateMixin {\n  String _tr(String key) => L10n.tr(ref.watch(timeLogProvider.select((s) => s.languageCode)), key);'
    );
  }
  
  // Replace the texts using the helper _tr
  content = content.replaceAll("const Text('TimeLog'", "Text(_tr('app_title')");
  content = content.replaceAll("Text('TimeLog'", "Text(_tr('app_title')");
  
  content = content.replaceAll("const Text('No hay tiempos tomados para guardar.'", "Text(_tr('no_data')");
  content = content.replaceAll("Text('No hay tiempos tomados para guardar.'", "Text(_tr('no_data')");
  
  content = content.replaceAll("const Text('Guardar Estudio'", "Text(_tr('save')");
  content = content.replaceAll("Text('Guardar Estudio'", "Text(_tr('save')");
  
  content = content.replaceAll("const Text('Historial'", "Text(_tr('historial')");
  content = content.replaceAll("Text('Historial'", "Text(_tr('historial')");
  
  content = content.replaceAll("const Text('Rutas Estándar'", "Text(_tr('templates')");
  content = content.replaceAll("Text('Rutas Estándar'", "Text(_tr('templates')");
  
  content = content.replaceAll("const Text('Configuración'", "Text(_tr('settings')");
  content = content.replaceAll("Text('Configuración'", "Text(_tr('settings')");
  
  content = content.replaceAll("const Text('Importar archivo'", "Text(_tr('load')");
  content = content.replaceAll("Text('Importar archivo'", "Text(_tr('load')");
  
  content = content.replaceAll("const Text('Exportar a Excel'", "Text(_tr('export')");
  content = content.replaceAll("Text('Exportar a Excel'", "Text(_tr('export')");
  
  content = content.replaceAll("'ESTADÍSTICAS'", "_tr('stats').toUpperCase()");
  content = content.replaceAll("'REGISTROS'", "_tr('time_list').toUpperCase()");
  
  file.writeAsStringSync(content);
}
