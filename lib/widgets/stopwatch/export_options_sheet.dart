import 'package:flutter/material.dart';

class ExportOptionsSheet extends StatelessWidget {
  final VoidCallback onImportPressed;
  final VoidCallback onExportPressed;

  const ExportOptionsSheet({
    super.key,
    required this.onImportPressed,
    required this.onExportPressed,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onImportPressed,
    required VoidCallback onExportPressed,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExportOptionsSheet(
        onImportPressed: onImportPressed,
        onExportPressed: onExportPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Manejo de Datos',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.download, color: Colors.white),
            ),
            title: Text(
              'Importar archivo',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Cargar un estudio previo desde tus archivos Excel.',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onImportPressed();
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.upload, color: Colors.white),
            ),
            title: Text(
              'Exportar a Excel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Guardar el estudio en formato Excel (.xlsx).',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onExportPressed();
            },
          ),
        ],
      ),
    );
  }
}
