import 'dart:io';

void main() {
  var path = 'lib/stopwatch_screen.dart';
  var file = File(path);
  var content = file.readAsStringSync();
  
  if (!content.contains("import 'l10n.dart';")) {
    content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'l10n.dart';");
  }
  
  // Inject lang into build
  if (!content.contains("final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));")) {
    content = content.replaceFirst('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));');
  }

  // Define a tiny helper method string replace
  String repStr(String old, String key, bool isDialog) {
    String getter = isDialog ? "ref.read(timeLogProvider).languageCode" : "lang";
    String replacement = "L10n.tr($getter, '$key')";
    content = content.replaceAll("const Text('$old'", "Text($replacement");
    content = content.replaceAll("Text('$old'", "Text($replacement");
    return content;
  }

  repStr("TimeLog", "app_title", false);
  repStr("Configuración", "settings", false);
  repStr("Historial", "historial", false);
  repStr("Rutas Estándar", "templates", false);
  repStr("Importar archivo", "load", false);
  repStr("Exportar a Excel", "export", false);
  repStr("Guardar Estudio", "save", false);

  // Dialogs
  repStr("No hay tiempos tomados para guardar.", "no_data", true);
  repStr("Guardar Estudio Nuevo", "new_study", true);
  repStr("Nombre del estudio", "study_name", true);
  repStr("CANCELAR", "cancel", true);
  repStr("GUARDAR", "save", true);
  
  // Uppercase ones
  content = content.replaceAll("'ESTADÍSTICAS'", "L10n.tr(lang, 'stats').toUpperCase()");
  content = content.replaceAll("'REGISTROS'", "L10n.tr(lang, 'time_list').toUpperCase()");
  
  content = content.replaceAll("const Text(L10n", "Text(L10n");

  // Colors.white replacement
  content = content.replaceAll("Colors.white", "Theme.of(context).textTheme.bodyMedium?.color");
  content = content.replaceAll("Theme.of(context).textTheme.bodyMedium?.color70", "Theme.of(context).textTheme.bodyMedium?.color");
  content = content.replaceAll("Theme.of(context).textTheme.bodyMedium?.color54", "Theme.of(context).textTheme.bodyMedium?.color");

  file.writeAsStringSync(content);


  var path2 = 'lib/widgets/stopwatch/time_records_list.dart';
  var file2 = File(path2);
  var content2 = file2.readAsStringSync();

  if (!content2.contains("import '../../l10n.dart';")) {
    content2 = content2.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../l10n.dart';");
  }

  if (!content2.contains("final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));")) {
    content2 = content2.replaceFirst('Widget build(BuildContext context) {', 'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));');
  }

  content2 = content2.replaceAll("'ELEMENTO'", "L10n.tr(lang, 'element')");
  content2 = content2.replaceAll("'TOTAL CICLO'", "L10n.tr(lang, 'total_cycle')");
  content2 = content2.replaceAll("Colors.white", "Theme.of(context).textTheme.bodyMedium?.color");
  content2 = content2.replaceAll("Theme.of(context).textTheme.bodyMedium?.color54", "Theme.of(context).textTheme.bodyMedium?.color");
  content2 = content2.replaceAll("Theme.of(context).textTheme.bodyMedium?.color60", "Theme.of(context).textTheme.bodyMedium?.color");
  content2 = content2.replaceAll("Theme.of(context).textTheme.bodyMedium?.color38", "Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.38)");

  content2 = content2.replaceAll("const Text(L10n", "Text(L10n");

  file2.writeAsStringSync(content2);
}
