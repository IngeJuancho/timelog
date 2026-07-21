import 'dart:io';

void main() {
  // 1. Fix Colors.white in time_records_list.dart
  var trlPath = 'lib/widgets/stopwatch/time_records_list.dart';
  var trlFile = File(trlPath);
  if (trlFile.existsSync()) {
    var content = trlFile.readAsStringSync();
    content = content.replaceAll('Colors.white', 'Theme.of(context).textTheme.bodyMedium?.color');
    
    // Also inject L10n if needed, but let's do L10n across files manually or via script
    if (!content.contains("import '../../l10n.dart';")) {
      content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../l10n.dart';");
    }
    
    if (!content.contains("final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));")) {
      content = content.replaceFirst('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));');
    }
    
    // translations
    content = content.replaceAll("'ELEMENTO'", "L10n.tr(lang, 'element')");
    content = content.replaceAll("'TOTAL CICLO'", "L10n.tr(lang, 'total_cycle')");
    content = content.replaceAll("'Sin datos registrados'", "L10n.tr(lang, 'no_data')");
    
    // remove const before Text if L10n is used
    content = content.replaceAll("const Text(L10n", "Text(L10n");
    
    trlFile.writeAsStringSync(content);
  }

  // 2. Fix stopwatch_screen.dart
  var ssPath = 'lib/stopwatch_screen.dart';
  var ssFile = File(ssPath);
  if (ssFile.existsSync()) {
    var content = ssFile.readAsStringSync();
    
    // Fix Colors.white
    content = content.replaceAll('Colors.white', 'Theme.of(context).textTheme.bodyMedium?.color');
    
    if (!content.contains("import 'l10n.dart';")) {
      content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'l10n.dart';");
    }
    
    // Inject lang into _StopwatchScreenState build
    if (!content.contains("final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));")) {
      content = content.replaceFirst('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));');
    }
    
    // Replace hardcoded strings
    content = content.replaceAll("'TimeLog'", "L10n.tr(lang, 'app_title')");
    content = content.replaceAll("'Guardar Estudio'", "L10n.tr(lang, 'save')");
    content = content.replaceAll("'Historial'", "L10n.tr(lang, 'historial')");
    content = content.replaceAll("'Rutas Estándar'", "L10n.tr(lang, 'templates')");
    content = content.replaceAll("'Rutas Estndar'", "L10n.tr(lang, 'templates')");
    content = content.replaceAll("'Calculadora Muestra'", "'Calculadora Muestra'"); // maybe later
    content = content.replaceAll("'Configuración'", "L10n.tr(lang, 'settings')");
    content = content.replaceAll("'Configuracin'", "L10n.tr(lang, 'settings')");
    content = content.replaceAll("'Manejo de Datos'", "'Manejo de Datos'");
    content = content.replaceAll("'Importar archivo'", "L10n.tr(lang, 'load')");
    content = content.replaceAll("'Exportar a Excel'", "L10n.tr(lang, 'export')");
    content = content.replaceAll("'ESTADISTICAS'", "L10n.tr(lang, 'stats').toUpperCase()");
    content = content.replaceAll("'REGISTROS'", "L10n.tr(lang, 'time_list').toUpperCase()");
    
    // Remove const before Text with L10n
    content = content.replaceAll("const Text(L10n", "Text(L10n");
    
    ssFile.writeAsStringSync(content);
  }
}
