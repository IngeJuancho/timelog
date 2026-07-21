import 'dart:io';

void main() {
  final files = [
    'lib/stopwatch_screen.dart',
    'lib/widgets/stopwatch/time_records_list.dart',
    'lib/widgets/stopwatch/statistics_panel.dart',
    'lib/widgets/stopwatch/control_buttons.dart',
    'lib/widgets/stopwatch/timer_display.dart',
  ];

  for (var path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Fix colors
    content = content.replaceAll('const Color(0xFF252525)', 'Theme.of(context).cardColor');
    content = content.replaceAll('Color(0xFF252525)', 'Theme.of(context).cardColor');
    content = content.replaceAll('const Color(0xFF1E1E1E)', 'Theme.of(context).colorScheme.surface');
    content = content.replaceAll('Color(0xFF1E1E1E)', 'Theme.of(context).colorScheme.surface');
    content = content.replaceAll('const Color(0xFF2A2A2A)', 'Theme.of(context).dividerColor');
    
    // Text colors that break light mode
    content = content.replaceAll('color: Colors.white,', '');
    content = content.replaceAll('color: Colors.white', '');
    content = content.replaceAll('color: Colors.white70', 'color: Theme.of(context).textTheme.bodySmall?.color');
    content = content.replaceAll('color: Colors.white54', 'color: Theme.of(context).textTheme.bodySmall?.color');
    content = content.replaceAll('color: Colors.white38', 'color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.38)');
    
    // Fix const issues caused by non-const Theme.of
    content = content.replaceAll('const TextStyle(color: Theme.of(context)', 'TextStyle(color: Theme.of(context)');
    content = content.replaceAll('const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent), SizedBox(width: 10), Text(''Datos no exportados'', style: TextStyle(fontSize: 18))])', 'Row(children: const [Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent), SizedBox(width: 10), Text(''Datos no exportados'', style: TextStyle(fontSize: 18))])');
    
    // Since we removed color: Colors.white, some const TextStyles might just be empty, e.g. const TextStyle(). Let's remove them or leave them
    
    file.writeAsStringSync(content);
  }
}
