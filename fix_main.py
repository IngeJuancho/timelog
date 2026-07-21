import io
import re
with io.open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r"locale: Locale\(state\.languageCode\),\n\s*", "", content)
content = re.sub(r"import 'l10n\.dart';\n\s*", "", content)

with io.open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
