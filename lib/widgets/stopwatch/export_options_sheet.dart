import 'package:flutter/material.dart';
import '../../models/pfd_category.dart';

class ExportOptionsSheet extends StatelessWidget {
  final VoidCallback onImportPressed;
  final VoidCallback onExportPressed;
  final PfdCategory? currentPfd;
  final VoidCallback? onPfdChangePressed;

  const ExportOptionsSheet({
    super.key,
    required this.onImportPressed,
    required this.onExportPressed,
    this.currentPfd,
    this.onPfdChangePressed,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onImportPressed,
    required VoidCallback onExportPressed,
    PfdCategory? currentPfd,
    VoidCallback? onPfdChangePressed,
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
        currentPfd: currentPfd,
        onPfdChangePressed: onPfdChangePressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

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
          const SizedBox(height: 16),
          if (currentPfd != null) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPfdChangePressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 18, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PF&D: ${currentPfd!.name} (${currentPfd!.percentageText})',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Se aplicará a la columna de suplementos en Excel.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onPfdChangePressed != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Cambiar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
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
