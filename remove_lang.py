import io
import re

# time_log_state.dart
with io.open('lib/time_log_state.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = re.sub(r"^\s*final String languageCode;\n", "", content, flags=re.MULTILINE)
content = re.sub(r"^\s*this\.languageCode = 'es',\n", "", content, flags=re.MULTILINE)
content = re.sub(r"^\s*String\? languageCode,\n", "", content, flags=re.MULTILINE)
content = re.sub(r"^\s*languageCode: languageCode \?\? this\.languageCode,\n", "", content, flags=re.MULTILINE)
with io.open('lib/time_log_state.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# time_log_controller.dart
with io.open('lib/time_log_controller.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = re.sub(r"^\s*String languageCode = prefs\.getString\('languageCode'\) \?\? 'es';\n", "", content, flags=re.MULTILINE)
content = re.sub(r"^\s*await prefs\.setString\('languageCode', newState\.languageCode\);\n", "", content, flags=re.MULTILINE)
content = re.sub(r"^\s*languageCode: languageCode,\n", "", content, flags=re.MULTILINE)
content = re.sub(r"^\s*String\? languageCode,\n", "", content, flags=re.MULTILINE)
with io.open('lib/time_log_controller.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# settings_screen.dart
with io.open('lib/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We need to remove the whole language toggle block.
# Look for ListTile for 'Idioma' and delete it safely.
# It's better to just search for the specific lines in settings_screen.dart. Let's see what it looks like.
