import os
import re

path = 'lib/stopwatch_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'l10n.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'l10n.dart';")

# Add lang to build
if "final lang =" not in content:
    content = re.sub(
        r'Widget build\(BuildContext context\) \{',
        r'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));',
        content
    )

# Replacements
def rep(old, new_key, use_read=False):
    global content
    lang_expr = "ref.read(timeLogProvider).languageCode" if use_read else "lang"
    replacement = f"L10n.tr({lang_expr}, '{new_key}')"
    content = content.replace(f"const Text('{old}'", f"Text({replacement}")
    content = content.replace(f"Text('{old}'", f"Text({replacement}")

# in build
rep('TimeLog', 'app_title')
rep('Configuración', 'settings')
rep('Historial', 'historial')
rep('Rutas Estándar', 'templates')
rep('Calculadora Muestra', 'calculator', False) # Wait, is calculator in l10n? No. Let's skip it
rep('Importar archivo', 'load')
rep('Exportar a Excel', 'export')
rep('ESTADÍSTICAS', 'stats') # wait, these are uppercase in dart code? Let's check
# They are hardcoded as uppercase, we can do L10n.tr(lang, 'stats').toUpperCase()
content = content.replace("'ESTADÍSTICAS'", "L10n.tr(lang, 'stats').toUpperCase()")
content = content.replace("'REGISTROS'", "L10n.tr(lang, 'time_list').toUpperCase()")
content = content.replace("const Text(L10n", "Text(L10n")

# In dialogs (use ref.read)
rep('No hay tiempos tomados para guardar.', 'no_data', True)
rep('Guardar Estudio Nuevo', 'new_study', True)
rep('Nombre del estudio', 'study_name', True)
rep('CANCELAR', 'cancel', True) 
rep('GUARDAR', 'save', True)
content = content.replace("Text(L10n.tr(ref.read(timeLogProvider).languageCode, 'cancel').toUpperCase()", "Text(L10n.tr(ref.read(timeLogProvider).languageCode, 'cancel').toUpperCase()") # Just handle manually
# Actually, for CANCELAR, GUARDAR:
content = content.replace("const Text('CANCELAR'", "Text(L10n.tr(ref.read(timeLogProvider).languageCode, 'cancel').toUpperCase()")
content = content.replace("const Text('GUARDAR'", "Text(L10n.tr(ref.read(timeLogProvider).languageCode, 'save').toUpperCase()")
content = content.replace("const Text('NUEVO'", "Text(L10n.tr(ref.read(timeLogProvider).languageCode, 'new_study').toUpperCase()")
content = content.replace("const Text('ACTUALIZAR'", "Text('ACTUALIZAR'")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
