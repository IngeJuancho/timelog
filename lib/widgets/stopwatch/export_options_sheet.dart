import 'package:flutter/material.dart';
import '../../theme.dart';

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ExportOptionsSheet(
        onImportPressed: onImportPressed,
        onExportPressed: onExportPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final emerald = AppTheme.getTealAccent(context);

    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF0F1116),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: isLight ? 0.8 : 0.4),
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de arrastre
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.swap_vert_circle_outlined, color: emerald, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Gestión de Datos & Archivos',
                    style: TextStyle(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildOptionCard(
                context: context,
                icon: Icons.file_download_outlined,
                iconColor: emerald,
                title: 'Importar Estudio Excel',
                subtitle: 'Cargar y continuar un estudio previo desde un archivo .xlsx.',
                onTap: () {
                  Navigator.pop(context);
                  onImportPressed();
                },
              ),

              const SizedBox(height: 10),

              _buildOptionCard(
                context: context,
                icon: Icons.file_upload_outlined,
                iconColor: isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision,
                title: 'Exportar a Excel (.xlsx)',
                subtitle: 'Generar reporte completo con fórmulas, PF&D y resumen de proceso.',
                onTap: () {
                  Navigator.pop(context);
                  onExportPressed();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF14171E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isLight ? 0.8 : 0.35),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isLight ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textTheme.titleMedium?.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
