import os
import io

path = 'lib/stopwatch_screen.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'l10n.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'l10n.dart';")

# Add lang to build
if "final lang = ref.watch(timeLogProvider" not in content:
    content = content.replace(
        'Widget build(BuildContext context) {',
        'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));'
    )

def rep(old, new_key, use_read=False):
    global content
    getter = "ref.read(timeLogProvider).languageCode" if use_read else "lang"
    rep_str = "L10n.tr(" + getter + ", '" + new_key + "')"
    
    # We replace both const Text and Text, and handle quotes safely
    content = content.replace("const Text('" + old + "'", "Text(" + rep_str)
    content = content.replace("Text('" + old + "'", "Text(" + rep_str)
    content = content.replace('const Text("' + old + '"', 'Text(' + rep_str)
    content = content.replace('Text("' + old + '"', 'Text(' + rep_str)

rep("TimeLog", "app_title", False)
rep(u"Configuraci\u00f3n", "settings", False)
rep(u"Configuración", "settings", False)
rep("Historial", "historial", False)
rep(u"Rutas Est\u00e1ndar", "templates", False)
rep(u"Rutas Estándar", "templates", False)
rep("Importar archivo", "load", False)
rep("Exportar a Excel", "export", False)
rep("Guardar Estudio", "save", False)
rep("Manejo de Datos", "Manejo de Datos", False) # ignore for now

rep("No hay tiempos tomados para guardar.", "no_data", True)
rep("Guardar Estudio Nuevo", "new_study", True)
rep("Nombre del estudio", "study_name", True)
rep("CANCELAR", "cancel", True)
rep("GUARDAR", "save", True)

content = content.replace("'ESTADISTICAS'", "L10n.tr(lang, 'stats').toUpperCase()")
content = content.replace("'ESTADÍSTICAS'", "L10n.tr(lang, 'stats').toUpperCase()")
content = content.replace(u"'ESTAD\u00cdSTICAS'", "L10n.tr(lang, 'stats').toUpperCase()")
content = content.replace("'REGISTROS'", "L10n.tr(lang, 'time_list').toUpperCase()")

# Colors.white replacement where needed
content = content.replace("Colors.white", "Theme.of(context).textTheme.bodyMedium?.color")
content = content.replace("color: Theme.of(context).textTheme.bodyMedium?.color70", "color: Theme.of(context).textTheme.bodyMedium?.color")
content = content.replace("color: Theme.of(context).textTheme.bodyMedium?.color54", "color: Theme.of(context).textTheme.bodyMedium?.color")

content = content.replace("const Text(L10n", "Text(L10n")

with io.open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Fix time_records_list.dart
path2 = 'lib/widgets/stopwatch/time_records_list.dart'
with io.open(path2, 'r', encoding='utf-8') as f:
    content2 = f.read()

if "import '../../l10n.dart';" not in content2:
    content2 = content2.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../l10n.dart';")

if "final lang = ref.watch(timeLogProvider" not in content2:
    content2 = content2.replace(
        'Widget build(BuildContext context) {',
        'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));'
    )

content2 = content2.replace("'ELEMENTO'", "L10n.tr(lang, 'element')")
content2 = content2.replace("'TOTAL CICLO'", "L10n.tr(lang, 'total_cycle')")
content2 = content2.replace("Colors.white", "Theme.of(context).textTheme.bodyMedium?.color")

with io.open(path2, 'w', encoding='utf-8') as f:
    f.write(content2)
