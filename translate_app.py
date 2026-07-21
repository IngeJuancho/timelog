import os
import re

def insert_lang_var(content):
    # For build method
    if "final lang = ref.watch(" not in content:
        content = re.sub(
            r'Widget build\(BuildContext context\) \{',
            r'Widget build(BuildContext context) {\n    final lang = ref.watch(timeLogProvider.select((s) => s.languageCode));',
            content
        )
    return content

def translate_file(path, replacements, imports="import 'l10n.dart';"):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # ensure import
    if imports not in content:
        content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{imports}")

    content = insert_lang_var(content)
    
    # In some methods outside build, we need lang. We can just use ref.read(timeLogProvider).languageCode directly!
    # Instead of injecting lang variables everywhere, let's just replace strings with L10n.tr(ref.read(timeLogProvider).languageCode, 'key')
    # Or for simplicity, in ConsumerState we can always do ref.watch(...) in build, and ref.read(...) in callbacks.
    # To be extremely safe, we will replace the target strings with a generic call.
    # Wait, in build() we can use lang. In callbacks like _promptSaveStudy, lang is not defined unless we define it.
    
    # Actually, it's much safer to replace strings with L10n.tr(ref.read(timeLogProvider).languageCode, 'key') if we are inside a State,
    # BUT ef.read inside uild is bad practice. We should use lang if inside build, or ef.watch / ef.read accordingly.
    # Let's just define String get lang => ref.watch(timeLogProvider.select((s) => s.languageCode)); as a getter in the State class!
    # BUT wait, ef.watch in a getter is dangerous because it must be called in uild.
    
    pass

# I will use multi_replace_file_content for specific files because it is safer than regex.
