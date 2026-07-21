import io
import re

def process_file(path, translations, has_build_lang=False):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    if "import 'l10n.dart';" not in content and "import '../../l10n.dart';" not in content:
        if 'time_records_list' in path:
            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../l10n.dart';")
        else:
            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'l10n.dart';")

    if has_build_lang and "final lang =" not in content:
        content = re.sub(
            r'Widget build\(BuildContext context\) \{',
            r'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));',
            content
        )

    for (old, new_key, use_read) in translations:
        getter = "ref.read(timeLogProvider).languageCode" if use_read else "lang"
        # Be careful not to replace parts of words
        rep = f"L10n.tr({getter}, '{new_key}')"
        content = content.replace(f"const Text('{old}'", f"Text({rep}")
        content = content.replace(f"Text('{old}'", f"Text({rep}")

    # Uppercase ones manually
    content = content.replace("'ESTAD\u00cdSTICAS'", "L10n.tr(lang, 'stats').toUpperCase()")
    content = content.replace("'REGISTROS'", "L10n.tr(lang, 'time_list').toUpperCase()")
    content = content.replace("const Text(L10n", "Text(L10n")

    # Colors.white logic
    content = re.sub(r"color: Colors\.white(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color\1", content)
    content = re.sub(r"color: Colors\.white70(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)\1", content)
    content = re.sub(r"color: Colors\.white54(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54)\1", content)
    content = re.sub(r"color: Colors\.white38(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.38)\1", content)
    content = re.sub(r"color: Colors\.white60(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.60)\1", content)
    content = re.sub(r"color: Colors\.white12(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.12)\1", content)
    content = re.sub(r"color: Colors\.white30(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.30)\1", content)

    # Clean const Text -> Text if it has Theme.of
    content = re.sub(r"const (TextStyle\([^)]*Theme\.of)", r"\1", content)
    content = re.sub(r"const (Text\([^)]*Theme\.of)", r"\1", content)
    # Generic const Text cleanup
    content = re.sub(r"const (Text\([^)]*ref\.read)", r"\1", content)

    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(content)

stopwatch_trans = [
    ("TimeLog", "app_title", False),
    (u"Configuraci\u00f3n", "settings", False),
    ("Historial", "historial", False),
    (u"Rutas Est\u00e1ndar", "templates", False),
    ("Importar archivo", "load", False),
    ("Exportar a Excel", "export", False),
    ("Guardar Estudio", "save", False),
    ("No hay tiempos tomados para guardar.", "no_data", True),
    ("Guardar Estudio Nuevo", "new_study", True),
    ("Nombre del estudio", "study_name", True),
    ("CANCELAR", "cancel", True),
    ("GUARDAR", "save", True),
    ("NUEVO", "new_study", True)
]

trl_trans = [
    ("ELEMENTO", "element", False),
    ("TOTAL CICLO", "total_cycle", False)
]

process_file('lib/stopwatch_screen.dart', stopwatch_trans, True)
process_file('lib/widgets/stopwatch/time_records_list.dart', trl_trans, True)

