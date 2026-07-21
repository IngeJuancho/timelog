import io
import re

with io.open('lib/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add isAmoled
if "final isAmoled =" not in content:
    content = content.replace(
        "final vDownCont = ref.watch(timeLogProvider.select((s) => s.volDownActionCont));",
        "final vDownCont = ref.watch(timeLogProvider.select((s) => s.volDownActionCont));\n    final isAmoled = ref.watch(timeLogProvider.select((s) => s.isAmoledMode));"
    )

# Add Theme toggle
if "Modo Claro" not in content and "Tema" not in content:
    theme_ui = """
          _buildSectionHeader("Personalización", Theme.of(context).colorScheme.primary),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            title: const Text('Modo Oscuro AMOLED', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Optimizado para pantallas OLED.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 12)),
            value: isAmoled,
            onChanged: (v) {
              controller.updateSetting(isAmoledMode: v);
            }
          ),
          const SizedBox(height: 20),
"""
    content = content.replace('          _buildSectionHeader("Visualización"),', theme_ui + '          _buildSectionHeader("Visualización", Theme.of(context).colorScheme.primary),')

# Replace buildSectionHeader calls
content = content.replace('_buildSectionHeader("Visualización")', '') # handled above
content = content.replace('_buildSectionHeader("Feedback")', '_buildSectionHeader("Feedback", Theme.of(context).colorScheme.primary)')
content = content.replace('_buildSectionHeader("Hardware")', '_buildSectionHeader("Hardware", Theme.of(context).colorScheme.primary)')

# Fix _buildSectionHeader signature
content = content.replace('Widget _buildSectionHeader(String title) {', 'Widget _buildSectionHeader(String title, Color color) {')
content = content.replace('style: const TextStyle(color: Colors.teal', 'style: TextStyle(color: color')

# Colors.white / fixed colors replacements
content = re.sub(r"color: Colors\.white(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color\1", content)
content = re.sub(r"color: Colors\.white70(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)\1", content)
content = re.sub(r"color: Colors\.white54(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54)\1", content)
content = re.sub(r"color: Colors\.white38(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.38)\1", content)
content = re.sub(r"color: Colors\.white60(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.60)\1", content)
content = re.sub(r"color: Colors\.white12(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.12)\1", content)
content = re.sub(r"color: Colors\.white30(\)|\s|,|})", r"color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.30)\1", content)

content = content.replace('activeTrackColor: Colors.tealAccent', 'activeTrackColor: Theme.of(context).colorScheme.primary')
content = content.replace('indicatorColor: Colors.tealAccent', 'indicatorColor: Theme.of(context).colorScheme.primary')
content = content.replace('labelColor: Colors.tealAccent', 'labelColor: Theme.of(context).colorScheme.primary')

content = content.replace('dropdownColor: const Color(0xFF2C2C2C),', '')
content = content.replace('dropdownColor: const Color(0xFF333333),', '')
content = content.replace('decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),', 'decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),')
content = content.replace('underline: Container(height: 1, color: Colors.white10)', 'underline: Container(height: 1, color: Theme.of(context).dividerColor)')

content = re.sub(r"const (TextStyle\([^)]*Theme\.of)", r"\1", content)
content = re.sub(r"const (Text\([^)]*Theme\.of)", r"\1", content)

with io.open('lib/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
