import os
import re

files_to_fix = [
    'lib/stopwatch_screen.dart',
    'lib/widgets/stopwatch/time_records_list.dart',
    'lib/widgets/stopwatch/statistics_panel.dart',
    'lib/widgets/stopwatch/control_buttons.dart',
    'lib/widgets/stopwatch/timer_display.dart',
]

def process_file(path):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Colors -> Theme colors
    content = content.replace('const Color(0xFF252525)', 'Theme.of(context).cardColor')
    content = content.replace('Color(0xFF252525)', 'Theme.of(context).cardColor')
    content = content.replace('const Color(0xFF1E1E1E)', 'Theme.of(context).colorScheme.surface')
    content = content.replace('Color(0xFF1E1E1E)', 'Theme.of(context).colorScheme.surface')
    content = content.replace('const Color(0xFF2A2A2A)', 'Theme.of(context).dividerColor')
    content = content.replace('Color(0xFF2A2A2A)', 'Theme.of(context).dividerColor')
    
    # 2. Text styles
    # We want to change const TextStyle(color: Colors.white...) to TextStyle(...)
    # and remove the color so it inherits from Theme.
    
    # Remove 'color: Colors.white,' and 'color: Colors.white'
    # But wait, if we remove it from const TextStyle(color: Colors.white), we need to make sure we don't break constness if we use Theme.
    # Actually, removing color: Colors.white from const TextStyle(...) is perfectly fine, it just becomes const TextStyle(...) which is valid!
    content = re.sub(r'color:\s*Colors\.white,\s*', '', content)
    content = re.sub(r'color:\s*Colors\.white\b', '', content)
    
    # Colors.white70 -> color: Theme.of(context).textTheme.bodySmall?.color
    # This WILL break const if it's const TextStyle(color: Colors.white70).
    # Let's remove const  before TextStyle if we are injecting Theme.of(context).
    # Regex to find const TextStyle(..., color: Colors.white70, ...)
    
    # Let's just remove const from ALL TextStyles to be safe, then let dart fix handle it!
    content = re.sub(r'const\s+TextStyle\(', 'TextStyle(', content)
    
    # Now replace the specific colors
    content = content.replace('Colors.white70', 'Theme.of(context).textTheme.bodySmall?.color')
    content = content.replace('Colors.white60', 'Theme.of(context).textTheme.bodySmall?.color')
    content = content.replace('Colors.white54', 'Theme.of(context).textTheme.bodySmall?.color')
    content = content.replace('Colors.white38', 'Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.38)')
    content = content.replace('Colors.white24', 'Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.24)')
    content = content.replace('Colors.white10', 'Theme.of(context).dividerColor')
    
    # Remove any stray empty color parameters that might have been left if we used regex badly
    content = re.sub(r',\s*\)', ')', content)
    
    # 3. Fix other const issues caused by Theme.of(context)
    # e.g., const Icon(..., color: Theme.of(context)...)
    content = re.sub(r'const\s+Icon\(', 'Icon(', content)
    content = re.sub(r'const\s+Text\(', 'Text(', content)
    content = re.sub(r'const\s+Row\(', 'Row(', content)
    content = re.sub(r'const\s+Column\(', 'Column(', content)
    content = re.sub(r'const\s+Padding\(', 'Padding(', content)
    content = re.sub(r'const\s+Center\(', 'Center(', content)
    content = re.sub(r'const\s+Divider\(', 'Divider(', content)
    content = re.sub(r'const\s+SizedBox\(', 'SizedBox(', content)
    content = re.sub(r'const\s+CircleAvatar\(', 'CircleAvatar(', content)
    content = re.sub(r'const\s+AlertDialog\(', 'AlertDialog(', content)
    
    # Save back
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

for p in files_to_fix:
    process_file(p)
